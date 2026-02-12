//
//  MarkdownLatex+WithoutAnimation.swift
//  MDLatex
//
//  Created by Kumar shubham on 23/12/24.
//

import SwiftUI
import Down

// MARK: - One-Go Rendering
extension MarkdownLatexView {
    /// Loads the KaTeX skeleton from bundle if not already loaded,
    /// injecting the custom font & style.
    func loadKatexTemplateIfNeeded() {
        guard katexTemplate.isEmpty else { return }
        
        guard let templatePath = Bundle.module.url(forResource: "katex_template", withExtension: "html"),
              let htmlTemplate = try? String(contentsOf: templatePath) else {
            fatalError("Unable to load KaTeX template.")
        }
        
        // Insert custom font & style
        let fontFace = loadCustomFont()
        let styles = generateStyles(fontFace: fontFace)
        
        // Replace </head> with <style>...</style></head>
        let finalTemplate = htmlTemplate.replacingOccurrences(
            of: "</head>",
            with: "<style>\(styles)</style></head>"
        )
        self.katexTemplate = finalTemplate
    }
    
    /// One-go rendering with caching
    func renderAllContentAtOnceCached() {
        if let cachedHTML = viewModel.renderedHTMLCache[markdownContent] {
            // If we already generated final HTML for this Markdown, reuse it
            debugPrint("Using cached HTML for non-animated flow")
            injectAllContentIntoWebView(cachedHTML)
        } else {
            // Convert from Markdown -> final HTML, store in cache, then inject
            let finalHTML = convertMarkdownToHTML(markdownContent)
            viewModel.renderedHTMLCache[markdownContent] = finalHTML
            injectAllContentIntoWebView(finalHTML)
        }
    }
    
    /// Convert from Markdown & LaTeX -> final HTML
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        // 1) Extract LaTeX
        let (strippedMarkdown, latexSegments) = MarkdownLatexParser.extractLatexSegments(from: markdown)
        // 2) Pre-process tables (convert markdown tables to HTML since basic cmark doesn't support them)
        let processedMarkdown = preprocessTablesInMarkdown(strippedMarkdown)
        // 3) Convert processed Markdown -> HTML
        let down = Down(markdownString: processedMarkdown)
        let markdownHTML: String
        do {
            // Enable available Down options (basic cmark, no GFM tables yet)
            markdownHTML = try down.toHTML([
                .validateUTF8,
                .smart,
                .unsafe  // Allow raw HTML for custom table handling
            ])
        } catch {
            debugPrint("Failed to render Markdown:", error)
            return ""
        }
        // 4) Re-inject LaTeX into the HTML
        let final = MarkdownLatexParser.restoreLatexSegments(into: markdownHTML, latexSegments: latexSegments)
        return final
    }
    
    /// Pre-process markdown tables and convert them to HTML since basic cmark doesn't support GFM tables
    private func preprocessTablesInMarkdown(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            
            // Check if this line looks like a table header (contains |)
            if line.contains("|") && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                // Look ahead to see if next line is a separator (contains | and -)
                if i + 1 < lines.count {
                    let nextLine = lines[i + 1]
                    if nextLine.contains("|") && nextLine.contains("-") {
                        // This looks like a markdown table, process it
                        let (tableHTML, consumedLines) = convertMarkdownTableToHTML(startingAt: i, in: lines)
                        processedLines.append(tableHTML)
                        i += consumedLines
                        continue
                    }
                }
            }
            
            // Regular line, just add it
            processedLines.append(line)
            i += 1
        }
        
        return processedLines.joined(separator: "\n")
    }
    
    /// Process markdown content in a table cell
    private func processTableCellMarkdown(_ cellContent: String) -> String {
        // Skip processing if cell is empty or only contains whitespace
        let trimmedContent = cellContent.trimmingCharacters(in: .whitespaces)
        guard !trimmedContent.isEmpty else { return cellContent }
        
        // Use Down to process markdown in the cell content
        let down = Down(markdownString: trimmedContent)
        do {
            let cellHTML = try down.toHTML([
                .validateUTF8,
                .smart,
                .unsafe
            ])
            // Remove the wrapping <p> tags that Down adds for inline content
            let cleanHTML = cellHTML
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "^<p>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "</p>$", with: "", options: .regularExpression)
            return cleanHTML
        } catch {
            // If markdown processing fails, return original content
            return cellContent
        }
    }
    
    /// Convert a markdown table to HTML table
    private func convertMarkdownTableToHTML(startingAt startIndex: Int, in lines: [String]) -> (html: String, consumedLines: Int) {
        var tableRows: [String] = []
        var i = startIndex
        
        // Process header
        if i < lines.count {
            let headerLine = lines[i]
            let headerCells = headerLine.components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            
            if !headerCells.isEmpty {
                let headerHTML = headerCells.map { "<th>\(processTableCellMarkdown($0))</th>" }.joined()
                tableRows.append("<tr>\(headerHTML)</tr>")
                i += 1
            }
        }
        
        // Skip separator line (if exists)
        if i < lines.count && lines[i].contains("-") && lines[i].contains("|") {
            i += 1
        }
        
        // Process data rows
        while i < lines.count {
            let line = lines[i]
            if line.contains("|") && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                let dataCells = line.components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                if !dataCells.isEmpty {
                    let dataHTML = dataCells.map { "<td>\(processTableCellMarkdown($0))</td>" }.joined()
                    tableRows.append("<tr>\(dataHTML)</tr>")
                    i += 1
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        let tableHTML = """
        <table>
        <thead>
        \(tableRows.first ?? "")
        </thead>
        <tbody>
        \(tableRows.dropFirst().joined(separator: "\n"))
        </tbody>
        </table>
        """
        
        return (tableHTML, i - startIndex)
    }
    
    /// Calls `renderAllContent(html)` in the KaTeX skeleton to replace <div id="content"> with final HTML
    private func injectAllContentIntoWebView(_ html: String) {
        guard !html.isEmpty else { return }
        let escapedHTML = escapeForJavaScript(html)
        let js = """
        (function() {
            renderAllContent(`\(escapedHTML)`, function() {
                // Additional safety check after KaTeX renders
                setTimeout(updateHeight, 100);
            });
        })();
        """
        viewModel.webViewRef.evaluateJavaScript(js) { _, error in
            if let error = error {
                debugPrint("Error injecting HTML:", error)
            } else {
                self.onLoadingComplete?(html)
            }
        }
    }
}

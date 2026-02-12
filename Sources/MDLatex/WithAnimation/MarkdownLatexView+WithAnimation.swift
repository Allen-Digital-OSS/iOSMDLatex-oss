//
//  MarkdownLatexView+WithAnimation.swift
//  MDLatex
//
//  Created by Kumar Shubham on 23/12/24.
//

import SwiftUI
import Down
import WebKit

// MARK: - Animated (Chunk) Rendering
extension MarkdownLatexView {
    /// Splits the Markdown on "\n\n" to produce chunk-based sections
    func splitMarkdownIntoChunks(_ markdown: String) -> [String] {
        markdown.components(separatedBy: "\n\n")
    }
    
    /// Initialize chunk-based flow
    func initializeForAnimation(
        chunkCompletion: @escaping (String, Int) -> Void,
        completion: @escaping () -> Void
    ) {
        startChunkRendering(
            chunkCompletion: chunkCompletion,
            completion: completion
        )
    }
    
    /// Start chunk-based rendering from the first chunk
    func startChunkRendering(
        chunkCompletion: @escaping (String, Int) -> Void,
        completion: @escaping () -> Void
    ) {
        guard !markdownChunks.isEmpty else {
            completion()
            return
        }
        currentChunkIndex = 0
        processChunk(
            at: currentChunkIndex,
            chunkCompletion: chunkCompletion,
            completion: completion
        )
    }
    
    /// Process a single chunk, inject it, then schedule the next
    private func processChunk(
        at index: Int,
        chunkCompletion: @escaping (String, Int) -> Void,
        completion: @escaping () -> Void
    ) {
        guard index < markdownChunks.count else {
            debugPrint("All chunks rendered.")
            completion()
            return
        }
        
        let chunk = markdownChunks[index]
        debugPrint("Rendering chunk \(index): \(chunk)")
        
        // Convert chunk to final HTML, then inject
        DispatchQueue.main.async {
            self.appendChunkToWebView(self.viewModel.webViewRef, chunk) { success in
                if success {
                    chunkCompletion(chunk, index)
                    self.scheduleNext(
                        index: index + 1,
                        chunkCompletion: chunkCompletion,
                        completion: completion
                    )
                } else {
                    debugPrint("Retrying chunk \(index)")
                    self.scheduleRetry(
                        index: index,
                        chunkCompletion: chunkCompletion,
                        completion: completion
                    )
                }
            }
        }
    }
    
    /// Wait chunkRenderingDuration, then process next chunk
    private func scheduleNext(
        index: Int,
        chunkCompletion: @escaping (String, Int) -> Void,
        completion: @escaping () -> Void
    ) {
        scheduleAfterDelay {
            self.processChunk(at: index, chunkCompletion: chunkCompletion, completion: completion)
        }
    }
    
    /// Retry the same chunk after delay
    private func scheduleRetry(
        index: Int,
        chunkCompletion: @escaping (String, Int) -> Void,
        completion: @escaping () -> Void
    ) {
        scheduleAfterDelay {
            self.processChunk(at: index, chunkCompletion: chunkCompletion, completion: completion)
        }
    }
    
    private func scheduleAfterDelay(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + viewModel.animationConfig.chunkRenderingDuration,
            execute: action
        )
    }
    
    /// Convert a chunk -> final HTML, then append it to #content in the skeleton
    func appendChunkToWebView(_ webView: WKWebView, _ chunk: String, completion: @escaping (Bool) -> Void) {
        // 1) Extract LaTeX from chunk
        let (strippedMarkdown, latexSegments) = MarkdownLatexParser.extractLatexSegments(from: chunk)
        // 2) Pre-process tables (convert markdown tables to HTML since basic cmark doesn't support them)
        let processedMarkdown = preprocessTablesInMarkdown(strippedMarkdown)
        // 3) Convert to HTML
        let down = Down(markdownString: processedMarkdown)
        let htmlChunk: String
        do {
            // Enable available Down options (basic cmark, no GFM tables yet)
            htmlChunk = try down.toHTML([
                .validateUTF8,
                .smart,
                .unsafe  // Allow raw HTML for custom table handling
            ])
        } catch {
            debugPrint("Failed to render Markdown chunk: \(error)")
            completion(false)
            return
        }
        // 4) Re-inject LaTeX
        let restoredHTML = MarkdownLatexParser.restoreLatexSegments(into: htmlChunk, latexSegments: latexSegments)
        // 4) Escape for JavaScript
        let escapedHTML = escapeForJavaScript(restoredHTML)
        
        // 5) Append chunk in #content and re-render
        let js = """
        (function() {
            try {
                const content = document.getElementById('content');
                if (!content) throw new Error('Content element not found');
                
                const div = document.createElement('div');
                div.innerHTML = `\(escapedHTML)`;
                content.appendChild(div);
                
                renderMathInElement(div, {
                    delimiters: [
                        { left: "\\\\(", right: "\\\\)", display: false },
                        { left: "\\\\[", right: "\\\\]", display: true }
                    ],
                    throwOnError: false
                });
                
                updateHeight();
                return true;
            } catch (error) {
                console.error("Error appending chunk:", error);
                return false;
            }
        })();
        """
        
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                debugPrint("JavaScript Execution Error: \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
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
}

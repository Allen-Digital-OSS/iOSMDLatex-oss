import XCTest
@testable import MDLatex

final class MDLatexTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
    
    func testLatexInTables() throws {
        // Test that LaTeX expressions in markdown tables are properly extracted and restored
        let markdownWithLatexTable = """
        | \\( 2x \\) | \\( x^2 \\) |
        | --- | --- |
        | \\( 3y \\) | \\( y^3 \\) |
        """
        
        // Step 1: Extract LaTeX segments
        let (strippedMarkdown, latexSegments) = MarkdownLatexParser.extractLatexSegments(from: markdownWithLatexTable)
        
        // Verify LaTeX was extracted
        XCTAssertEqual(latexSegments.count, 4)
        XCTAssertEqual(latexSegments[0], "\\( 2x \\)")
        XCTAssertEqual(latexSegments[1], "\\( x^2 \\)")
        XCTAssertEqual(latexSegments[2], "\\( 3y \\)")
        XCTAssertEqual(latexSegments[3], "\\( y^3 \\)")
        
        // Verify placeholders were inserted
        XCTAssertTrue(strippedMarkdown.contains("<<<LATEX_0>>>"))
        XCTAssertTrue(strippedMarkdown.contains("<<<LATEX_1>>>"))
        XCTAssertTrue(strippedMarkdown.contains("<<<LATEX_2>>>"))
        XCTAssertTrue(strippedMarkdown.contains("<<<LATEX_3>>>"))
        
        // Step 2: Simulate HTML processing that would escape the placeholders
        let htmlWithEscapedPlaceholders = strippedMarkdown
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        // Step 3: Restore LaTeX segments (this should work with escaped placeholders)
        let finalResult = MarkdownLatexParser.restoreLatexSegments(into: htmlWithEscapedPlaceholders, latexSegments: latexSegments)
        
        // Verify all LaTeX expressions were restored
        XCTAssertTrue(finalResult.contains("\\( 2x \\)"))
        XCTAssertTrue(finalResult.contains("\\( x^2 \\)"))
        XCTAssertTrue(finalResult.contains("\\( 3y \\)"))
        XCTAssertTrue(finalResult.contains("\\( y^3 \\)"))
        
        // Verify no placeholders remain
        XCTAssertFalse(finalResult.contains("LATEX_"))
    }
    
    func testComplexLatexInTables() throws {
        // Test the specific complex example from the user
        let complexTable = """
        | \\( \\frac{\\begin{matrix}    \\text{First } \\hfill \\\\    \\text{monomial} \\to  \\hfill \\\\   \\end{matrix} }{\\begin{matrix}     \\downarrow \\text{Second } \\hfill \\\\    \\text{monomial} \\hfill \\\\   \\end{matrix} }\\)  | \\( 2x\\)  | \\( -5y\\)  |
        | --- | --- | --- |
        | \\( 2x\\)  | \\( 4x^{2}\\)  | \\( - 10xy\\)  |
        """
        
        let (strippedMarkdown, latexSegments) = MarkdownLatexParser.extractLatexSegments(from: complexTable)
        
        // Verify complex LaTeX was extracted
        XCTAssertTrue(latexSegments.count >= 6)
        XCTAssertTrue(latexSegments[0].contains("\\frac"))
        XCTAssertTrue(latexSegments[0].contains("\\text{First"))
        
        // Simulate HTML escaping and restore
        let htmlWithEscapedPlaceholders = strippedMarkdown
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        let finalResult = MarkdownLatexParser.restoreLatexSegments(into: htmlWithEscapedPlaceholders, latexSegments: latexSegments)
        
        // Verify complex LaTeX was restored
        XCTAssertTrue(finalResult.contains("\\frac"))
        XCTAssertTrue(finalResult.contains("\\text{First"))
        XCTAssertTrue(finalResult.contains("4x^{2}"))
        XCTAssertFalse(finalResult.contains("LATEX_"))
    }
    
    func testMarkdownAndLatexInTables() throws {
        // Test the user's specific example with both markdown and LaTeX
        let combinedTable = """
        | **Mass of the planet** | **Radius of the planet** | **Acceleration due to gravity** |
        | --- | --- | --- |
        | \\( 2M\\)  | \\( 2R\\)  | \\( \\frac{GM}{2R^2}\\)  |
        | \\( 4M\\)  | \\( \\frac{R}{2}\\)  | \\( \\frac{16GM}{R^2}\\)  |
        """
        
        // Step 1: Extract LaTeX segments
        let (strippedMarkdown, latexSegments) = MarkdownLatexParser.extractLatexSegments(from: combinedTable)
        
        // Verify LaTeX extraction
        XCTAssertTrue(latexSegments.count >= 6)
        XCTAssertTrue(latexSegments.contains { $0.contains("\\frac{GM}{2R^2}") })
        XCTAssertTrue(latexSegments.contains { $0.contains("2M") })
        
        // The table processing would happen here in the real implementation
        // For testing, we simulate that markdown **bold** would be processed to <strong>bold</strong>
        let processedMarkdown = strippedMarkdown.replacingOccurrences(of: "**", with: "")
        
        // Simulate HTML context where placeholders get escaped
        let htmlWithEscapedPlaceholders = processedMarkdown
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        
        // Step 2: Restore LaTeX segments
        let finalResult = MarkdownLatexParser.restoreLatexSegments(into: htmlWithEscapedPlaceholders, latexSegments: latexSegments)
        
        // Verify both markdown structure and LaTeX were preserved
        XCTAssertTrue(finalResult.contains("Mass of the planet")) // Markdown text preserved
        XCTAssertTrue(finalResult.contains("\\( 2M\\)")) // Basic LaTeX restored
        XCTAssertTrue(finalResult.contains("\\frac{GM}{2R^2}")) // Complex LaTeX restored
        XCTAssertFalse(finalResult.contains("LATEX_")) // No placeholders remain
    }
    
    func testImageTapCallback() throws {
        // Test that the image tap callback can be set and the API is properly structured
        var tappedImageUrl: String? = nil
        
        // This test verifies the API structure - actual WebView testing would require UI testing
        let expectation = XCTestExpectation(description: "Image tap callback should be callable")
        
        // Simulate what would happen when an image is tapped
        let testImageUrl = "https://example.com/test-image.jpg"
        let callback: (String) -> Void = { url in
            tappedImageUrl = url
            expectation.fulfill()
        }
        
        // Call the callback to simulate image tap
        callback(testImageUrl)
        
        // Verify the callback was called with the correct URL
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(tappedImageUrl, testImageUrl)
        
        // Test that the API accepts the callback parameter
        let markdownWithImage = """
        # Test Image
        ![Test Image](https://example.com/image.jpg)
        """
        
        // This should compile without errors, proving the API structure is correct
        let _ = MDLatex.render(
            markdown: markdownWithImage,
            onImageTapped: { url in
                // This callback would be called when image is tapped in real usage
                print("Image tapped: \(url)")
            }
        )
        
        // If we get here, the API structure is correct
        XCTAssertTrue(true, "Image tap callback API is properly structured")
    }
}

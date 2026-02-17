# MDLatex

A powerful Swift package for seamlessly rendering Markdown with LaTeX support. Features include **GitHub Flavored Markdown support**, customizable themes, smooth animations, fluent API modifiers, designed for effortless integration into your apps.

---

## Features
- **Markdown and LaTeX Rendering:** Combines the power of Markdown and LaTeX to deliver beautifully rendered content.
- **GitHub Flavored Markdown Support:** Full support for tables, strikethrough text, task lists, code blocks, and all GFM features.
- **Enhanced Table Processing with LaTeX & Markdown:** Robust table parsing that handles LaTeX expressions and full Markdown formatting within table cells 
- **Advanced Table Support:** Works with complex malformed tables with images, multiline content, and various structures.
- **Generic Table Support:** Works with any table format or structure without hardcoded patterns or content-specific logic.
- **Customizable Themes:** Modify background color, font size, font family, and more to suit your app's design.
- **Chunk-based Animations:** Render content in chunks for a smooth and dynamic user experience with full table support.
- **Fluent Modifiers:** Easily configure the rendering behavior with a fluent API.
- **Caching for Optimized Performance:** Non-animated rendering supports caching for repeated content.
- **Production-Ready Performance:** Optimized code with clean architecture for high-performance rendering.
- **Cross-platform Support:** Compatible with iOS 14.0+.

---

## Installation

### Swift Package Manager
Add the following to your `Package.swift`:

```swift
.package(url: "https://github.com/Allen-Digital-OSS/iOSMDLatex-oss", from: "1.0.2")
```

Include `MDLatex` as a dependency for your target:

```swift
.target(name: "YourTarget", dependencies: ["MDLatex"]),
```

Or add it via Xcode:
1. Navigate to `File > Add Packages`.
2. Enter the repository URL: `https://github.com/Allen-Digital-OSS/iOSMDLatex-oss`.
3. Choose the latest version and integrate it into your project.

---

## What's New

🚀 **Enhanced Table Cell Processing & Image Interaction:**
- **✅ LaTeX in Table Cells**: LaTeX expressions now render perfectly within table cells
- **✅ Markdown in Table Cells**: Bold, italic, links, code, strikethrough formatting all work in table cells  
- **✅ Mixed Content Support**: Combine LaTeX math and Markdown formatting in the same table cell
- **✅ Image Tap Callbacks**: Tap any image to get its URL for full-screen viewers or other actions
- **✅ Visual Image Feedback**: Images show hover effects and pointer cursor to indicate interactivity
- **✅ Robust Processing**: Enhanced placeholder restoration handles HTML-escaped contexts
- **✅ Backward Compatible**: All existing functionality preserved

**Example of new capabilities:**
```swift
let advancedTable = """
| **Mass of the planet** | **Radius of the planet** | **Acceleration due to gravity** |
| --- | --- | --- |
| \\( 2M \\) | \\( 2R \\) | \\( \\frac{GM}{2R^2} \\) |
| \\( 4M \\) | \\( \\frac{R}{2} \\) | \\( \\frac{16GM}{R^2} \\) |
| **Bold text** | *Italic text* | `Code snippet` |
| [Link text](https://example.com) | ~~Strikethrough~~ | Normal text |
"""

MDLatex.render(markdown: advancedTable)
```

---

## Usage

### Basic Usage
Render Markdown with embedded LaTeX expressions and GitHub Flavored Markdown features:

```swift
import MDLatex

struct ContentView: View {
    @State private var renderingComplete = false
    var body: some View {
        VStack {
            if renderingComplete {
                Text("Rendering Complete!")
                    .font(.headline)
                    .padding()
            }

            MDLatex.render(
                markdown: """
                # Photosynthesis with GitHub Flavored Markdown

                Photosynthesis is the process by which green plants convert light energy into chemical energy.

                ## Key Points:
                - [x] **Definition**: Plants make their own food using sunlight, CO₂, and water
                - [x] **Equation**: \\[6CO_2 + 6H_2O + light \\ energy \\rightarrow C_6H_{12}O_6 + 6O_2\\]
                - [ ] ~~Old understanding~~ **New research**: Two main stages

                ### Comparison Table:
                | Component         | Role in Photosynthesis                          | Location |
                |--------------------|--------------------------------------------------|----------|
                | Sunlight          | Provides energy for light-dependent reactions   | Thylakoid |
                | Chlorophyll       | Absorbs light energy                            | Chloroplast |
                | Water (H₂O)       | Source of electrons, releases O₂                | Stroma |
                | Carbon Dioxide    | Used in Calvin cycle to produce glucose         | Stroma |

                ### Code Example:
                ```python
                def photosynthesis(sunlight, co2, water):
                    return glucose + oxygen
                ```

                > **Note**: This is a simplified representation of the complex biochemical process.

                **Math Formula**: The efficiency can be calculated as \\(E = \\frac{glucose}{energy_{input}} \\times 100\\%\\)
                """,
                theme: ThemeConfiguration(
                    backgroundColor: Color.clear,
                    fontColor: Color.black,
                    fontSize: 16,
                    fontFamily: "Arial",
                    userInteractionEnabled: true
                ),
                animation: AnimationConfiguration(isEnabled: true, chunkRenderingDuration: 0.4),
                width: UIScreen.main.bounds.width - 32,
                onComplete: { _ in
                    /// to do on complete rendering 
                },
                onChunkRendered: { _, _ in
                    /// to do on chunk rendered
                }
            )
        }
    }
}
```

---

### Image Tap Handling
MDLatex now supports **image tap callbacks** for implementing full-screen image viewers:

```swift
struct ContentView: View {
    @State private var showFullScreenImage = false
    @State private var selectedImageUrl = ""
    
    var body: some View {
        MDLatex.render(
            markdown: """
            # Images with Tap Support
            
            ![Sample Image](https://picsum.photos/300/200)
            
            | Description | Image |
            |-------------|-------|
            | **Photo 1** | ![Photo](https://picsum.photos/150/100?random=1) |
            | **Photo 2** | ![Photo](https://picsum.photos/150/100?random=2) |
            """,
            onImageTapped: { imageUrl in
                selectedImageUrl = imageUrl
                showFullScreenImage = true
            }
        )
        .sheet(isPresented: $showFullScreenImage) {
            FullScreenImageViewer(imageUrl: selectedImageUrl)
        }
    }
}
```

**Features:**
- ✅ **Tap Detection**: Automatically detects taps on any image in the rendered content
- ✅ **URL Extraction**: Provides the complete image URL when tapped
- ✅ **Visual Feedback**: Images show hover effects and pointer cursor
- ✅ **Table Support**: Works with images in table cells
- ✅ **Full Integration**: Compatible with both animated and non-animated rendering

---

### Enhanced Table Processing
MDLatex now features **complete LaTeX and Markdown support within table cells**:

```swift
MDLatex.render(
    markdown: """
    # Advanced Table with Mixed Content
    
    | **Physics Formulas** | **Description** | **Applications** |
    |----------------------|-----------------|------------------|
    | \\( E = mc^2 \\) | *Einstein's mass-energy equivalence* | `Nuclear physics` |
    | \\( F = ma \\) | **Newton's second law** | [Classical mechanics](https://example.com) |
    | \\( \\frac{1}{2}mv^2 \\) | ~~Potential~~ **Kinetic energy** | Motion analysis |
    | \\( \\sum_{i=1}^n F_i = 0 \\) | *Equilibrium condition* | `Statics problems` |
    
    ## What Works in Table Cells:
    - ✅ **LaTeX expressions**: \\( \\frac{a}{b} \\), \\( x^2 \\), \\[ \\int f(x)dx \\]
    - ✅ **Bold formatting**: **bold text**
    - ✅ **Italic formatting**: *italic text*
    - ✅ **Code formatting**: `inline code`
    - ✅ **Links**: [link text](url)
    - ✅ **Strikethrough**: ~~crossed out text~~
    - ✅ **Mixed content**: **Bold** with \\( math \\) and `code`
    """,
    theme: ThemeConfiguration(
        backgroundColor: .white,
        fontColor: .black,
        fontSize: 16
    )
)
```

---

### GitHub Flavored Markdown Features
MDLatex supports all GitHub Flavored Markdown features:

```swift
MDLatex.render(
    markdown: """
    # GFM Features Demo
    
    ## Tables
    | Feature | Status | Description |
    |---------|--------|-------------|
    | Tables | ✅ | Full table support with styling |
    | Strikethrough | ✅ | ~~Old text~~ **New text** |
    | Task Lists | ✅ | Interactive checkboxes |
    
    ## Task Lists
    - [x] Completed task
    - [ ] Pending task
    - [x] ~~Cancelled~~ Completed task
    
    ## Code Blocks
    ```swift
    let renderer = MDLatex.render(markdown: content)
    ```
    
    ## Other Features
    > Blockquotes are supported with proper styling
    
    **Bold**, *italic*, and `inline code` work perfectly.
    
    Horizontal rules work too:
    
    ---
    
    Math still works: \\(E = mc^2\\) and \\[\\sum_{i=1}^{n} x_i\\]
    """,
    theme: ThemeConfiguration(
        backgroundColor: .white,
        fontColor: .black,
        fontSize: 16
    ),
    animation: AnimationConfiguration(isEnabled: false)
)
```

---

### Advanced Table Support
MDLatex features **robust, generic table processing** that can handle complex and malformed table structures:

```swift
MDLatex.render(
    markdown: """
    # Complex Table Example
    
    | **Complex Tables** |
    | --- |
    | **Convex Mirror** | **Side View Mirror** |
    | ![image](https://example.com/mirror1.png)  
    - Used at sharp corners to see traffic
    - Placed in shops for security
    - **Virtual, erect, smaller images** | ![image](https://example.com/mirror2.png)  
    - Helps drivers see traffic behind
    - Mounted on vehicle sides
    - Images are **virtual, erect, smaller** |
    
    ## Features:
    - ✅ **Multi-line cell content** with images and bullet points
    - ✅ **Generic parsing** that works with any table structure
    - ✅ **No hardcoded patterns** - adapts to any content format
    - ✅ **Markdown processing** within table cells (bold, images, lists)
    - ✅ **LaTeX expressions** within table cells - **NEW in v2.0.1!**
    - ✅ **Works in both animation modes** (chunked and non-animated)
    """,
    theme: ThemeConfiguration(
        backgroundColor: .white,
        fontColor: .black,
        fontSize: 16
    ),
    animation: AnimationConfiguration(isEnabled: true, chunkRenderingDuration: 0.4)
)
```

**Key Capabilities:**
- **Complex Structures:** Handles malformed tables with inconsistent formatting
- **Multi-line Content:** Supports images, bullet points, and text spanning multiple lines within cells
- **Generic Processing:** Uses structural analysis instead of hardcoded patterns
- **Enhanced Cell Processing:** Full markdown AND LaTeX processing within individual table cells
- **Animation Support:** Works seamlessly in both chunked and non-animated rendering modes

---

### Customizing the Theme
Configure the theme using the fluent API:

```swift
MDLatex.render(
    markdown: """
    # Custom Theme Example
    
    This content will be rendered with custom styling.
    
    | Feature | Customizable | Math Example |
    |---------|-------------|--------------|
    | Font | ✅ | \\( f(x) = ax + b \\) |
    | Colors | ✅ | **Bold text** |
    | Size | ✅ | `Code snippet` |
    
    Math: \\(E = mc^2\\)
    """,
    theme: ThemeConfiguration(
        backgroundColor: .blue,
        fontColor: .white,
        fontSize: 20,
        fontFamily: "Helvetica",
        userInteractionEnabled: true
    ),
    animation: AnimationConfiguration(isEnabled: false),
    width: UIScreen.main.bounds.width - 32
)
```

---

### Animating Content
Enable chunk-based animations for rendering large content:

```swift
MDLatex.render(
    markdown: """
    # Animated Content Example
    
    ## Chunk 1
    This is the first chunk with **bold text** and a table:
    
    | Feature | Status | Math |
    |---------|--------|------|
    | Animation | ✅ | \\( \\alpha = \\frac{\\pi}{4} \\) |
    
    ## Chunk 2
    - [x] Task lists work
    - [ ] Pending item
    
    Math: \\(f(x) = x^2\\)
    
    ## Chunk 3
    > This is a blockquote in the final chunk
    
    ~~Old content~~ **New content**
    """,
    theme: ThemeConfiguration(
        backgroundColor: .white,
        fontColor: .black,
        fontSize: 16,
        fontFamily: "Arial"
    ),
    animation: AnimationConfiguration(isEnabled: true, chunkRenderingDuration: 0.3)
)
```

Use `onChunkRendered` and `onComplete` for callbacks:

```swift
MDLatex.render(
    markdown: """
    # Animated GFM Content
    
    ## Tables with LaTeX
    | Feature | Support | Formula |
    |---------|---------|---------|
    | GFM | ✅ | \\( \\sum_{i=1}^n i \\) |
    | LaTeX | ✅ | \\( E = mc^2 \\) |
    
    ## More content...
    """,
    animation: AnimationConfiguration(isEnabled: true, chunkRenderingDuration: 0.4)
)
.onChunkRendered { chunk, index in
    print("Rendered chunk \(index): \(chunk)")
}
.onComplete { finalHTML in
    print("Rendering complete: \(finalHTML)")
}
```

---

### Caching Content
Take advantage of caching in non-animated mode:

It by default caches the contents once rendered so you wont see a rerendering jitter

---

## How It Works

1. **Markdown Parsing:** Uses [Down](https://github.com/johnxnguyen/Down) to convert GitHub Flavored Markdown into HTML with native GFM table support.
2. **Enhanced Table Processing:** Custom table parser handles LaTeX expressions and full Markdown formatting within table cells with robust placeholder restoration.
3. **LaTeX Handling:** Extracts LaTeX expressions with a custom parser and injects them into the HTML using KaTeX with robust timing controls.
4. **Dynamic Rendering:** Supports chunk-based or one-go rendering with identical table processing capabilities in both modes.
5. **WebView Integration:** Leverages `WKWebView` for rendering HTML and JavaScript for KaTeX rendering with optimized performance.
6. **GitHub Flavored Markdown:** Full support for tables, strikethrough, task lists, and enhanced code blocks with production-ready optimization.

---

## Architecture

- **`AnimationConfiguration`:** Defines animation settings like duration and toggle for enabling animations.
- **`ThemeConfiguration`:** Handles theme properties like colors, font size, and font family.
- **`MarkdownLatexView`:** The main SwiftUI view for rendering Markdown and LaTeX with KaTeX loading detection.
- **`MarkdownLatexParser`:** Enhanced utility for extracting and reinjecting LaTeX expressions with HTML-escape handling.
- **`Enhanced Table Engine`:** Processes LaTeX expressions and Markdown formatting within table cells with robust placeholder restoration.
- **`katex_template.html`:** Optimized HTML template for KaTeX rendering with performance enhancements.
- **`Dual Rendering Modes`:** Both animated (chunked) and non-animated rendering with identical enhanced table processing capabilities.

---

## Example Project

https://github.com/user-attachments/assets/d3984f54-8272-4a7f-9c43-5a7de3da017f

---

## Changelog
🚀 **Enhanced Table Cell Processing & Image Interaction:**
- ✅ **Fixed LaTeX rendering in tables:** LaTeX expressions now render properly within table cells
- ✅ **Fixed Markdown rendering in tables:** Bold, italic, links, code, and strikethrough formatting now work in table cells
- ✅ **Enhanced table processing:** Improved HTML generation for tables with mixed content
- ✅ **Image tap callbacks:** Added `onImageTapped` parameter for handling image taps with URL extraction
- ✅ **Interactive image styling:** Images now show visual feedback (hover effects, pointer cursor)
- ✅ **Comprehensive testing:** Added extensive test coverage for table functionality and image callbacks
- ✅ **Backward compatibility:** All existing functionality preserved

**Technical Details:**
- Enhanced `MarkdownLatexParser.restoreLatexSegments()` to handle HTML-escaped placeholders
- Added `processTableCellMarkdown()` function for proper cell content processing
- Implemented JavaScript-to-native bridge for image tap detection via `WKScriptMessageHandler`
- Added `onImageTapped` fluent modifier and callback parameter to main render function
- Updated WebView coordinator to handle `imageTapped` messages from JavaScript
- Enhanced HTML template with image click handlers and visual feedback CSS
- Updated both animated and non-animated rendering pipelines
- Improved placeholder restoration logic for complex HTML contexts

---

## Contributions

We welcome contributions! To get started:
1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request.

For bugs or feature requests, open an issue in the repository.

---

## License

**MDLatex** is available under the MIT license. See the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

This package is built on:
- [Down](https://github.com/johnxnguyen/Down.git) for GitHub Flavored Markdown parsing with native table support.
- [KaTeX](https://katex.org) for fast, high-quality LaTeX rendering.
- Custom enhanced table processing engine for handling LaTeX expressions and Markdown formatting within table cells.

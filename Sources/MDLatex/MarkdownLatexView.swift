//
//  MarkdownLatexView.swift
//  MDLatex
//
//  Created by Kumar Shubham on 23/12/24.
//

import SwiftUI
import Down
import WebKit

/// A SwiftUI view that renders Markdown+LaTeX content using a WKWebView.
/// - If `animationConfig.isEnabled` is true, it renders the content in chunks,
///   otherwise, it does a one-go injection.
/// - Caches final HTML for repeated usage in non-animated mode.
/// - Injects a custom font and style into the base KaTeX skeleton.
struct MarkdownLatexView: View {
    
    // MARK: - ViewModel
    /// Holds a WKWebView reference, caching, and theme settings.
    class ViewModel: ObservableObject {
        @Published var webViewRef: WKWebView
        @Published var isWebViewReady: Bool = false  // Set true once the skeleton is loaded

        var animationConfig: AnimationConfiguration = AnimationConfiguration(isEnabled: false, chunkRenderingDuration: 0)
        var themeConfig: ThemeConfiguration = ThemeConfiguration(
                            backgroundColor: .black,
                            fontSize: 16,
                            userInteractionEnabled: true)
        
        /// Cache for storing final HTML keyed by original Markdown
        var renderedHTMLCache: [String: String] = [:]
        
        init() {
            self.webViewRef = WebViewPool.shared.getWebView()
        }
        
        deinit {
            WebViewPool.shared.returnWebView(self.webViewRef)
        }
    }
    
    // MARK: - Public Props
    let markdownContent: String
    var width: CGFloat = UIScreen.main.bounds.width
    
    @ObservedObject var viewModel: ViewModel
    
    // MARK: - Internal State
    @State var katexTemplate: String = ""    // Base KaTeX skeleton, injected with custom CSS
    @State private var webContentHeight: CGFloat = 0 // Height from the WebView
    @State var currentChunkIndex: Int = 0    // For chunk-based animation
    @State var markdownChunks: [String] = []
    
    // MARK: - Callbacks
    var onLoadingComplete: ((String) -> Void)?
    var onChunkRendered: ((String, Int) -> Void)?
    var onImageTapped: ((String) -> Void)?
    
    // MARK: - Body
    var body: some View {
        Group {
            if katexTemplate.isEmpty {
                // Show progress if KaTeX skeleton not yet loaded
                ProgressView("Loading Template...")
                    .frame(width: width, height: webContentHeight)
            } else {
                // If skeleton is loaded, use WebView
                WebView(
                    htmlContent: katexTemplate, // The base skeleton initially
                    isAnimationEnabled: viewModel.animationConfig.isEnabled,
                    themeConfig: viewModel.themeConfig,
                    webViewRef: $viewModel.webViewRef,
                    contentHeight: $webContentHeight,
                    onImageTapped: onImageTapped
                ) {
                    // onWebViewReady callback: skeleton loaded -> render
                    viewModel.isWebViewReady = true
                    if viewModel.animationConfig.isEnabled {
                        // Animated chunk-based flow
                        markdownChunks = splitMarkdownIntoChunks(markdownContent)
                        initializeForAnimation(
                            chunkCompletion: { chunk, idx in
                                onChunkRendered?(chunk, idx)
                            },
                            completion: {
                                onLoadingComplete?("") // all chunks done
                            }
                        )
                    } else {
                        // Single-shot flow, possibly with caching
                        renderAllContentAtOnceCached()
                    }
                }
                .frame(width: width, height: webContentHeight)
            }
        }
        .onAppear {
            // Load the KaTeX skeleton if not already loaded
            loadKatexTemplateIfNeeded()
        }
    }
}

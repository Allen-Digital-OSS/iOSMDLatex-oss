//
//  WebViewPool.swift
//  MDLatex
//
//  Created by Kumar Shubham on 19/01/25.
//

import SwiftUI
import WebKit

/// A singleton class that manages a pool of reusable `WKWebView` instances.
///
/// `WebViewPool` is designed to optimize the creation and reuse of `WKWebView` objects,
/// reducing memory overhead and initialization costs by maintaining a pool of pre-configured WebViews.
/// The pool has a configurable maximum size to control the number of cached WebViews.
///
/// ## Features
/// - Thread-safe access to the WebView pool using a concurrent queue with barrier writes.
/// - Limits the maximum number of cached WebViews to conserve memory.
/// - Cleans up `WKWebView` instances before returning them to the pool.
class WebViewPool {
    
    /// The shared singleton instance of `WebViewPool`.
    static let shared = WebViewPool()
    
    /// The maximum number of `WKWebView` instances that can be retained in the pool.
    private let maxPoolSize = 10
    
    /// Internal array holding the pool of reusable `WKWebView` instances.
    private var pool: [WKWebView] = []
    
    /// A concurrent queue used to synchronize access to the WebView pool.
    private let lockQueue = DispatchQueue(label: "com.webviewpool.lockQueue", attributes: .concurrent)
    
    // MARK: - Public Methods
    
    /// Retrieves a `WKWebView` instance from the pool or creates a new one if the pool is empty.
    ///
    /// - Returns: A `WKWebView` instance ready for use.
    ///
    /// This method ensures thread-safe access to the pool and avoids blocking the main thread.
    func getWebView() -> WKWebView {
        // Use a thread-safe queue to pop from the pool
        if let webView = lockQueue.sync(execute: { pool.popLast() }) {
            return webView
        }
        // If no WebView is available, create a new one
        return initializeWebView()
    }
    
    /// Cleans up and returns a `WKWebView` instance to the pool.
    ///
    /// - Parameter webView: The `WKWebView` instance to be returned to the pool.
    ///
    /// The method resets the WebView's state (e.g., clears content and removes delegates)
    /// and only appends it back to the pool if the pool has not reached its maximum size.
    func returnWebView(_ webView: WKWebView) {
        DispatchQueue.main.async {
            webView.loadHTMLString("", baseURL: nil) // Cleanup content
            webView.navigationDelegate = nil        // Detach navigation delegate
            webView.uiDelegate = nil                // Detach UI delegate
            
            // Return the cleaned-up WebView to the pool on a barrier queue
            self.lockQueue.async(flags: .barrier) {
                if self.pool.count < self.maxPoolSize {
                    self.pool.append(webView)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates or initializes a `WKWebView` instance on the appropriate thread.
    ///
    /// - Returns: A new `WKWebView` instance.
    ///
    /// This method ensures that the WebView initialization always occurs on the main thread,
    /// which is required by UIKit.
    private func initializeWebView() -> WKWebView {
        if Thread.isMainThread {
            return createWebView()
        } else {
            var webView: WKWebView?
            DispatchQueue.main.sync {
                webView = createWebView()
            }
            return webView!
        }
    }
    
    /// Creates a new instance of `WKWebView`.
    ///
    /// - Returns: A newly initialized `WKWebView` instance with default configurations.
    ///
    /// This method sets up a `WKWebView` with a user content controller and custom configuration.
    private func createWebView() -> WKWebView {
        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        return WKWebView(frame: .zero, configuration: configuration)
    }
}

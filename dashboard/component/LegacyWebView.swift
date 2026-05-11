import SwiftUI
import WebKit

struct Web: View {
    let url: URL
    let reloadToken: UUID
    let scrollTopToken: UUID

    var body: some View {
        WebView(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken)
    }
}

struct QueryWeb: View {
    let payload: WebPagePayload
    @State private var reloadToken = UUID()
    @State private var scrollTopToken = UUID()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white.ignoresSafeArea()
            if let url = URL(string: payload.urlString) {
                Web(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            HStack(spacing: 12) {
                action("arrow.up.to.line") { scrollTopToken = UUID() }
                action("arrow.clockwise") { reloadToken = UUID() }
            }
            .padding()
        }
        .navigationTitle(payload.title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func action(_ icon: String, callback: @escaping () -> Void) -> some View {
        Button(action: callback) {
            Image(systemName: icon)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .glassEffect()
    }
}


#if os(iOS)
struct WebView: UIViewRepresentable {
    let url: URL
    let reloadToken: UUID
    let scrollTopToken: UUID

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {

        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.customUserAgent = UAProvider.customUserAgent
        
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    
        context.coordinator.load(url, into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken, webView: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var lastURL: URL?
        private var lastReloadToken: UUID?
        private var lastScrollTopToken: UUID?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func load(_ url: URL, into webView: WKWebView) {
            lastURL = url
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
            if url.isFileURL {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            } else {
                webView.load(request)
            }
        }

        func update(url: URL, reloadToken: UUID, scrollTopToken: UUID, webView: WKWebView) {
            if lastURL != url {
                load(url, into: webView)
            }
            if lastReloadToken != reloadToken {
                lastReloadToken = reloadToken
                webView.reload()
            }
            if lastScrollTopToken != scrollTopToken {
                lastScrollTopToken = scrollTopToken
                webView.scrollView.setContentOffset(.zero, animated: true)
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[WebView Error] 无法加载: \(error.localizedDescription)")
        }
    }
}

#elseif os(macOS)
import AppKit

struct WebView: NSViewRepresentable {
    let url: URL
    let reloadToken: UUID
    let scrollTopToken: UUID

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        
        // 关键：注入 UA
        webView.customUserAgent = UAProvider.customUserAgent
        
        webView.navigationDelegate = context.coordinator
        
        context.coordinator.load(url, into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken, webView: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var lastURL: URL?
        private var lastReloadToken: UUID?
        private var lastScrollTopToken: UUID?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func load(_ url: URL, into webView: WKWebView) {
            lastURL = url
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20)
            if url.isFileURL {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            } else {
                webView.load(request)
            }
        }

        func update(url: URL, reloadToken: UUID, scrollTopToken: UUID, webView: WKWebView) {
            if lastURL != url {
                load(url, into: webView)
            }
            if lastReloadToken != reloadToken {
                lastReloadToken = reloadToken
                webView.reload()
            }
            if lastScrollTopToken != scrollTopToken {
                lastScrollTopToken = scrollTopToken
                webView.evaluateJavaScript("window.scrollTo({ top: 0, behavior: 'smooth' });")
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[macOS WebView Error] 无法加载: \(error.localizedDescription)")
        }
    }
}
#endif

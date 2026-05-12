import SwiftUI
import WebKit

@Observable
final class WebViewController {
    fileprivate weak var webView: WKWebView?
    var canGoBack = false

    func reload() {
        webView?.reload()
    }

    func scrollToTop() {
#if os(iOS)
        webView?.scrollView.setContentOffset(.zero, animated: true)
#elseif os(macOS)
        webView?.evaluateJavaScript("window.scrollTo({ top: 0, behavior: 'smooth' });")
#endif
    }

    func goBack() {
        guard let webView, webView.canGoBack else { return }
        webView.goBack()
    }
}

struct Web: View {
    let url: URL
    let controller: WebViewController

    var body: some View {
        WebView(url: url, controller: controller)
    }
}

struct QueryWeb: View {
    let payload: WebPagePayload
    @State private var controller = WebViewController()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white.ignoresSafeArea()
            if let url = URL(string: payload.urlString) {
                Web(url: url, controller: controller)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            HStack(spacing: 12) {
                action("arrow.up.to.line") { controller.scrollToTop() }
                action("arrow.clockwise") { controller.reload() }
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
    let controller: WebViewController

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
        context.coordinator.update(url: url, controller: controller, webView: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var lastURL: URL?

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

        func update(url: URL, controller: WebViewController, webView: WKWebView) {
            controller.webView = webView
            controller.canGoBack = webView.canGoBack
            if lastURL != url {
                load(url, into: webView)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.controller.canGoBack = webView.canGoBack
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.controller.canGoBack = webView.canGoBack
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.controller.canGoBack = webView.canGoBack
            print("[WebView Error] 无法加载: \(error.localizedDescription)")
        }
    }
}

#elseif os(macOS)
import AppKit

struct WebView: NSViewRepresentable {
    let url: URL
    let controller: WebViewController

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
        context.coordinator.update(url: url, controller: controller, webView: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        private var lastURL: URL?

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

        func update(url: URL, controller: WebViewController, webView: WKWebView) {
            controller.webView = webView
            controller.canGoBack = webView.canGoBack
            if lastURL != url {
                load(url, into: webView)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.controller.canGoBack = webView.canGoBack
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.controller.canGoBack = webView.canGoBack
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.controller.canGoBack = webView.canGoBack
            print("[macOS WebView Error] 无法加载: \(error.localizedDescription)")
        }
    }
}
#endif

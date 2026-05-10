import SwiftUI
import WebKit

struct Web: View {
    let url: URL
    let reloadToken: UUID
    let scrollTopToken: UUID
    let immersive: Bool

    var body: some View {
        PlatformWebView(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken, immersive: immersive)
    }
}

#if os(iOS)
struct PlatformWebView: UIViewRepresentable {
    let url: URL
    let reloadToken: UUID
    let scrollTopToken: UUID
    let immersive: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        // 使用默认配置，UA 在之后手动注入
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        
        // 关键：直接设置 customUserAgent 避开 applicationName 字符限制
        webView.customUserAgent = UAProvider.customUserAgent
        
        // 视觉设置
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = !immersive
        webView.backgroundColor = immersive ? .clear : .systemBackground
        webView.scrollView.backgroundColor = immersive ? .clear : .systemBackground
        
        context.coordinator.load(url, into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken, webView: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PlatformWebView
        private var lastURL: URL?
        private var lastReloadToken: UUID?
        private var lastScrollTopToken: UUID?

        init(_ parent: PlatformWebView) {
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

        // 调试反馈：如果网页加载不出，这里会打印原因
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ [WebView Error] 无法加载: \(error.localizedDescription)")
        }
    }
}

#elseif os(macOS)
import AppKit

struct PlatformWebView: NSViewRepresentable {
    let url: URL
    let reloadToken: UUID
    let scrollTopToken: UUID
    let immersive: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        
        // 关键：注入 UA
        webView.customUserAgent = UAProvider.customUserAgent
        
        webView.navigationDelegate = context.coordinator
        // macOS 特有的背景透明处理
        webView.setValue(!immersive, forKey: "drawsBackground")
        
        context.coordinator.load(url, into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken, webView: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PlatformWebView
        private var lastURL: URL?
        private var lastReloadToken: UUID?
        private var lastScrollTopToken: UUID?

        init(_ parent: PlatformWebView) {
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
                // macOS 下平滑滚动到顶部的 JS 实现
                webView.evaluateJavaScript("window.scrollTo({ top: 0, behavior: 'smooth' });")
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ [macOS WebView Error] 无法加载: \(error.localizedDescription)")
        }
    }
}
#endif

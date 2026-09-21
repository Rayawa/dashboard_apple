import SwiftUI
import WebKit

@MainActor
@Observable
final class WebViewController {
    fileprivate weak var webView: WKWebView?
    var canGoBack = false
    var isLoading = false
    var loadingProgress: Double = 0

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

private enum WebNavigationPolicy {
    static func allowsRemote(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https"
    }
}

private func makeWebView() -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.customUserAgent = UAProvider.customUserAgent
    return webView
}

@MainActor
final class WebViewCoordinator: NSObject, WKNavigationDelegate {
    private weak var controller: WebViewController?
    private var lastURL: URL?
    private var allowedFileDirectory: URL?

    init(controller: WebViewController) {
        self.controller = controller
    }

    func load(_ url: URL, into webView: WKWebView) {
        guard url.isFileURL || WebNavigationPolicy.allowsRemote(url) else { return }
        controller?.webView = webView
        controller?.canGoBack = webView.canGoBack
        lastURL = url
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = !url.isFileURL
        if url.isFileURL {
            let directory = url.deletingLastPathComponent().standardizedFileURL
            allowedFileDirectory = directory
            webView.loadFileURL(url, allowingReadAccessTo: directory)
        } else {
            allowedFileDirectory = nil
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            webView.load(request)
        }
    }

    func update(url: URL, webView: WKWebView) {
        controller?.webView = webView
        controller?.canGoBack = webView.canGoBack
        if lastURL != url {
            load(url, into: webView)
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url, allows(url) else {
            decisionHandler(.cancel)
            return
        }

        // Keep user-activated target=_blank links in the same audited WebView.
        if navigationAction.targetFrame == nil, navigationAction.navigationType == .linkActivated {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    private func allows(_ url: URL) -> Bool {
        if WebNavigationPolicy.allowsRemote(url) { return true }
        guard url.isFileURL, let allowedFileDirectory else { return false }
        let directoryPath = allowedFileDirectory.path.hasSuffix("/")
            ? allowedFileDirectory.path
            : allowedFileDirectory.path + "/"
        let candidate = url.standardizedFileURL.path
        return candidate == allowedFileDirectory.path || candidate.hasPrefix(directoryPath)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        controller?.isLoading = true
        controller?.loadingProgress = max(controller?.loadingProgress ?? 0, 0.02)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        controller?.canGoBack = webView.canGoBack
        controller?.loadingProgress = max(webView.estimatedProgress, 0.1)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        controller?.canGoBack = webView.canGoBack
        controller?.isLoading = false
        controller?.loadingProgress = 1
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        controller?.canGoBack = webView.canGoBack
        controller?.isLoading = false
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
        ZStack(alignment: .top) {
            dashboardPageBackground.ignoresSafeArea()
            Web(url: payload.url, controller: controller)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            WebLoadingProgressView(controller: controller)
        }
        .overlay(alignment: .bottomTrailing) {
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
        .background(.background)
        .clipShape(Circle())
        .overlay(Circle().stroke(.quaternary, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

struct WebLoadingProgressView: View {
    let controller: WebViewController

    var body: some View {
        if controller.isLoading {
            ProgressView(value: max(controller.loadingProgress, 0.02))
                .progressViewStyle(.linear)
                .tint(.blue)
                .background(dashboardPageBackground.opacity(0.92))
        }
    }
}

#if os(iOS)
struct WebView: UIViewRepresentable {
    let url: URL
    let controller: WebViewController

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(controller: controller)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = makeWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.load(url, into: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(url: url, webView: webView)
    }
}
#elseif os(macOS)
struct WebView: NSViewRepresentable {
    let url: URL
    let controller: WebViewController

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(controller: controller)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = makeWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.load(url, into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(url: url, webView: webView)
    }
}
#endif

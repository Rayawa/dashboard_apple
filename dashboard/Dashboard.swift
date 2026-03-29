import SwiftUI
import WebKit

// MARK: - 1. 核心 WebView 组件
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var reloadTrigger: Bool
    @Binding var scrollToTopTrigger: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if reloadTrigger {
            uiView.reload()
            DispatchQueue.main.async { reloadTrigger = false }
        }
        
        if scrollToTopTrigger {
            uiView.scrollView.setContentOffset(.zero, animated: true)
            DispatchQueue.main.async { scrollToTopTrigger = false }
        }
    }
}

// MARK: - 2. 主视图
struct DashboardView: View {
    // 修正 URL 定义
    private let sBaseUrl = "http://shenjack.top:10003/dashboard"
    private let tBaseUrl = "http://hmtxit.top/dashboard"
    
    // 状态控制
    @State private var reloadTrigger = false
    @State private var scrollToTopTrigger = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 安全解包 URL
            if let url = URL(string: sBaseUrl) {
                WebView(url: url,
                        reloadTrigger: $reloadTrigger,
                        scrollToTopTrigger: $scrollToTopTrigger)
                    .edgesIgnoringSafeArea(.top)
            } else {
                Text("Invalid URL")
            }
            
            // 控制面板
            ControlBar(reload: $reloadTrigger, scrollTop: $scrollToTopTrigger)
        }
    }
}

// MARK: - 3. 提取出的按钮组件 (保持代码整洁)
struct ControlBar: View {
    @Binding var reload: Bool
    @Binding var scrollTop: Bool
    
    var body: some View {
        HStack {
            Button(action: { reload = true }) {
                Label("刷新", systemImage: "arrow.clockwise")
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            
            Divider().frame(height: 30)
            
            Button(action: { scrollTop = true }) {
                Label("顶部", systemImage: "arrow.up.to.line")
                    .padding()
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    DashboardView()
}

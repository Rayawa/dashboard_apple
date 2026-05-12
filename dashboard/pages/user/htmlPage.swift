import SwiftUI

struct HTMLPageView: View {
    let payload: HTMLPagePayload
    @State private var controller = WebViewController()

    var body: some View {
        ZStack {
            dashboardPageBackground.ignoresSafeArea()
            Group {
                if let url = Bundle.main.url(forResource: payload.resourceName, withExtension: "html", subdirectory: "resources") ?? Bundle.main.url(forResource: payload.resourceName, withExtension: "html") {
                    Web(url: url, controller: controller)
                } else {
                    ScrollView {
                        Text("未找到本地资源：\(payload.resourceName).html")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            WebLoadingProgressView(controller: controller)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle(payload.title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

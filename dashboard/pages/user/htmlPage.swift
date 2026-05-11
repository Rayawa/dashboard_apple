import SwiftUI

struct HTMLPageView: View {
    let payload: HTMLPagePayload

    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: payload.resourceName, withExtension: "html", subdirectory: "resources") ?? Bundle.main.url(forResource: payload.resourceName, withExtension: "html") {
                Web(url: url, reloadToken: UUID(), scrollTopToken: UUID())
            } else {
                ScrollView {
                    Text("未找到本地资源：\(payload.resourceName).html")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .navigationTitle(payload.title)
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

import SwiftUI

struct AppQueryComponent: View {
    @State private var inputText = ""
    @State private var formData = FormData()
    let onSuccess: (WebPagePayload) -> Void

    var body: some View {
        Form {
            Section("AI智能提取") {
                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                Text("支持应用名称、华为商店分享链接、包名和 AppID")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("查询信息") {
                TextField("应用名称", text: $formData.appName)
                TextField("应用详情页链接", text: $formData.appLink)
                TextField("包名", text: $formData.packageName)
                TextField("AppID", text: $formData.appId)
            }

            Section {
                QueryButtonsComponent(formData: $formData, inputText: $inputText, onSuccess: onSuccess)
            }
        }
        .navigationTitle("查询应用")
        .onChange(of: inputText) { _, newValue in
            let extracted = NaturalLanguageExtractor.extract(from: newValue)
            if let name = extracted.appName { formData.appName = name }
            if let link = extracted.appLink { formData.appLink = link }
            if let package = extracted.packageName { formData.packageName = package }
            if let appId = extracted.appId { formData.appId = appId }
        }
    }
}

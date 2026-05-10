import SwiftUI

struct AppSubmitComponent: View {
    @AppStorage(DashboardSettings.userName) private var userName = ""
    @State private var inputText = ""
    @State private var formData = FormData()

    var body: some View {
        Form {
            Section("AI智能提取") {
                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                Text("粘贴或输入应用信息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("投稿信息") {
                TextField("应用详情页链接（可选）", text: $formData.appLink)
                TextField("包名", text: $formData.packageName)
                TextField("AppID", text: $formData.appId)
                TextField("备注（可选）", text: $formData.remark, axis: .vertical)
            }

            Section {
                SubmitButtonsComponent(formData: $formData, inputText: $inputText, userName: userName)
            }
        }
        .navigationTitle("投稿/更新应用")
        .onChange(of: inputText) { _, newValue in
            let extracted = NaturalLanguageExtractor.extract(from: newValue)
            if let link = extracted.appLink { formData.appLink = link }
            if let package = extracted.packageName { formData.packageName = package }
            if let appId = extracted.appId { formData.appId = appId }
            if let date = extracted.date {
                let oldRemark = formData.remark.replacingOccurrences(of: #"提取日期:\s*[\d-]+\n?"#, with: "", options: .regularExpression)
                formData.remark = oldRemark.isEmpty ? "提取日期: \(date)" : "提取日期: \(date)\n\(oldRemark)"
            }
        }
    }
}

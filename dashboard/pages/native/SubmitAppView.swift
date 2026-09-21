import SwiftUI

struct SubmitAppView: View {
    @AppStorage("username") private var username = ""
    @State private var packageName = ""
    @State private var appID = ""
    @State private var isSubmitting = false
    @State private var resultMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("应用信息") {
                TextField("包名，例如 com.example.app", text: $packageName)
                    .textContentType(.URL)
                TextField("App ID，例如 C10084839", text: $appID)
                Text("填写包名或 App ID 其中一项即可；包名优先。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("提交者") {
                TextField("用户名（可选）", text: $username)
                Text("用户名会随投稿与更新请求提交。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Label("提交应用", systemImage: "paperplane.fill").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting || (packageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && appID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("投稿应用")
        .alert("提交成功", isPresented: Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })) {
            Button("确定", role: .cancel) {}
        } message: { Text(resultMessage ?? "") }
        .alert("提交失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("确定", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let response = try await AppAPIService.submitApp(
                packageName: packageName,
                appId: appID,
                remark: username
            )
            let submittedName = response.data.fullInfo.name
            packageName = ""
            appID = ""
            resultMessage = "\(submittedName) 已完成抓取或更新。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

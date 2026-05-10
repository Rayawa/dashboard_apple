import SwiftUI

struct SubmitButtonsComponent: View {
    @Binding var formData: FormData
    @Binding var inputText: String
    let userName: String

    @State private var isSubmitting = false
    @State private var message: String?

    var body: some View {
        HStack {
            Button("清空") {
                formData.clear(includeName: true)
                inputText = ""
            }
            .buttonStyle(.bordered)
            .tint(.green)

            Button(isSubmitting ? "提交中..." : "提交投稿") {
                Task { await submit() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting)
        }
        .alert("提示", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await AppAPIService.submitApp(
                packageName: formData.packageName,
                appId: formData.appId,
                userName: userName,
                remark: formData.remark
            )
            formData.clear(includeName: true)
            inputText = ""
            message = "提交成功，感谢您的投稿！"
        } catch {
            message = error.localizedDescription
        }
    }
}

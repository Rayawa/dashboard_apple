import SwiftUI

struct QueryButtonsComponent: View {
    @Binding var formData: FormData
    @Binding var inputText: String
    let onSuccess: (WebPagePayload) -> Void

    @State private var isSearching = false
    @State private var message: String?

    var body: some View {
        HStack {
            Button("清空") {
                formData.clear(includeName: true)
                inputText = ""
            }
            .buttonStyle(.bordered)
            .tint(.green)

            Button(isSearching ? "查询中..." : "查询") {
                Task { await query() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(isSearching)
        }
        .alert("提示", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    @MainActor
    private func query() async {
        isSearching = true
        defer { isSearching = false }

        do {
            let appID: String
            let directId = formData.appId.trimmingCharacters(in: .whitespacesAndNewlines)
            let packageName = formData.packageName.trimmingCharacters(in: .whitespacesAndNewlines)
            let appLink = formData.appLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let appName = formData.appName.trimmingCharacters(in: .whitespacesAndNewlines)

            if directId.hasPrefix("C") {
                appID = directId
            } else if !packageName.isEmpty {
                appID = try await AppAPIService.appId(byPackage: packageName)
            } else if let package = extractPackageName(from: appLink) {
                appID = try await AppAPIService.appId(byPackage: package)
            } else if !appName.isEmpty {
                appID = try await AppAPIService.appId(byName: appName)
            } else {
                throw APIError.invalidInput("请输入任何有效信息")
            }

            guard try await AppAPIService.verify(appId: appID) else {
                throw APIError.notFound("库中未找到该应用")
            }

            formData.clear(includeName: true)
            inputText = ""
            onSuccess(WebPagePayload(title: "查询结果", urlString: AppAPIService.resultURL(for: appID).absoluteString))
        } catch {
            message = error.localizedDescription
        }
    }

    private func extractPackageName(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString) else { return nil }
        return components.queryItems?.first(where: { $0.name == "id" })?.value
    }
}

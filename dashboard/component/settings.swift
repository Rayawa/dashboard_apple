import SwiftUI
import WebKit

struct SettingsComponent: View {
    @State private var showClearAlert = false

    var body: some View {
        VStack(spacing: 14) {
            Button(role: .destructive) {
                showClearAlert = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 38, height: 38)

                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.red)
                    }

                    Text("清除缓存")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.red)

                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .alert("清除缓存", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("继续", role: .destructive) {
                let store = WKWebsiteDataStore.default()
                let types = WKWebsiteDataStore.allWebsiteDataTypes()
                store.fetchDataRecords(ofTypes: types) { records in
                    store.removeData(ofTypes: types, for: records) {}
                }
            }
        } message: {
            Text("这会删除当前 WebView 缓存和 Cookie。")
        }
    }
}

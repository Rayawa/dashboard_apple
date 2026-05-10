import SwiftUI

struct QueryWebPageView: View {
    let payload: WebPagePayload
    @AppStorage(DashboardSettings.immersiveTexture) private var immersiveTexture = SettingsStorage.defaultImmersiveTexture
    @State private var reloadToken = UUID()
    @State private var scrollTopToken = UUID()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white.ignoresSafeArea()
            if let url = URL(string: payload.urlString) {
                Web(url: url, reloadToken: reloadToken, scrollTopToken: scrollTopToken, immersive: immersiveTexture)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            HStack(spacing: 12) {
                action("arrow.up.to.line") { scrollTopToken = UUID() }
                action("arrow.clockwise") { reloadToken = UUID() }
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
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .glassEffect()
    }
}

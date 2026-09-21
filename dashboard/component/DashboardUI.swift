import SwiftUI

struct DashboardCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.quaternary, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
    }
}

struct AppIconView: View {
    let app: MarketApp
    var size: CGFloat = 52

    var body: some View {
        AsyncImage(url: app.iconURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                ZStack {
                    Color.accentColor.opacity(0.12)
                    Image(systemName: "app.fill")
                        .foregroundStyle(.tint)
                        .font(.system(size: size * 0.42))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityLabel("\(app.name)图标")
    }
}

struct OfflineCacheBanner: View {
    let cachedAt: Date?

    var body: some View {
        Label {
            if let cachedAt {
                Text("网络不可用，显示 \(cachedAt.formatted(date: .abbreviated, time: .shortened)) 的离线缓存")
            } else {
                Text("当前显示离线缓存")
            }
        } icon: {
            Image(systemName: "wifi.slash")
        }
        .font(.footnote)
        .foregroundStyle(.orange)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.orange.opacity(0.1), in: Capsule())
        .accessibilityLabel("当前显示离线缓存数据")
    }
}

struct LoadingStateView: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(text).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("重试", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

extension View {
    func dashboardPage() -> some View {
        background(dashboardPageBackground.ignoresSafeArea())
    }
}

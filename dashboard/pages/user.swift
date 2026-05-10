import SwiftUI

struct UserPageView: View {
    @Environment(\.openURL) private var openURL
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                section("用户与应用") {
                    VStack(spacing: 14) {
                        navRow("投稿/更新应用", systemImage: "square.and.pencil") { onNavigate(.submit) }
                        navRow("查询应用", systemImage: "magnifyingglass") { onNavigate(.query) }
                    }
                }

                section("设置") {
                    SettingsComponent()
                }

                section("更多") {
                    VStack(spacing: 12) {
                        Button {
                            openURL(DashboardURLs.mainPage)
                        } label: {
                            rowLabel("项目网站首页", systemImage: "house")
                        }
                        .buttonStyle(.plain)

                        Button {
                            onNavigate(.friends)
                        } label: {
                            rowLabel("友情链接", systemImage: "link")
                        }
                        .buttonStyle(.plain)

                        Button {
                            onNavigate(.contact)
                        } label: {
                            rowLabel("联系我们", systemImage: "person.2")
                        }
                        .buttonStyle(.plain)

                        Button {
                            onNavigate(.about)
                        } label: {
                            rowLabel("关于应用", systemImage: "info.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("我的")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        }
    }

    private func navRow(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(title, systemImage: systemImage) }
            .buttonStyle(.plain)
    }

    private func rowLabel(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

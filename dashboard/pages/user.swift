import SwiftUI

struct UserPageView: View {
    @Environment(\.openURL) private var openURL
    let onNavigate: (AppRoute) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 238 / 255, green: 246 / 255, blue: 254 / 255),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {

                    section("应用") {
                        VStack(spacing: 0) {
                            navRow("投稿/更新应用", systemImage: "square.and.pencil") {
                                onNavigate(.submit)
                            }

                            Divider()
                                .opacity(0.70)

                            navRow("查询应用", systemImage: "magnifyingglass") {
                                onNavigate(.query(nil))
                            }
                        }
                    }

                    section("更多") {
                        VStack(spacing: 0) {
                            Button {
                                openURL(DashboardURLs.mainPage)
                            } label: {
                                rowLabel("项目网站首页", systemImage: "house")
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .opacity(0.70)

                            Button {
                                onNavigate(.friends)
                            } label: {
                                rowLabel("友情链接", systemImage: "link")
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .opacity(0.70)

                            Button {
                                onNavigate(.contact)
                            } label: {
                                rowLabel("联系我们", systemImage: "person.2")
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .opacity(0.70)

                            Button {
                                onNavigate(.about)
                            } label: {
                                rowLabel("关于应用", systemImage: "info.circle")
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .opacity(0.70)
                                .padding(.vertical, 2)

                            SettingsComponent()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        }
    }

    private func navRow(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowLabel(title, systemImage: systemImage)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 38, height: 38)

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Text(title)
                .font(.body.weight(.medium))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 10)
    }
}

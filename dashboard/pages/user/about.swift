import SwiftUI

struct AboutPageView: View {
    let onOpenModal: (AppRoute) -> Void
    @State private var showWarn = false

    var body: some View {
        ZStack {
            dashboardPageBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 10) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 72))
                        Text("Hm应用看板")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("HmDashboard")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 30)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 18) {
                    VStack(spacing: 12) {
                        Button {
                            showWarn = true
                        } label: {
                            row("重要提示", icon: "exclamationmark.triangle.fill", tint: .red)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onOpenModal(.aboutWeb(.init(title: "API文档说明", urlString: DashboardURLs.sBase.appending(path: "docs").absoluteString)))
                        } label: {
                            row("API文档说明", icon: "doc.text")
                        }
                        .buttonStyle(.plain)

                        Button {
                            onOpenModal(.aboutWeb(.init(title: "Web更新日志", urlString: DashboardURLs.tBase.appending(path: "changelog").absoluteString)))
                        } label: {
                            row("Web更新日志", icon: "network")
                        }
                        .buttonStyle(.plain)

                        Button {
                            onOpenModal(.appLog)
                        } label: {
                            row("App更新日志", icon: "clock.arrow.circlepath")
                        }
                        .buttonStyle(.plain)

                        Button {
                            onOpenModal(.htmlPage(.init(title: "隐私政策", resourceName: "privacy")))
                        } label: {
                            row("隐私政策", icon: "hand.raised")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                    VStack(spacing: 4) {
                        Text("版本 \(DashboardMeta.appVersion)").font(.footnote).foregroundStyle(.secondary)
                        Text("Designed & Developed by Ray Chen (Rayawa)").font(.footnote).foregroundStyle(.secondary)
                        Text("Copyright © 2026. All rights reserved.").font(.footnote).foregroundStyle(.secondary)
                        Link("京ICP备2025153453号", destination: DashboardURLs.miit).font(.footnote)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("关于应用")
        .sheet(isPresented: $showWarn) {
            NavigationStack {
                WarnComponent()
                    .padding()
                    .navigationTitle("重要提示")
                    #if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .dashboardModalCloseToolbar()
        }
    }

    private func row(_ title: String, icon: String, tint: Color = .primary) -> some View {
        HStack {
            Label(title, systemImage: icon).foregroundStyle(tint)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

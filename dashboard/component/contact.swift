import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ContactComponent: View {
    @Environment(\.openURL) private var openURL
    @State private var copiedMessage: String?

    var body: some View {
        ZStack {
            dashboardPageBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    ContactItem(title: "主要负责人", name: "shenjack", detail: "邮箱：3695888@qq.com") {
                        copy("3695888@qq.com", label: "邮箱")
                    }
                    ContactItem(title: "T站网页负责人", name: "tianxiu2b2t", detail: "邮箱：administrator@ttb-network.top") {
                        copy("administrator@ttb-network.top", label: "邮箱")
                    }
                    ContactItem(title: "客户端开发", name: "清霁·Rayawa", detail: "邮箱：rayawa.work@outlook.com") {
                        copy("rayawa.work@outlook.com", label: "邮箱")
                    }
                    ContactItem(title: "QQ群", name: "Harmony Dashboard 官方交流群", detail: "群号：757273833") {
                        copy("757273833", label: "群号")
                    }
                    ContactItem(title: "赞助我们", name: "支持项目发展", detail: "点击跳转到爱发电赞助页面") {
                        openURL(DashboardURLs.sponsor)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("联系我们")
        .alert("提示", isPresented: Binding(get: { copiedMessage != nil }, set: { if !$0 { copiedMessage = nil } })) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(copiedMessage ?? "")
        }
    }

    private func copy(_ value: String, label: String) {
        #if os(iOS)
        UIPasteboard.general.string = value
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        #endif
        copiedMessage = "已复制\(label)"
    }
}

private struct ContactItem: View {
    let title: String
    let name: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title).font(.headline)
                Text(name).font(.subheadline).foregroundStyle(.secondary)
                Text(detail).font(.footnote).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.quaternary))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

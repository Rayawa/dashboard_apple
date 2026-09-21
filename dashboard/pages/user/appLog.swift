import SwiftUI

struct AppLogPageView: View {
    @State private var enabledTypes: Set<ReleaseType> = Set(ReleaseType.allCases)

    var body: some View {
        let filteredLogs = updateLogs.filter { enabledTypes.contains($0.type) }
        ZStack {
            dashboardPageBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        ForEach(ReleaseType.allCases, id: \.self) { type in
                            Button {
                                if enabledTypes.contains(type) {
                                    enabledTypes.remove(type)
                                } else {
                                    enabledTypes.insert(type)
                                }
                            } label: {
                                Text(type.title)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(enabledTypes.contains(type) ? Color.accentColor.opacity(0.14) : Color.clear))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(.background, in: Capsule())
                    .overlay(Capsule().stroke(.quaternary, lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                    if filteredLogs.isEmpty {
                        ContentUnavailableView(
                            "没有选中的版本类型",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("选择 Beta、RC 或 Release 以查看更新记录。")
                        )
                        .padding(.top, 36)
                    }

                    ForEach(filteredLogs) { log in
                        DashboardCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(log.version).font(.headline)
                                    Spacer()
                                    Text(log.date).font(.footnote).foregroundStyle(.secondary)
                                }
                                Text(log.type.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                ForEach(log.items, id: \.self) { item in
                                    Text("• \(item)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("App更新日志")
    }
}

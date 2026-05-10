import SwiftUI

struct AppLogPageView: View {
    @State private var enabledTypes: Set<ReleaseType> = Set(ReleaseType.allCases)

    var body: some View {
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
                                .background(Capsule().fill(enabledTypes.contains(type) ? Color.white.opacity(0.62) : Color.clear))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

                ForEach(updateLogs.filter { enabledTypes.contains($0.type) }) { log in
                    VStack(alignment: .leading, spacing: 10) {
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
                    .padding(16)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("App更新日志")
    }
}

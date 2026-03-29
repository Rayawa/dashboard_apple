import SwiftUI
struct FloatingPanel: View {
    var onTop: () -> Void
    var onRefresh: () -> Void

    var body: some View {
        GlassContainer {
            VStack(spacing: 12) {
                Button(action: onTop) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.plain)

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .font(.title2)
        }
        .frame(width: 50)
    }
}

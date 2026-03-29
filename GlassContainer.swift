import SwiftUI

struct GlassContainer<Content: View>: View {
    var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.6),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            content()
                .padding(10)
        }
        .shadow(color: .black.opacity(0.2), radius: 15)
    }
}

import SwiftUI
struct GlassNavBar: View {
    @Binding var currentIndex: Int
    let count: Int

    var body: some View {
        GlassContainer {
            HStack(spacing: 10) {
                ForEach(0..<count, id: \.self) { i in
                    Circle()
                        .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            currentIndex = i
                        }
                        .animation(.easeInOut, value: currentIndex)
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 30)
    }
}

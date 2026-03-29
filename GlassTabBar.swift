import SwiftUI
struct GlassTabBar: View {
    @Binding var currentIndex: Int
    let titles: [String]

    var body: some View {
        GlassContainer {
            HStack {
                ForEach(0..<titles.count, id: \.self) { i in
                    Button(action: {
                        currentIndex = i
                    }) {
                        Text(titles[i])
                            .foregroundColor(i == currentIndex ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 50)
    }
}

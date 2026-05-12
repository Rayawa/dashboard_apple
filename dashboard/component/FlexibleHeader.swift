import SwiftUI

private struct FlexibleHeaderOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private extension EnvironmentValues {
    var flexibleHeaderOffset: CGFloat {
        get { self[FlexibleHeaderOffsetKey.self] }
        set { self[FlexibleHeaderOffsetKey.self] = newValue }
    }
}

private struct FlexibleHeaderContentModifier: ViewModifier {
    @Environment(\.flexibleHeaderOffset) private var offset
    let minHeight: CGFloat

    func body(content: Content) -> some View {
        let height = max(minHeight - offset, minHeight)
        content
            .frame(height: height)
            .padding(.bottom, offset)
            .offset(y: offset)
    }
}

private struct FlexibleHeaderScrollViewModifier: ViewModifier {
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { scrollGeometry in
                min(scrollGeometry.contentOffset.y + scrollGeometry.contentInsets.top, 0)
            } action: { _, offset in
                self.offset = offset
            }
            .environment(\.flexibleHeaderOffset, offset)
    }
}

extension View {
    @MainActor func flexibleHeaderScrollView() -> some View {
        modifier(FlexibleHeaderScrollViewModifier())
    }

    func flexibleHeaderContent(minHeight: CGFloat) -> some View {
        modifier(FlexibleHeaderContentModifier(minHeight: minHeight))
    }
}

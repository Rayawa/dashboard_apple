import SwiftUI

@Observable
private final class FlexibleHeaderGeometry {
    var offset: CGFloat = 0
}

private struct FlexibleHeaderContentModifier: ViewModifier {
    @Environment(FlexibleHeaderGeometry.self) private var geometry
    let minHeight: CGFloat

    func body(content: Content) -> some View {
        let height = max(minHeight - geometry.offset, minHeight)
        content
            .frame(height: height)
            .padding(.bottom, geometry.offset)
            .offset(y: geometry.offset)
    }
}

private struct FlexibleHeaderScrollViewModifier: ViewModifier {
    @State private var geometry = FlexibleHeaderGeometry()

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { scrollGeometry in
                min(scrollGeometry.contentOffset.y + scrollGeometry.contentInsets.top, 0)
            } action: { _, offset in
                geometry.offset = offset
            }
            .environment(geometry)
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

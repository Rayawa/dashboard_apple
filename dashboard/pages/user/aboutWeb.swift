import SwiftUI

struct AboutWebPageView: View {
    let payload: WebPagePayload

    var body: some View {
        QueryWebPageView(payload: payload)
    }
}

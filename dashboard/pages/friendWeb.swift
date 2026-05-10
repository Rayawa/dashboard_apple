import SwiftUI

struct FriendWebPageView: View {
    let payload: WebPagePayload

    var body: some View {
        QueryWebPageView(payload: payload)
    }
}

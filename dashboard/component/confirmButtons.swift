import SwiftUI

struct ConfirmButtons: View {
    let onConfirm: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button("确定", action: onConfirm)
                .buttonStyle(.borderedProminent)
        }
    }
}

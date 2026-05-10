import SwiftUI

struct TutorialComponent: View {
    var body: some View {
        ScrollView {
            Text("教程页暂未迁移。")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("教程")
    }
}

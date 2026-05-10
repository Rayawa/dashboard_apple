import SwiftUI
import WebKit

struct SettingsComponent: View {
    @AppStorage(DashboardSettings.vibration) private var vibrationOn = SettingsStorage.defaultVibration
    @AppStorage(DashboardSettings.holdCheck) private var holdCheckOn = SettingsStorage.defaultHoldCheck
    @AppStorage(DashboardSettings.buttonRight) private var buttonRight = SettingsStorage.defaultButtonRight
    @AppStorage(DashboardSettings.tabBarAuto) private var tabBarAuto = SettingsStorage.defaultTabBarAuto
    @AppStorage(DashboardSettings.immersiveTexture) private var immersiveTexture = SettingsStorage.defaultImmersiveTexture
    @State private var showClearAlert = false

    var body: some View {
        VStack(spacing: 14) {
            Toggle("全局振动反馈", isOn: $vibrationOn)
            Toggle("按钮智感握持", isOn: $holdCheckOn)
            Toggle("自动隐藏底部栏", isOn: $tabBarAuto)
            Toggle("使用沉浸式材质", isOn: $immersiveTexture)

            VStack(alignment: .leading, spacing: 8) {
                Text("按钮默认位置")
                    .font(.subheadline.weight(.semibold))
                Picker("按钮默认位置", selection: $buttonRight) {
                    Text("左").tag(false)
                    Text("右").tag(true)
                }
                .pickerStyle(.segmented)
            }

            Button(role: .destructive) {
                showClearAlert = true
            } label: {
                Label("清除缓存", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .alert("清除缓存", isPresented: $showClearAlert) {
            Button("取消", role: .cancel) {}
            Button("继续", role: .destructive) {
                let store = WKWebsiteDataStore.default()
                let types = WKWebsiteDataStore.allWebsiteDataTypes()
                store.fetchDataRecords(ofTypes: types) { records in
                    store.removeData(ofTypes: types, for: records) {}
                }
            }
        } message: {
            Text("这会删除当前 WebView 缓存和 Cookie。")
        }
    }
}

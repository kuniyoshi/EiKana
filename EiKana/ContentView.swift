import SwiftUI
import SwiftData
import Foundation
import ServiceManagement
struct ContentView: View {
    @AppStorage("modifierKeyType") private var modifierKeyType: String = "control"
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        VStack(spacing: 20) {
            Picker("切り替えキー", selection: $modifierKeyType) {
                Text("Control").tag("control")
                Text("Command").tag("command")
            }
            .pickerStyle(.segmented)
            .padding()
            Toggle("ログイン時に起動", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { oldValue, newValue in
                    updateLaunchAtLogin(newValue)
                }
                .padding(.horizontal)
        }
        .padding()
        .onAppear {
            checkLaunchAtLoginStatus()
        }
    }
    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
                launchAtLogin = !enabled
            }
        }
    }
    private func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
#Preview {
    ContentView()
}

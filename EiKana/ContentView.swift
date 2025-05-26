import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @AppStorage("modifierKeyType") private var modifierKeyType: String = "control"
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Picker("切り替えキー", selection: $modifierKeyType) {
                Text("Control").tag("control")
                Text("Command").tag("command")
            }
            .pickerStyle(.segmented)
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

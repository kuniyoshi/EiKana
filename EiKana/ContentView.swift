import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @AppStorage("userName") private var userName: String = ""
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Text("ようこそ、\(userName)さん！")
                .font(.headline)
            TextField("ユーザー名を入力", text: $userName)
                .textFieldStyle(.roundedBorder)
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

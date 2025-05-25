import SwiftUI
import SwiftData
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "bird.fill",
                accessibilityDescription: Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            )
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.menu = menu
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

@main
struct EiKanaApp: App {
    private let imeManager = IMEManager()

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        Settings {
        }
    }
}

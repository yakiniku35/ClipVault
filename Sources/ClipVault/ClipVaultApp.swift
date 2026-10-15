import AppKit
import SwiftUI

@main
struct ClipVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            HistoryView()
                .environmentObject(appDelegate.settings)
                .environmentObject(appDelegate.store)
                .environmentObject(appDelegate.monitor)
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appDelegate.settings)
                .environmentObject(appDelegate.store)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings: AppSettings
    let store: HistoryStore
    let monitor: ClipboardMonitor

    override init() {
        let settings = AppSettings()
        self.settings = settings
        self.store = HistoryStore(settings: settings)
        self.monitor = ClipboardMonitor(settings: settings)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        monitor.onCapture = { [weak self] item in
            self?.store.add(item)
        }
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.saveNow()
    }
}

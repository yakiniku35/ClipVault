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
            MenuBarIcon.image
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

/// Custom template glyph for the menu bar, rendered by scripts/make-icon.swift.
/// Falls back to an SF Symbol when running the bare binary outside the bundle.
enum MenuBarIcon {
    static var image: Image {
        if let nsImage = Bundle.main.image(forResource: "MenuBarIcon") {
            nsImage.isTemplate = true
            nsImage.size = NSSize(width: 18, height: 18)
            return Image(nsImage: nsImage)
        }
        return Image(systemName: "doc.on.clipboard")
    }
}

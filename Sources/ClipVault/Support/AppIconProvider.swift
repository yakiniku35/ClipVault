import AppKit
import Foundation

/// Caches app icons and display names looked up by bundle identifier.
@MainActor
enum AppIconProvider {
    private static var iconCache: [String: NSImage] = [:]
    private static var nameCache: [String: String] = [:]

    static func icon(forBundleID bundleID: String?) -> NSImage {
        guard let bundleID else { return genericIcon }
        if let cached = iconCache[bundleID] { return cached }
        let image: NSImage
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            image = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            image = genericIcon
        }
        iconCache[bundleID] = image
        return image
    }

    static func name(forBundleID bundleID: String) -> String {
        if let cached = nameCache[bundleID] { return cached }
        var name = bundleID
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            name = FileManager.default.displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        nameCache[bundleID] = name
        return name
    }

    private static var genericIcon: NSImage {
        NSWorkspace.shared.icon(for: .applicationBundle)
    }
}

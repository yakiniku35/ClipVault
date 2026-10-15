import AppKit
import Foundation

/// Best-effort detection of the web page a clip was copied from.
///
/// Chromium browsers attach the page URL to the pasteboard directly. For
/// Safari (and as a fallback for the others) we ask the browser for its
/// front tab via AppleScript, which requires the user to grant Automation
/// access the first time. AppleScript can block for a long time, so it is
/// run on a dedicated background queue and awaited.
enum SourceURLResolver {
    static let chromiumSourceURLType = NSPasteboard.PasteboardType("org.chromium.source-url")

    /// Browsers we can ask for their front tab. Addressed by bundle id so a
    /// renamed or localized app name never breaks the lookup.
    private static let safariIDs: Set<String> = [
        "com.apple.Safari",
        "com.apple.SafariTechnologyPreview",
    ]
    private static let chromiumIDs: Set<String> = [
        "com.google.Chrome",
        "com.google.Chrome.beta",
        "com.google.Chrome.canary",
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser",   // Arc
        "com.vivaldi.Vivaldi",
        "com.operasoftware.Opera",
    ]

    private static let scriptQueue = DispatchQueue(label: "com.peterchiu.clipvault.applescript", qos: .userInitiated)

    static func isBrowser(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return canScript(bundleID: bundleID) || bundleID == "org.mozilla.firefox"
    }

    static func canScript(bundleID: String) -> Bool {
        safariIDs.contains(bundleID) || chromiumIDs.contains(bundleID)
    }

    /// Fast path: Chromium browsers put the page URL on the pasteboard.
    static func pasteboardURL(_ pasteboard: NSPasteboard) -> String? {
        guard let value = pasteboard.string(forType: chromiumSourceURLType), isWebURL(value) else { return nil }
        return value
    }

    /// Slow path: ask the browser via AppleScript, off the main actor.
    static func resolveViaAppleScript(bundleID: String) async -> String? {
        guard let source = script(for: bundleID) else { return nil }
        return await withCheckedContinuation { continuation in
            scriptQueue.async {
                continuation.resume(returning: runAppleScript(source))
            }
        }
    }

    private static func script(for bundleID: String) -> String? {
        let tab: String
        if safariIDs.contains(bundleID) {
            tab = "current tab"
        } else if chromiumIDs.contains(bundleID) {
            tab = "active tab"
        } else {
            return nil
        }
        return "tell application id \"\(bundleID)\" to return URL of \(tab) of front window"
    }

    private static func isWebURL(_ s: String) -> Bool {
        guard let url = URL(string: s), let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private static func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if let error {
            NSLog("ClipVault: AppleScript URL lookup failed: \(error)")
            return nil
        }
        guard let value = result.stringValue, isWebURL(value) else { return nil }
        return value
    }
}

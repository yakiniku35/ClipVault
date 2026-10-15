import AppKit
import Foundation

/// Best-effort detection of the web page a clip was copied from.
///
/// Chromium browsers attach the page URL to the pasteboard directly. For
/// Safari (and as a fallback for the others) we ask the browser for its
/// front tab via AppleScript, which requires the user to grant Automation
/// access the first time.
enum SourceURLResolver {
    static let chromiumSourceURLType = NSPasteboard.PasteboardType("org.chromium.source-url")

    /// Bundle IDs → AppleScript snippet returning the active tab URL.
    private static let scripts: [String: String] = [
        "com.apple.Safari": #"tell application "Safari" to return URL of current tab of front window"#,
        "com.apple.SafariTechnologyPreview": #"tell application "Safari Technology Preview" to return URL of current tab of front window"#,
        "com.google.Chrome": #"tell application "Google Chrome" to return URL of active tab of front window"#,
        "com.google.Chrome.canary": #"tell application "Google Chrome Canary" to return URL of active tab of front window"#,
        "com.brave.Browser": #"tell application "Brave Browser" to return URL of active tab of front window"#,
        "com.microsoft.edgemac": #"tell application "Microsoft Edge" to return URL of active tab of front window"#,
        "company.thebrowser.Browser": #"tell application "Arc" to return URL of active tab of front window"#,
        "com.vivaldi.Vivaldi": #"tell application "Vivaldi" to return URL of active tab of front window"#,
        "com.operasoftware.Opera": #"tell application "Opera" to return URL of active tab of front window"#,
    ]

    static func isBrowser(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return scripts[bundleID] != nil || bundleID == "org.mozilla.firefox"
    }

    static func resolve(pasteboard: NSPasteboard, bundleID: String?) -> String? {
        if let fromPasteboard = pasteboard.string(forType: chromiumSourceURLType),
           isWebURL(fromPasteboard) {
            return fromPasteboard
        }
        guard let bundleID, let source = scripts[bundleID] else { return nil }
        return runAppleScript(source)
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

import Foundation

/// Pure matching logic for "never record copies from these apps / sites".
struct ExclusionRules: Equatable {
    var bundleIDs: Set<String>
    var urlPatterns: [String]

    init(bundleIDs: Set<String> = [], urlPatterns: [String] = []) {
        self.bundleIDs = bundleIDs
        self.urlPatterns = urlPatterns.map(Self.normalize(pattern:)).filter { !$0.isEmpty }
    }

    func isAppExcluded(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return bundleIDs.contains(bundleID)
    }

    func isURLExcluded(_ urlString: String?) -> Bool {
        guard let urlString, !urlString.isEmpty else { return false }
        let lowered = urlString.lowercased()
        let host = URL(string: urlString)?.host?.lowercased()
            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        let hostAndPath = Self.stripScheme(lowered)

        for pattern in urlPatterns {
            if pattern.contains("*") {
                if Self.wildcardMatch(pattern: pattern, text: hostAndPath) { return true }
                if let host, Self.wildcardMatch(pattern: pattern, text: host) { return true }
                continue
            }
            if let host {
                // "bank.com" matches "bank.com" and "online.bank.com"
                if host == pattern || host.hasSuffix("." + pattern) { return true }
            }
            // "mail.google.com/mail" style path prefixes, or arbitrary substrings
            if hostAndPath.hasPrefix(pattern) || hostAndPath.contains(pattern) { return true }
        }
        return false
    }

    func isExcluded(bundleID: String?, url: String?) -> Bool {
        isAppExcluded(bundleID: bundleID) || isURLExcluded(url)
    }

    // MARK: - Helpers

    /// Lower-cases, strips scheme and leading "www.", trims whitespace and trailing slashes.
    static func normalize(pattern: String) -> String {
        var p = pattern.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        p = stripScheme(p)
        if p.hasPrefix("www.") { p.removeFirst(4) }
        while p.hasSuffix("/") { p.removeLast() }
        return p
    }

    static func stripScheme(_ s: String) -> String {
        var out = s
        for scheme in ["https://", "http://"] where out.hasPrefix(scheme) {
            out.removeFirst(scheme.count)
        }
        if out.hasPrefix("www.") { out.removeFirst(4) }
        return out
    }

    static func wildcardMatch(pattern: String, text: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
        guard let regex = try? NSRegularExpression(pattern: "^" + escaped + "$") else { return false }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil
    }
}

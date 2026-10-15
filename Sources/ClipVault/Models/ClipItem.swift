import Foundation

/// A single captured clipboard entry.
struct ClipItem: Identifiable, Codable, Equatable, Hashable {
    /// Clips larger than this are not recorded (keeps memory, JSON and
    /// rendering costs bounded).
    static let maxStoredBytes = 2_000_000

    /// Only this many leading characters are inspected to build `preview`.
    static let previewScanLimit = 1_000

    let id: UUID
    var text: String
    var copiedAt: Date
    var sourceAppName: String
    var sourceBundleID: String?
    var sourceURL: String?
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        text: String,
        copiedAt: Date = Date(),
        sourceAppName: String,
        sourceBundleID: String? = nil,
        sourceURL: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
        self.sourceAppName = sourceAppName
        self.sourceBundleID = sourceBundleID
        self.sourceURL = sourceURL
        self.isPinned = isPinned
    }

    /// Single-line, whitespace-collapsed preview used in list rows.
    /// Only the first `previewScanLimit` characters are tokenised so this stays
    /// cheap for very large clips.
    var preview: String {
        let head = text.prefix(Self.previewScanLimit)
        let collapsed = head
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if collapsed.count > 240 || text.count > Self.previewScanLimit {
            return String(collapsed.prefix(240)) + "…"
        }
        return collapsed
    }

    var characterCount: Int { text.count }

    var lineCount: Int {
        text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
    }

    /// Host portion of `sourceURL`, if any (e.g. "github.com").
    var sourceHost: String? {
        guard let sourceURL, let url = URL(string: sourceURL) else { return nil }
        return url.host
    }

    /// True when the whole clip looks like a single URL.
    var looksLikeURL: Bool { Self.looksLikeURL(text) }

    /// True when `text` as a whole is a single http(s) URL.
    static func looksLikeURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(" "), let url = URL(string: trimmed) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}

// Minimal assertion-based checks that run with only the Command Line Tools
// installed (no XCTest). `make test` compiles the app sources (minus the
// @main entry point) together with this file and runs it.
import Foundation

var failures = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String, file: String = #file, line: Int = #line) {
    if condition() {
        print("  ✓ \(message)")
    } else {
        failures += 1
        print("  ✗ \(message)  (\(file):\(line))")
    }
}

// MARK: ExclusionRules
print("ExclusionRules")
do {
    let apps = ExclusionRules(bundleIDs: ["com.agilebits.onepassword7"])
    check(apps.isAppExcluded(bundleID: "com.agilebits.onepassword7"), "excluded bundle id matches")
    check(!apps.isAppExcluded(bundleID: "com.apple.Safari"), "other bundle id does not match")
    check(!apps.isAppExcluded(bundleID: nil), "nil bundle id is not excluded")

    let host = ExclusionRules(urlPatterns: ["bank.com"])
    check(host.isURLExcluded("https://bank.com/login"), "exact host matches")
    check(host.isURLExcluded("https://online.bank.com/"), "subdomain matches")
    check(host.isURLExcluded("http://www.bank.com"), "www. prefix matches")
    check(!host.isURLExcluded("https://notbank.com"), "suffix without dot does not match")
    check(!host.isURLExcluded("https://example.com/bank.com"), "host in path does not match")

    let path = ExclusionRules(urlPatterns: ["https://mail.google.com/mail"])
    check(path.isURLExcluded("https://mail.google.com/mail/u/0/#inbox"), "path prefix matches")
    check(!path.isURLExcluded("https://docs.google.com/"), "other google host does not match")

    let wild = ExclusionRules(urlPatterns: ["*.internal.corp*"])
    check(wild.isURLExcluded("https://wiki.internal.corp/page"), "wildcard matches")
    check(!wild.isURLExcluded("https://internal.corp.example.com"), "wildcard anchored")

    check(ExclusionRules.normalize(pattern: "  HTTPS://WWW.Example.com/ ") == "example.com", "normalize strips scheme/www/slash")
    check(!host.isURLExcluded(nil) && !host.isURLExcluded(""), "nil/empty URL never excluded")
}

// MARK: Retention pruning
print("HistoryStore.pruned")
do {
    let now = Date()
    func item(_ text: String, age: TimeInterval, pinned: Bool = false) -> ClipItem {
        ClipItem(text: text, copiedAt: now.addingTimeInterval(-age), sourceAppName: "Test", isPinned: pinned)
    }
    let expired = HistoryStore.pruned([item("fresh", age: 60), item("old", age: 7200)], policy: .oneHour, maxItems: 100, now: now)
    check(expired.map(\.text) == ["fresh"], "expired unpinned items dropped")

    let pinned = HistoryStore.pruned([item("keep", age: 10 * 86400, pinned: true)], policy: .oneDay, maxItems: 100, now: now)
    check(pinned.count == 1, "pinned items survive expiry")

    let forever = HistoryStore.pruned([item("ancient", age: 365 * 86400)], policy: .forever, maxItems: 100, now: now)
    check(forever.count == 1, "forever never expires")

    let capped = HistoryStore.pruned((0..<5).map { item("\($0)", age: Double($0)) }, policy: .forever, maxItems: 3, now: now)
    check(capped.map(\.text) == ["0", "1", "2"], "max items keeps newest")

    var mixed = (0..<4).map { item("\($0)", age: Double($0)) }
    mixed.insert(item("pinned", age: 100, pinned: true), at: 0)
    let cappedPinned = HistoryStore.pruned(mixed, policy: .forever, maxItems: 2, now: now)
    check(cappedPinned.map(\.text) == ["pinned", "0", "1"], "cap ignores pinned")
}

// MARK: ClipItem helpers
print("ClipItem")
do {
    check(ClipItem(text: "  hello\n\n  world\t!  ", sourceAppName: "T").preview == "hello world !", "preview collapses whitespace")
    check(ClipItem(text: "https://example.com/a?b=1", sourceAppName: "T").looksLikeURL, "single URL detected")
    check(!ClipItem(text: "visit https://example.com now", sourceAppName: "T").looksLikeURL, "sentence is not a URL")
    check(ClipItem(text: "x", sourceAppName: "T", sourceURL: "https://www.github.com/a").sourceHost == "www.github.com", "sourceHost parsed")
    check(RetentionPolicy.oneHour.expiryDate(now: Date(timeIntervalSince1970: 7200)) == Date(timeIntervalSince1970: 3600), "expiry date arithmetic")
    check(RetentionPolicy.forever.expiryDate() == nil, "forever has no expiry")
}

print(failures == 0 ? "\nAll checks passed." : "\n\(failures) check(s) FAILED.")
exit(failures == 0 ? 0 : 1)

import XCTest
@testable import ClipVault

final class HistoryPruningTests: XCTestCase {
    private func item(_ text: String, ageSeconds: TimeInterval, pinned: Bool = false, now: Date) -> ClipItem {
        ClipItem(text: text, copiedAt: now.addingTimeInterval(-ageSeconds), sourceAppName: "Test", isPinned: pinned)
    }

    func testExpiredUnpinnedItemsAreDropped() {
        let now = Date()
        let items = [
            item("fresh", ageSeconds: 60, now: now),
            item("old", ageSeconds: 2 * 60 * 60, now: now),
        ]
        let result = HistoryStore.pruned(items, policy: .oneHour, maxItems: 100, now: now)
        XCTAssertEqual(result.map(\.text), ["fresh"])
    }

    func testPinnedItemsSurviveExpiry() {
        let now = Date()
        let items = [item("keep me", ageSeconds: 10 * 24 * 3600, pinned: true, now: now)]
        let result = HistoryStore.pruned(items, policy: .oneDay, maxItems: 100, now: now)
        XCTAssertEqual(result.count, 1)
    }

    func testForeverNeverExpires() {
        let now = Date()
        let items = [item("ancient", ageSeconds: 365 * 24 * 3600, now: now)]
        let result = HistoryStore.pruned(items, policy: .forever, maxItems: 100, now: now)
        XCTAssertEqual(result.count, 1)
    }

    func testMaxItemsCapKeepsNewestUnpinned() {
        let now = Date()
        let items = (0..<5).map { item("\($0)", ageSeconds: Double($0), now: now) }
        let result = HistoryStore.pruned(items, policy: .forever, maxItems: 3, now: now)
        XCTAssertEqual(result.map(\.text), ["0", "1", "2"])
    }

    func testMaxItemsCapIgnoresPinned() {
        let now = Date()
        var items = (0..<4).map { item("\($0)", ageSeconds: Double($0), now: now) }
        items.insert(item("pinned", ageSeconds: 100, pinned: true, now: now), at: 0)
        let result = HistoryStore.pruned(items, policy: .forever, maxItems: 2, now: now)
        XCTAssertEqual(result.map(\.text), ["pinned", "0", "1"])
    }

    func testPreviewCollapsesWhitespace() {
        let clip = ClipItem(text: "  hello\n\n  world\t!  ", sourceAppName: "Test")
        XCTAssertEqual(clip.preview, "hello world !")
    }

    func testLooksLikeURL() {
        XCTAssertTrue(ClipItem(text: "https://example.com/a?b=1", sourceAppName: "T").looksLikeURL)
        XCTAssertFalse(ClipItem(text: "visit https://example.com now", sourceAppName: "T").looksLikeURL)
        XCTAssertFalse(ClipItem(text: "hello", sourceAppName: "T").looksLikeURL)
    }
}

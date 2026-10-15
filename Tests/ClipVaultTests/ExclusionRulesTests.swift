import XCTest
@testable import ClipVault

final class ExclusionRulesTests: XCTestCase {
    func testBundleIDExclusion() {
        let rules = ExclusionRules(bundleIDs: ["com.agilebits.onepassword7"])
        XCTAssertTrue(rules.isAppExcluded(bundleID: "com.agilebits.onepassword7"))
        XCTAssertFalse(rules.isAppExcluded(bundleID: "com.apple.Safari"))
        XCTAssertFalse(rules.isAppExcluded(bundleID: nil))
    }

    func testHostSuffixMatching() {
        let rules = ExclusionRules(urlPatterns: ["bank.com"])
        XCTAssertTrue(rules.isURLExcluded("https://bank.com/login"))
        XCTAssertTrue(rules.isURLExcluded("https://online.bank.com/"))
        XCTAssertTrue(rules.isURLExcluded("http://www.bank.com"))
        XCTAssertFalse(rules.isURLExcluded("https://notbank.com"))
        XCTAssertFalse(rules.isURLExcluded("https://example.com/bank.com"))
    }

    func testPathPrefixMatching() {
        let rules = ExclusionRules(urlPatterns: ["https://mail.google.com/mail"])
        XCTAssertTrue(rules.isURLExcluded("https://mail.google.com/mail/u/0/#inbox"))
        XCTAssertFalse(rules.isURLExcluded("https://docs.google.com/"))
    }

    func testWildcardMatching() {
        let rules = ExclusionRules(urlPatterns: ["*.internal.corp*"])
        XCTAssertTrue(rules.isURLExcluded("https://wiki.internal.corp/page"))
        XCTAssertFalse(rules.isURLExcluded("https://internal.corp.example.com"))
    }

    func testNormalization() {
        XCTAssertEqual(ExclusionRules.normalize(pattern: "  HTTPS://WWW.Example.com/ "), "example.com")
        XCTAssertEqual(ExclusionRules.normalize(pattern: "example.com/path/"), "example.com/path")
    }

    func testNilAndEmptyURLsAreNeverExcluded() {
        let rules = ExclusionRules(urlPatterns: ["example.com"])
        XCTAssertFalse(rules.isURLExcluded(nil))
        XCTAssertFalse(rules.isURLExcluded(""))
    }
}

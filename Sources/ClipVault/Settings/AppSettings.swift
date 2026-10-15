import Foundation
import Combine
import ServiceManagement

/// User preferences, persisted in UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let retention = "retention"
        static let maxItems = "maxItems"
        static let excludedBundleIDs = "excludedBundleIDs"
        static let excludedURLPatterns = "excludedURLPatterns"
        static let ignoreConcealed = "ignoreConcealed"
        static let captureURLs = "captureURLs"
        static let pollInterval = "pollInterval"
    }

    private let defaults: UserDefaults

    @Published var retention: RetentionPolicy {
        didSet { defaults.set(retention.rawValue, forKey: Key.retention) }
    }

    /// Hard cap on stored (unpinned) items regardless of age.
    @Published var maxItems: Int {
        didSet { defaults.set(maxItems, forKey: Key.maxItems) }
    }

    /// Bundle identifiers of apps whose copies are never recorded.
    @Published var excludedBundleIDs: [String] {
        didSet { defaults.set(excludedBundleIDs, forKey: Key.excludedBundleIDs) }
    }

    /// URL patterns (host suffixes or substrings) whose copies are never recorded.
    @Published var excludedURLPatterns: [String] {
        didSet { defaults.set(excludedURLPatterns, forKey: Key.excludedURLPatterns) }
    }

    /// Skip clips flagged by password managers as concealed/transient.
    @Published var ignoreConcealed: Bool {
        didSet { defaults.set(ignoreConcealed, forKey: Key.ignoreConcealed) }
    }

    /// Try to detect the web page URL when copying from a browser.
    @Published var captureURLs: Bool {
        didSet { defaults.set(captureURLs, forKey: Key.captureURLs) }
    }

    /// Seconds between pasteboard checks.
    @Published var pollInterval: Double {
        didSet { defaults.set(pollInterval, forKey: Key.pollInterval) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard !isSyncingLaunchAtLogin, launchAtLogin != oldValue else { return }
            applyLaunchAtLogin(launchAtLogin)
        }
    }
    private var isSyncingLaunchAtLogin = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        retention = RetentionPolicy(rawValue: defaults.string(forKey: Key.retention) ?? "") ?? .oneWeek
        let storedMax = defaults.integer(forKey: Key.maxItems)
        maxItems = storedMax > 0 ? storedMax : 500
        excludedBundleIDs = defaults.stringArray(forKey: Key.excludedBundleIDs) ?? []
        excludedURLPatterns = defaults.stringArray(forKey: Key.excludedURLPatterns) ?? []
        ignoreConcealed = defaults.object(forKey: Key.ignoreConcealed) as? Bool ?? true
        captureURLs = defaults.object(forKey: Key.captureURLs) as? Bool ?? true
        let storedPoll = defaults.double(forKey: Key.pollInterval)
        pollInterval = storedPoll > 0 ? storedPoll : 0.5
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    var exclusionRules: ExclusionRules {
        ExclusionRules(bundleIDs: Set(excludedBundleIDs), urlPatterns: excludedURLPatterns)
    }

    // MARK: - Mutations

    func addExcludedBundleID(_ id: String) {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !excludedBundleIDs.contains(trimmed) else { return }
        excludedBundleIDs.append(trimmed)
    }

    func removeExcludedBundleID(_ id: String) {
        excludedBundleIDs.removeAll { $0 == id }
    }

    func addExcludedURLPattern(_ pattern: String) {
        let normalized = ExclusionRules.normalize(pattern: pattern)
        guard !normalized.isEmpty, !excludedURLPatterns.contains(normalized) else { return }
        excludedURLPatterns.append(normalized)
    }

    func removeExcludedURLPattern(_ pattern: String) {
        excludedURLPatterns.removeAll { $0 == pattern }
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("ClipVault: launch-at-login change failed: \(error.localizedDescription)")
            // Keep the toggle truthful: fall back to what the system reports.
            isSyncingLaunchAtLogin = true
            launchAtLogin = SMAppService.mainApp.status == .enabled
            isSyncingLaunchAtLogin = false
        }
    }
}

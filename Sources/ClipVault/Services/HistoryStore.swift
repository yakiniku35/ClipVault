import AppKit
import Combine
import Foundation

/// In-memory history backed by a JSON file in Application Support.
@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []

    private let settings: AppSettings
    private let fileURL: URL
    private var cancellables = Set<AnyCancellable>()
    private var pruneTimer: Timer?
    private var saveWorkItem: DispatchWorkItem?

    init(settings: AppSettings, fileURL: URL? = nil) {
        self.settings = settings
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
        prune()

        // @Published emits during willSet, so use the delivered values rather
        // than re-reading `settings`, which still holds the old ones.
        settings.$retention
            .combineLatest(settings.$maxItems)
            .dropFirst()
            .sink { [weak self] retention, maxItems in
                self?.prune(policy: retention, maxItems: maxItems)
            }
            .store(in: &cancellables)

        let t = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.prune() }
        }
        RunLoop.main.add(t, forMode: .common)
        pruneTimer = t
    }

    // MARK: - Queries

    var pinnedItems: [ClipItem] { items.filter(\.isPinned) }
    var unpinnedItems: [ClipItem] { items.filter { !$0.isPinned } }

    func search(_ query: String) -> [ClipItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter {
            $0.text.localizedCaseInsensitiveContains(q)
                || $0.sourceAppName.localizedCaseInsensitiveContains(q)
                || ($0.sourceURL?.localizedCaseInsensitiveContains(q) ?? false)
        }
    }

    // MARK: - Mutations

    /// Insert a freshly captured clip at the top, replacing an identical older clip.
    func add(_ item: ClipItem) {
        var newItem = item
        if let existingIndex = items.firstIndex(where: { $0.text == item.text }) {
            // Keep the pin state of the older duplicate.
            newItem.isPinned = items[existingIndex].isPinned
            items.remove(at: existingIndex)
        }
        items.insert(newItem, at: 0)
        enforceLimit()
        scheduleSave()
    }

    func remove(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        scheduleSave()
    }

    func togglePin(_ item: ClipItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        scheduleSave()
    }

    func clear(keepPinned: Bool = true) {
        items = keepPinned ? items.filter(\.isPinned) : []
        scheduleSave()
    }

    /// Write the clip back to the system pasteboard and move it to the top.
    func copyToPasteboard(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
        pb.setString("1", forType: ClipboardMonitor.internalMarkerType)

        var refreshed = item
        refreshed.copiedAt = Date()
        add(refreshed)
    }

    /// Drop unpinned items that are older than the retention policy allows.
    func prune(now: Date = Date()) {
        prune(policy: settings.retention, maxItems: settings.maxItems, now: now)
    }

    func prune(policy: RetentionPolicy, maxItems: Int, now: Date = Date()) {
        let before = items.count
        items = Self.pruned(items, policy: policy, maxItems: maxItems, now: now)
        if items.count != before { scheduleSave() }
    }

    /// Pure pruning logic, exposed for tests.
    nonisolated static func pruned(_ items: [ClipItem], policy: RetentionPolicy, maxItems: Int, now: Date) -> [ClipItem] {
        var result = items
        if let cutoff = policy.expiryDate(now: now) {
            result.removeAll { !$0.isPinned && $0.copiedAt < cutoff }
        }
        // Enforce the hard cap on unpinned items, oldest first.
        var unpinnedSeen = 0
        result = result.filter { item in
            if item.isPinned { return true }
            unpinnedSeen += 1
            return unpinnedSeen <= maxItems
        }
        return result
    }

    private func enforceLimit() {
        items = Self.pruned(items, policy: .forever, maxItems: settings.maxItems, now: Date())
    }

    // MARK: - Persistence

    static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("ClipVault", isDirectory: true)
        // Clipboard history is sensitive: keep the directory private to this user.
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        return dir.appendingPathComponent("history.json")
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([ClipItem].self, from: data)
        } catch {
            // Never overwrite a file we could not read: move it aside so the
            // user can recover it, then start fresh.
            let backup = fileURL.deletingPathExtension().appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            NSLog("ClipVault: could not read history (%@); moved it to %@", error.localizedDescription, backup.lastPathComponent)
        }
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in self?.saveNow() }
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func saveNow() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            NSLog("ClipVault: failed to save history: \(error.localizedDescription)")
        }
    }
}

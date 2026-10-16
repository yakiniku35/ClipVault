import AppKit
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: HistoryStore
    @EnvironmentObject private var monitor: ClipboardMonitor
    @EnvironmentObject private var settings: AppSettings

    @State private var query = ""
    @State private var now = Date()
    @State private var copiedID: UUID?
    @State private var pendingClear: ClearMode?

    /// Which clear action is waiting for confirmation. Confirmation is an
    /// inline banner rather than a sheet/alert: sheets presented inside a
    /// MenuBarExtra window do not reliably run their button actions.
    private enum ClearMode {
        case unpinned, all

        var question: String {
            switch self {
            case .unpinned: return "清除所有未釘選的紀錄？"
            case .all: return "清除全部紀錄（包含釘選）？"
            }
        }

        var confirmTitle: String {
            switch self {
            case .unpinned: return "清除未釘選"
            case .all: return "清除全部"
            }
        }
    }

    private let clock = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private struct Sections {
        var pinned: [ClipItem] = []
        var recent: [ClipItem] = []
        var isEmpty: Bool { pinned.isEmpty && recent.isEmpty }
    }

    /// Runs the search once per render and splits the result by pin state.
    private func sections() -> Sections {
        var result = Sections()
        for item in store.search(query) {
            if item.isPinned { result.pinned.append(item) } else { result.recent.append(item) }
        }
        return result
    }

    var body: some View {
        let sections = sections()
        VStack(spacing: 0) {
            header
            Divider()
            if let mode = pendingClear {
                clearBanner(mode)
                Divider()
            }
            if sections.isEmpty {
                emptyState
            } else {
                list(sections)
            }
            Divider()
            footer
        }
        .frame(width: 400, height: 520)
        .onReceive(clock) { now = $0 }
        .onAppear { now = Date() }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜尋文字、App 或網址", text: $query)
                .textFieldStyle(.plain)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button {
                monitor.isPaused.toggle()
            } label: {
                Image(systemName: monitor.isPaused ? "play.circle" : "pause.circle")
                    .foregroundColor(monitor.isPaused ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .help(monitor.isPaused ? "恢復記錄" : "暫停記錄")

            Menu {
                settingsButton
                Divider()
                Button("清除未釘選的紀錄…") { pendingClear = .unpinned }
                Button("清除全部紀錄…", role: .destructive) { pendingClear = .all }
                Divider()
                Button("結束 ClipVault") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle").foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 22)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func clearBanner(_ mode: ClearMode) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(mode.question)
                .font(.system(size: 12))
            Spacer()
            Button("取消") { pendingClear = nil }
                .keyboardShortcut(.cancelAction)
            Button(mode.confirmTitle) {
                store.clear(keepPinned: mode == .unpinned)
                pendingClear = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.12))
    }

    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 14, *) {
            SettingsLink { Text("設定…") }
                .simultaneousGesture(TapGesture().onEnded { NSApp.activate(ignoringOtherApps: true) })
        } else {
            Button("設定…") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
    }

    private func list(_ sections: Sections) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                if !sections.pinned.isEmpty {
                    sectionTitle("已釘選")
                    ForEach(sections.pinned) { row($0) }
                }
                if !sections.recent.isEmpty {
                    sectionTitle(sections.pinned.isEmpty ? "歷史紀錄" : "最近")
                    ForEach(sections.recent) { row($0) }
                }
            }
            .padding(6)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private func row(_ item: ClipItem) -> some View {
        ClipRowView(item: item, now: now, isHighlighted: copiedID == item.id)
            .onTapGesture { copy(item) }
            .contextMenu {
                Button("複製") { copy(item) }
                Button(item.isPinned ? "取消釘選" : "釘選") { store.togglePin(item) }
                if let urlString = item.sourceURL, let url = URL(string: urlString) {
                    Button("開啟來源網頁") { NSWorkspace.shared.open(url) }
                }
                if item.looksLikeURL, let url = URL(string: item.text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    Button("在瀏覽器開啟") { NSWorkspace.shared.open(url) }
                }
                if let bundleID = item.sourceBundleID {
                    Button("之後不記錄「\(item.sourceAppName)」") { settings.addExcludedBundleID(bundleID) }
                }
                if let host = item.sourceHost {
                    Button("之後不記錄「\(host)」") { settings.addExcludedURLPattern(host) }
                }
                Divider()
                Button("刪除", role: .destructive) { store.remove(item) }
            }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: query.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(query.isEmpty ? "還沒有任何剪貼紀錄\n複製一段文字試試看" : "找不到符合「\(query)」的紀錄")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if monitor.isPaused {
                Image(systemName: "pause.fill").foregroundColor(.orange)
                Text("已暫停記錄")
            } else {
                Text("\(store.items.count) 筆")
                Text("·")
                Text("保留 \(settings.retention.title)")
            }
            Spacer()
            if let reason = monitor.lastSkipReason {
                Text("略過：\(reason)")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .font(.system(size: 10.5))
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    // MARK: - Actions

    private func copy(_ item: ClipItem) {
        store.copyToPasteboard(item)
        copiedID = item.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if copiedID == item.id { copiedID = nil }
        }
    }
}

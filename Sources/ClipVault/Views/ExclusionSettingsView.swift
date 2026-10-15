import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ExclusionSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var newPattern = ""
    @State private var selectedApp: String?
    @State private var selectedPattern: String?

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .filter { $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            appsSection
            urlsSection
        }
        .padding(16)
    }

    // MARK: - Apps

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("不記錄這些 App 的複製內容").font(.headline)
            List(selection: $selectedApp) {
                ForEach(settings.excludedBundleIDs, id: \.self) { id in
                    HStack(spacing: 8) {
                        Image(nsImage: AppIconProvider.icon(forBundleID: id))
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text(AppIconProvider.name(forBundleID: id))
                        Text(id).font(.caption).foregroundColor(.secondary)
                    }
                    .tag(id)
                }
            }
            .frame(minHeight: 90)
            .overlay {
                if settings.excludedBundleIDs.isEmpty {
                    Text("尚未排除任何 App").foregroundColor(.secondary).font(.caption)
                }
            }
            HStack {
                Menu("加入執行中的 App") {
                    ForEach(runningApps, id: \.bundleIdentifier) { app in
                        Button {
                            if let id = app.bundleIdentifier { settings.addExcludedBundleID(id) }
                        } label: {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                            }
                            Text(app.localizedName ?? app.bundleIdentifier ?? "")
                        }
                    }
                }
                .frame(width: 160)
                Button("從 Applications 選擇…", action: chooseApp)
                Spacer()
                Button {
                    if let selectedApp { settings.removeExcludedBundleID(selectedApp) }
                    selectedApp = nil
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selectedApp == nil)
            }
        }
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "排除"
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            if let id = Bundle(url: url)?.bundleIdentifier {
                settings.addExcludedBundleID(id)
            }
        }
    }

    // MARK: - URLs

    private var urlsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("在這些網址複製時不記錄").font(.headline)
            List(selection: $selectedPattern) {
                ForEach(settings.excludedURLPatterns, id: \.self) { pattern in
                    HStack(spacing: 6) {
                        Image(systemName: "globe").foregroundColor(.secondary)
                        Text(pattern)
                    }
                    .tag(pattern)
                }
            }
            .frame(minHeight: 90)
            .overlay {
                if settings.excludedURLPatterns.isEmpty {
                    Text("尚未排除任何網址").foregroundColor(.secondary).font(.caption)
                }
            }
            HStack {
                TextField("例如 bank.com、mail.google.com/mail、*.internal.corp", text: $newPattern)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addPattern)
                Button("加入", action: addPattern)
                    .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)
                Button {
                    if let selectedPattern { settings.removeExcludedURLPattern(selectedPattern) }
                    selectedPattern = nil
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(selectedPattern == nil)
            }
            Text("輸入網域會同時涵蓋其子網域；可用 * 當萬用字元。網址偵測需開啟「記錄來源網址」並允許 Automation 權限。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func addPattern() {
        settings.addExcludedURLPattern(newPattern)
        newPattern = ""
    }
}

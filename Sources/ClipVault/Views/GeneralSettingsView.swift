import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: HistoryStore
    @State private var showClearConfirm = false

    var body: some View {
        Form {
            Section("保留期限") {
                Picker("自動刪除超過以下時間的紀錄", selection: $settings.retention) {
                    ForEach(RetentionPolicy.allCases) { policy in
                        Text(policy.title).tag(policy)
                    }
                }
                Text("釘選的項目不受期限與數量上限影響。")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Stepper(value: $settings.maxItems, in: 20...5000, step: 20) {
                    HStack {
                        Text("最多保留筆數")
                        Spacer()
                        Text("\(settings.maxItems)").foregroundColor(.secondary)
                    }
                }
            }

            Section("記錄行為") {
                Toggle("略過密碼管理器標記為機密的內容", isOn: $settings.ignoreConcealed)
                Toggle("從瀏覽器複製時記錄來源網址", isOn: $settings.captureURLs)
                Text("第一次使用時 macOS 會詢問是否允許 ClipVault 控制 Safari / Chrome 以讀取目前分頁網址。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("偵測頻率", selection: $settings.pollInterval) {
                    Text("0.25 秒").tag(0.25)
                    Text("0.5 秒").tag(0.5)
                    Text("1 秒").tag(1.0)
                }
            }

            Section("系統") {
                Toggle("登入時自動啟動", isOn: $settings.launchAtLogin)
                HStack {
                    Text("目前共 \(store.items.count) 筆紀錄")
                    Spacer()
                    Button("清除全部…", role: .destructive) { showClearConfirm = true }
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("確定要刪除所有剪貼紀錄（包含釘選）嗎？", isPresented: $showClearConfirm) {
            Button("刪除全部", role: .destructive) { store.clear(keepPinned: false) }
        }
    }
}

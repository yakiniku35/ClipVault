import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("ClipVault").font(.title2).bold()
            Text("版本 \(version)").foregroundColor(.secondary)
            Text("輕量的 macOS 選單列剪貼簿歷史工具。\n所有紀錄只存在本機，不會上傳任何資料。")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundColor(.secondary)
            Divider().padding(.horizontal, 60)
            VStack(alignment: .leading, spacing: 4) {
                Label("點一下項目即複製回剪貼簿", systemImage: "cursorarrow.click")
                Label("右鍵可釘選、刪除、開啟來源網頁或快速排除", systemImage: "contextualmenu.and.cursorarrow")
                Label("滑鼠停留可看完整複製時間", systemImage: "clock")
            }
            .font(.callout)
            .foregroundColor(.secondary)
            Spacer()
        }
        .padding(24)
    }
}

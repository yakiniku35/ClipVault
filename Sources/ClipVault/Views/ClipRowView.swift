import SwiftUI

struct ClipRowView: View {
    let item: ClipItem
    let now: Date
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(nsImage: AppIconProvider.icon(forBundleID: item.sourceBundleID))
                .resizable()
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.preview)
                    .font(.system(size: 12.5))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text(item.sourceAppName)
                        .fontWeight(.medium)
                    Text("·")
                    Text(DateFormatting.relativeString(item.copiedAt, now: now))
                    if let host = item.sourceHost {
                        Text("·")
                        Image(systemName: "globe")
                            .font(.system(size: 9))
                        Text(host)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: 0)
                    Text("\(item.characterCount) 字")
                }
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
            }

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHighlighted ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .contentShape(Rectangle())
        .help(tooltip)
    }

    private var tooltip: String {
        var lines = [
            "複製時間：\(DateFormatting.absolute.string(from: item.copiedAt))",
            "來源 App：\(item.sourceAppName)",
        ]
        if let url = item.sourceURL { lines.append("來源網址：\(url)") }
        lines.append("\(item.characterCount) 字、\(item.lineCount) 行")
        return lines.joined(separator: "\n")
    }
}

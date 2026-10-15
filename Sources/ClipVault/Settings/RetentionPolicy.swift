import Foundation

/// How long an unpinned clip is kept before it is automatically removed.
enum RetentionPolicy: String, CaseIterable, Identifiable, Codable {
    case fifteenMinutes
    case oneHour
    case sixHours
    case oneDay
    case threeDays
    case oneWeek
    case oneMonth
    case forever

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fifteenMinutes: return "15 分鐘"
        case .oneHour: return "1 小時"
        case .sixHours: return "6 小時"
        case .oneDay: return "1 天"
        case .threeDays: return "3 天"
        case .oneWeek: return "7 天"
        case .oneMonth: return "30 天"
        case .forever: return "永久保留"
        }
    }

    /// `nil` means never expire.
    var duration: TimeInterval? {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .oneHour: return 60 * 60
        case .sixHours: return 6 * 60 * 60
        case .oneDay: return 24 * 60 * 60
        case .threeDays: return 3 * 24 * 60 * 60
        case .oneWeek: return 7 * 24 * 60 * 60
        case .oneMonth: return 30 * 24 * 60 * 60
        case .forever: return nil
        }
    }

    /// Cut-off date: clips copied before this should be dropped.
    func expiryDate(now: Date = Date()) -> Date? {
        guard let duration else { return nil }
        return now.addingTimeInterval(-duration)
    }
}

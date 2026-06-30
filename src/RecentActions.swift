import Foundation

enum RecentActionKind: String, Codable {
    case skipped
    case unminimized
    case reopened
    case cmdN
    case failed
}

struct RecentActionRecord: Codable {
    let date: Date
    let appName: String
    let bundleIdentifier: String
    let action: RecentActionKind
    let result: String
}

let applicationSupportDirectoryPath: String = {
    "\(NSHomeDirectory())/Library/Application Support/\(appName)"
}()

let recentActionsPath: String = {
    "\(applicationSupportDirectoryPath)/recent-actions.json"
}()

private let recentActionsDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

private let recentActionsEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

func recentActionRecords() -> [RecentActionRecord] {
    let url = URL(fileURLWithPath: recentActionsPath)
    guard let data = try? Data(contentsOf: url) else { return [] }
    let records = (try? recentActionsDecoder.decode([RecentActionRecord].self, from: data)) ?? []
    return records.filter { $0.action != .skipped }
}

func appendRecentAction(
    appName: String?,
    bundleIdentifier: String?,
    action: RecentActionKind,
    result: String
) {
    let record = RecentActionRecord(
        date: Date(),
        appName: appName ?? "Unknown",
        bundleIdentifier: bundleIdentifier ?? "unknown",
        action: action,
        result: result
    )

    let records = Array(([record] + recentActionRecords()).prefix(10))
    let url = URL(fileURLWithPath: recentActionsPath)
    do {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try recentActionsEncoder.encode(records).write(to: url, options: .atomic)
    } catch {
        debugLogAgent("failed to write recent action: \(error.localizedDescription)")
    }
}

func clearRecentActionRecords() {
    let url = URL(fileURLWithPath: recentActionsPath)
    try? FileManager.default.removeItem(at: url)
}

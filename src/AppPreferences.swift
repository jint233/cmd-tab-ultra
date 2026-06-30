import Foundation

let defaultExcludedBundleIDs: Set<String> = [
    "com.apple.systemuiserver"
]

private let restoreMinimizedWindowsDefaultsKey = "restoreMinimizedWindows"
private let reopenAppsWithoutWindowsDefaultsKey = "reopenAppsWithoutWindows"
private let useCommandNFallbackDefaultsKey = "useCommandNFallback"
private let excludedBundleIDsDefaultsKey = "excludedBundleIDs"

struct RestorePolicy {
    let restoreMinimizedWindows: Bool
    let reopenAppsWithoutWindows: Bool
    let useCommandNFallback: Bool
}

enum AppPreferences {
    static var restorePolicy: RestorePolicy {
        RestorePolicy(
            restoreMinimizedWindows: boolDefault(
                restoreMinimizedWindowsDefaultsKey, defaultValue: true),
            reopenAppsWithoutWindows: boolDefault(
                reopenAppsWithoutWindowsDefaultsKey, defaultValue: true),
            useCommandNFallback: boolDefault(useCommandNFallbackDefaultsKey, defaultValue: true)
        )
    }

    static var excludedBundleIDs: Set<String> {
        get {
            let saved =
                UserDefaults.standard.stringArray(forKey: excludedBundleIDsDefaultsKey) ?? []
            return defaultExcludedBundleIDs.union(saved)
        }
        set {
            let userBundleIDs = newValue.subtracting(defaultExcludedBundleIDs).sorted()
            UserDefaults.standard.set(userBundleIDs, forKey: excludedBundleIDsDefaultsKey)
            }
    }

    static func setRestoreMinimizedWindows(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: restoreMinimizedWindowsDefaultsKey)
    }

    static func setReopenAppsWithoutWindows(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: reopenAppsWithoutWindowsDefaultsKey)
    }

    static func setUseCommandNFallback(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: useCommandNFallbackDefaultsKey)
    }

    static func addExcludedBundleID(_ bundleID: String) {
        let normalized = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        var bundleIDs = excludedBundleIDs
        bundleIDs.insert(normalized)
        excludedBundleIDs = bundleIDs
    }

    static func removeExcludedBundleID(_ bundleID: String) {
        guard !defaultExcludedBundleIDs.contains(bundleID) else { return }
        var bundleIDs = excludedBundleIDs
        bundleIDs.remove(bundleID)
        excludedBundleIDs = bundleIDs
    }

    static func isBundleExcluded(_ bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return excludedBundleIDs.contains(bundleID)
    }

    private static func boolDefault(_ key: String, defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
        return UserDefaults.standard.bool(forKey: key)
    }
}

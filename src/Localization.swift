import Foundation

enum ControlPanelLanguage: String, CaseIterable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var localizationIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .simplifiedChinese, .english:
            return rawValue
        }
    }
}

private let controlPanelLanguageDefaultsKey = "controlPanelLanguage"

private var cachedLocalizationBundle: Bundle?
private var cachedLocalizationLanguage: ControlPanelLanguage?

var selectedControlPanelLanguage: ControlPanelLanguage {
    get {
        let rawValue = UserDefaults.standard.string(forKey: controlPanelLanguageDefaultsKey)
        return rawValue.flatMap(ControlPanelLanguage.init(rawValue:)) ?? .system
    }
    set {
        UserDefaults.standard.set(newValue.rawValue, forKey: controlPanelLanguageDefaultsKey)
        // Invalidate cached bundle when language changes.
        cachedLocalizationBundle = nil
        cachedLocalizationLanguage = nil
    }
}

func localized(_ key: String) -> String {
    let language = selectedControlPanelLanguage
    if language != cachedLocalizationLanguage {
        cachedLocalizationLanguage = language
        if let identifier = language.localizationIdentifier,
            let path = Bundle.main.path(forResource: identifier, ofType: "lproj")
        {
            cachedLocalizationBundle = Bundle(path: path)
        } else {
            cachedLocalizationBundle = nil
        }
    }
    let bundle = cachedLocalizationBundle ?? .main
    return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
}

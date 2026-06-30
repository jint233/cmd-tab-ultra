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

let controlPanelLanguageDefaultsKey = "controlPanelLanguage"

var selectedControlPanelLanguage: ControlPanelLanguage {
    get {
        let rawValue = UserDefaults.standard.string(forKey: controlPanelLanguageDefaultsKey)
        return rawValue.flatMap(ControlPanelLanguage.init(rawValue:)) ?? .system
    }
    set {
        UserDefaults.standard.set(newValue.rawValue, forKey: controlPanelLanguageDefaultsKey)
    }
}

func localized(_ key: String) -> String {
    guard
        let identifier = selectedControlPanelLanguage.localizationIdentifier,
        let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
        let bundle = Bundle(path: path)
    else {
        return NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }

    return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
}

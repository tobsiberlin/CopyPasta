import Foundation
import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var barHeight: CGFloat {
        didSet { UserDefaults.standard.set(barHeight, forKey: "barHeight") }
    }
    
    @Published var screenshotSize: CGFloat {
        didSet { 
            UserDefaults.standard.set(screenshotSize, forKey: "screenshotSize")
            // Bar-Höhe basierend auf Screenshot-Größe anpassen
            barHeight = screenshotSize + 100 // 100px für Top-Bar + Padding + Dateityp-Label
        }
    }
    
    @Published var maxItems: Int {
        didSet { UserDefaults.standard.set(maxItems, forKey: "maxItems") }
    }
    
    @Published var autoShowOnCopy: Bool {
        didSet { UserDefaults.standard.set(autoShowOnCopy, forKey: "autoShowOnCopy") }
    }
    
    @Published var barOpacity: Double {
        didSet { UserDefaults.standard.set(barOpacity, forKey: "barOpacity") }
    }
    
    // Umgekehrte Transparenz für UI (100 = transparent, 0 = opak)
    var transparencyPercentage: Double {
        get { (1.0 - barOpacity) * 100 }
        set { barOpacity = 1.0 - (newValue / 100.0) }
    }
    
    @Published var itemSpacing: CGFloat {
        didSet { UserDefaults.standard.set(itemSpacing, forKey: "itemSpacing") }
    }
    
    @Published var cornerRadius: CGFloat {
        didSet { UserDefaults.standard.set(cornerRadius, forKey: "cornerRadius") }
    }
    
    @Published var hideDelay: Double {
        didSet { UserDefaults.standard.set(hideDelay, forKey: "hideDelay") }
    }
    
    @Published var autoHideEnabled: Bool {
        didSet { UserDefaults.standard.set(autoHideEnabled, forKey: "autoHideEnabled") }
    }
    
    @Published var keepOpenOnIOSCopy: Bool {
        didSet { UserDefaults.standard.set(keepOpenOnIOSCopy, forKey: "keepOpenOnIOSCopy") }
    }
    
    @Published var themeMode: ThemeMode {
        didSet { UserDefaults.standard.set(themeMode.rawValue, forKey: "themeMode") }
    }
    
    enum ThemeMode: String, CaseIterable {
        case system = "system"
        case light = "light" 
        case dark = "dark"
        
        var displayName: String {
            let locManager = LocalizationManager.shared
            switch self {
            case .system: return locManager.localizedString(.themeSystem)
            case .light: return locManager.localizedString(.themeLight)
            case .dark: return locManager.localizedString(.themeDark)
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "gear"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }
    }
    
    enum ItemLimit: Int, CaseIterable {
        case ten = 10
        case hundred = 100
        case unlimited = -1
        
        var displayName: String {
            let locManager = LocalizationManager.shared
            switch self {
            case .ten: return locManager.localizedString(.itemLimitTen)
            case .hundred: return locManager.localizedString(.itemLimitHundred)
            case .unlimited: return locManager.localizedString(.itemLimitUnlimited)
            }
        }
    }
    
    var currentItemLimit: ItemLimit {
        get {
            switch maxItems {
            case 10: return .ten
            case 100: return .hundred
            default: return .unlimited
            }
        }
        set {
            maxItems = newValue.rawValue == -1 ? 999999 : newValue.rawValue
        }
    }
    
    private init() {
        let defaultScreenshotSize: CGFloat = 176 // Doppelt so groß wie vorher (88 * 2)
        self.screenshotSize = UserDefaults.standard.object(forKey: "screenshotSize") as? CGFloat ?? defaultScreenshotSize
        self.barHeight = UserDefaults.standard.object(forKey: "barHeight") as? CGFloat ?? (defaultScreenshotSize + 100)
        self.maxItems = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 100
        self.autoShowOnCopy = UserDefaults.standard.object(forKey: "autoShowOnCopy") as? Bool ?? true
        self.barOpacity = UserDefaults.standard.object(forKey: "barOpacity") as? Double ?? 0.9
        self.itemSpacing = UserDefaults.standard.object(forKey: "itemSpacing") as? CGFloat ?? 12
        self.cornerRadius = UserDefaults.standard.object(forKey: "cornerRadius") as? CGFloat ?? 12
        self.hideDelay = UserDefaults.standard.object(forKey: "hideDelay") as? Double ?? 3.0
        self.autoHideEnabled = UserDefaults.standard.object(forKey: "autoHideEnabled") as? Bool ?? false
        self.keepOpenOnIOSCopy = UserDefaults.standard.object(forKey: "keepOpenOnIOSCopy") as? Bool ?? true
        self.themeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system
    }
    
    func resetToDefaults() {
        screenshotSize = 176
        barHeight = screenshotSize + 100
        maxItems = 100
        autoShowOnCopy = true
        barOpacity = 0.9
        itemSpacing = 12
        cornerRadius = 12
        hideDelay = 3.0
        autoHideEnabled = false  // Standard: Leiste bleibt offen
        keepOpenOnIOSCopy = true
        themeMode = .system
    }
}
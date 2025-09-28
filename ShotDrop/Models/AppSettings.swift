import Foundation
import SwiftUI
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var barHeight: CGFloat {
        didSet { UserDefaults.standard.set(barHeight, forKey: "barHeight") }
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
            switch self {
            case .system: return "System"
            case .light: return "Hell"
            case .dark: return "Dunkel"
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
            switch self {
            case .ten: return "Letzte 10"
            case .hundred: return "Letzte 100"
            case .unlimited: return "Unbegrenzt"
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
        self.barHeight = UserDefaults.standard.object(forKey: "barHeight") as? CGFloat ?? 120
        self.maxItems = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 100
        self.autoShowOnCopy = UserDefaults.standard.object(forKey: "autoShowOnCopy") as? Bool ?? true
        self.barOpacity = UserDefaults.standard.object(forKey: "barOpacity") as? Double ?? 0.95
        self.itemSpacing = UserDefaults.standard.object(forKey: "itemSpacing") as? CGFloat ?? 12
        self.cornerRadius = UserDefaults.standard.object(forKey: "cornerRadius") as? CGFloat ?? 12
        self.hideDelay = UserDefaults.standard.object(forKey: "hideDelay") as? Double ?? 3.0
        self.autoHideEnabled = UserDefaults.standard.object(forKey: "autoHideEnabled") as? Bool ?? false
        self.keepOpenOnIOSCopy = UserDefaults.standard.object(forKey: "keepOpenOnIOSCopy") as? Bool ?? true
        self.themeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system
    }
    
    func resetToDefaults() {
        barHeight = 120
        maxItems = 100
        autoShowOnCopy = true
        barOpacity = 0.95
        itemSpacing = 12
        cornerRadius = 12
        hideDelay = 3.0
        autoHideEnabled = false
        keepOpenOnIOSCopy = true
        themeMode = .system
    }
}
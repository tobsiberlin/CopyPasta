import Foundation
import SwiftUI
import Combine

// App-Einstellungen mit UserDefaults-Persistierung
// App settings with UserDefaults persistence
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    // Bar-Eigenschaften
    // Bar properties
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
    
    // Verfügbare Optionen
    // Available options
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
        // Standard-Werte laden
        // Load default values
        self.barHeight = UserDefaults.standard.object(forKey: "barHeight") as? CGFloat ?? 120
        self.maxItems = UserDefaults.standard.object(forKey: "maxItems") as? Int ?? 100
        self.autoShowOnCopy = UserDefaults.standard.object(forKey: "autoShowOnCopy") as? Bool ?? true
        self.barOpacity = UserDefaults.standard.object(forKey: "barOpacity") as? Double ?? 0.95
        self.itemSpacing = UserDefaults.standard.object(forKey: "itemSpacing") as? CGFloat ?? 12
        self.cornerRadius = UserDefaults.standard.object(forKey: "cornerRadius") as? CGFloat ?? 12
        self.hideDelay = UserDefaults.standard.object(forKey: "hideDelay") as? Double ?? 3.0
    }
    
    // Standard-Werte wiederherstellen
    // Restore default values
    func resetToDefaults() {
        barHeight = 120
        maxItems = 100
        autoShowOnCopy = true
        barOpacity = 0.95
        itemSpacing = 12
        cornerRadius = 12
        hideDelay = 3.0
    }
}
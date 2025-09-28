import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

// Überwacht das System-Pasteboard für neue Bilder und erkennt Universal Clipboard
// Monitors system pasteboard for new images and detects Universal Clipboard
@MainActor
class PasteboardWatcher: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    @Published var isMonitoring = true
    
    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let maxItems = 100 // Maximale Anzahl gespeicherter Items
    private let pollingInterval: TimeInterval = 0.5 // Schnelles Polling für iPhone-Detection
    
    // Universal Clipboard Detection
    private var lastClipboardUpdate = Date()
    private let universalClipboardTimeout: TimeInterval = 2.0 // Zeit für UC-Übertragung
    
    init() {
        startMonitoring()
        loadPersistedItems()
    }
    
    // Startet das Pasteboard-Monitoring
    // Starts pasteboard monitoring
    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForNewContent()
            }
        }
    }
    
    // Stoppt das Monitoring
    // Stops monitoring
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    // Prüft auf neue Clipboard-Inhalte
    // Checks for new clipboard content
    private func checkForNewContent() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // Unterstützte Bildformate prüfen
        // Check supported image formats
        let imageTypes: [UTType] = [.png, .jpeg, .tiff, .heic, .webP, .bmp, .gif]
        
        guard let availableType = pasteboard.availableType(from: imageTypes.map { NSPasteboard.PasteboardType($0.identifier) }) else {
            return
        }
        
        // Bild-Daten extrahieren
        // Extract image data
        guard let imageData = pasteboard.data(forType: availableType) else { return }
        
        // Hash berechnen für Deduplikation
        // Calculate hash for deduplication
        let hash = ClipboardItem.calculateHash(for: imageData)
        
        // Duplikate vermeiden (nur letzte 8 Einträge prüfen)
        // Avoid duplicates (check only last 8 entries)
        let recentItems = Array(clipboardItems.prefix(8))
        if recentItems.contains(where: { $0.hash == hash }) {
            return
        }
        
        // Universal Clipboard Detection
        let source = detectClipboardSource()
        
        // Neues Item erstellen
        // Create new item
        var newItem = ClipboardItem(
            timestamp: Date(),
            source: source,
            contentType: UTType(availableType.rawValue) ?? .png,
            imageData: imageData,
            hash: hash
        )
        
        // Thumbnail generieren
        // Generate thumbnail
        newItem.generateThumbnail()
        
        // Item hinzufügen
        // Add item
        clipboardItems.insert(newItem, at: 0)
        
        // Limit einhalten
        // Maintain limit
        if clipboardItems.count > maxItems {
            clipboardItems = Array(clipboardItems.prefix(maxItems))
        }
        
        // Bei Universal Clipboard: Auto-Activation
        // For Universal Clipboard: Auto-Activation
        if case .universalClipboard = source {
            autoActivateWindow()
        }
        
        // Änderung persistieren
        // Persist changes
        persistItems()
    }
    
    // Erkennt die Quelle des Clipboard-Inhalts
    // Detects the source of clipboard content
    private func detectClipboardSource() -> ClipboardItem.ClipboardSource {
        // Heuristiken für Universal Clipboard Detection
        // Heuristics for Universal Clipboard Detection
        
        // 1. Prüfe Pasteboard-Metadaten
        // 1. Check pasteboard metadata
        if let types = pasteboard.types {
            // Apple's Universal Clipboard fügt spezielle Metadaten hinzu
            // Apple's Universal Clipboard adds special metadata
            for type in types {
                if type.rawValue.contains("com.apple.") && 
                   type.rawValue.contains("continuity") {
                    return .universalClipboard(deviceName: detectDeviceName())
                }
            }
        }
        
        // 2. Timing-basierte Erkennung
        // 2. Timing-based detection
        let timeSinceLastUpdate = Date().timeIntervalSince(lastClipboardUpdate)
        if timeSinceLastUpdate < universalClipboardTimeout {
            // Schnelle aufeinanderfolgende Updates deuten auf UC hin
            // Quick successive updates indicate UC
            return .universalClipboard(deviceName: detectDeviceName())
        }
        
        // 3. Prüfe auf Handoff-Aktivität
        // 3. Check for Handoff activity
        if isHandoffActive() {
            return .universalClipboard(deviceName: detectDeviceName())
        }
        
        lastClipboardUpdate = Date()
        return .local
    }
    
    // Versucht den Gerätenamen zu ermitteln
    // Attempts to determine device name
    private func detectDeviceName() -> String? {
        // Aus Handoff-Informationen oder Metadaten
        // From Handoff information or metadata
        return nil // Placeholder - würde aus System-APIs kommen
    }
    
    // Prüft ob Handoff aktiv ist
    // Checks if Handoff is active
    private func isHandoffActive() -> Bool {
        // Würde NSUserActivity oder ähnliche APIs nutzen
        // Would use NSUserActivity or similar APIs
        return false // Placeholder
    }
    
    // Aktiviert das App-Fenster automatisch
    // Auto-activates the app window
    private func autoActivateWindow() {
        // App in den Vordergrund bringen
        // Bring app to foreground
        NSApp.activate(ignoringOtherApps: true)
        
        // Hauptfenster anzeigen und fokussieren
        // Show and focus main window
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            
            // Sanfte Erscheinungs-Animation
            // Smooth appearance animation
            window.alphaValue = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1.0
            }
        }
        
        // Notification für UI-Update
        // Notification for UI update
        NotificationCenter.default.post(name: .clipboardAutoActivated, object: nil)
    }
    
    // Lädt gespeicherte Items
    // Loads persisted items
    private func loadPersistedItems() {
        // TODO: Implementierung mit UserDefaults oder Core Data
        // TODO: Implementation with UserDefaults or Core Data
    }
    
    // Speichert Items
    // Saves items
    private func persistItems() {
        // TODO: Implementierung mit UserDefaults oder Core Data
        // TODO: Implementation with UserDefaults or Core Data
    }
    
    // Löscht ein Item
    // Deletes an item
    func deleteItem(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
        persistItems()
    }
    
    // Toggle Favorit
    // Toggle favorite
    func toggleFavorite(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isFavorite.toggle()
            persistItems()
        }
    }
    
    // Löscht alle Items
    // Clears all items
    func clearAll() {
        clipboardItems.removeAll()
        persistItems()
    }
}

// Notification für Auto-Activation
// Notification for Auto-Activation
extension Notification.Name {
    static let clipboardAutoActivated = Notification.Name("clipboardAutoActivated")
}
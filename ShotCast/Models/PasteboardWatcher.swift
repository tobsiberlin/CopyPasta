import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

class PasteboardWatcher: ObservableObject {
    static let shared = PasteboardWatcher()
    
    @Published var clipboardItems: [ClipboardItem] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    
    private init() {
        loadSavedItems()
        startMonitoring()
        lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        print("📋 PasteboardWatcher: Monitoring gestartet")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        print("📋 PasteboardWatcher: Monitoring gestoppt")
    }
    
    private func checkForChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            handlePasteboardChange()
        }
    }
    
    private func handlePasteboardChange() {
        guard let items = pasteboard.pasteboardItems else { return }
        
        for item in items {
            // Prüfe zuerst auf Bilder
            if let imageData = item.data(forType: .png) ?? 
                               item.data(forType: NSPasteboard.PasteboardType("public.jpeg")) ?? 
                               item.data(forType: .tiff) {
                
                let contentType: UTType
                if item.data(forType: .png) != nil {
                    contentType = .png
                } else if item.data(forType: NSPasteboard.PasteboardType("public.jpeg")) != nil {
                    contentType = .jpeg
                } else {
                    contentType = .tiff
                }
                
                let newItem = ClipboardItem(imageData: imageData, contentType: contentType)
                addNewItem(newItem)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .clipboardAutoActivated, object: nil)
                }
                
                break
            }
            // Prüfe auf Text
            else if let text = item.string(forType: .string) {
                let newItem = ClipboardItem(text: text)
                addNewItem(newItem)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .clipboardAutoActivated, object: nil)
                }
                
                break
            }
        }
    }
    
    private func addNewItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // Prüfe auf Duplikate basierend auf Inhalt
            let isDuplicate: Bool
            if let imageData = item.imageData {
                isDuplicate = self.clipboardItems.contains(where: { $0.imageData == imageData })
            } else if let textContent = item.textContent {
                isDuplicate = self.clipboardItems.contains(where: { $0.textContent == textContent })
            } else {
                isDuplicate = false
            }
            
            if !isDuplicate {
                self.clipboardItems.insert(item, at: 0)
                
                let maxItems = AppSettings.shared.maxItems
                if maxItems > 0 && self.clipboardItems.count > maxItems {
                    self.clipboardItems = Array(self.clipboardItems.prefix(maxItems))
                }
                
                self.saveItems()
                let itemType = item.isImage ? "Bild" : "Text"
                print("📋 Neues \(itemType) hinzugefügt. Gesamt: \(self.clipboardItems.count)")
            }
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems.remove(at: index)
            saveItems()
        }
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        if let index = clipboardItems.firstIndex(where: { $0.id == item.id }) {
            clipboardItems[index].isFavorite.toggle()
            saveItems()
        }
    }
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(clipboardItems) {
            UserDefaults.standard.set(encoded, forKey: "clipboardItems")
        }
    }
    
    private func loadSavedItems() {
        if let data = UserDefaults.standard.data(forKey: "clipboardItems"),
           let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            self.clipboardItems = items
            print("📋 \(items.count) gespeicherte Items geladen")
        }
    }
}
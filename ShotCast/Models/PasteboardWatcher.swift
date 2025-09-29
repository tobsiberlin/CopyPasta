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
            var newItem: ClipboardItem? = nil
            
            // 1. Prüfe auf Bilder (höchste Priorität)
            if let imageData = item.data(forType: .png) ?? 
                               item.data(forType: NSPasteboard.PasteboardType("public.jpeg")) ?? 
                               item.data(forType: .tiff) ?? 
                               item.data(forType: NSPasteboard.PasteboardType("public.heic")) ?? 
                               item.data(forType: NSPasteboard.PasteboardType("public.webp")) {
                
                let contentType: UTType
                if item.data(forType: .png) != nil {
                    contentType = .png
                } else if item.data(forType: NSPasteboard.PasteboardType("public.jpeg")) != nil {
                    contentType = .jpeg
                } else if item.data(forType: NSPasteboard.PasteboardType("public.heic")) != nil {
                    contentType = .heic
                } else if item.data(forType: NSPasteboard.PasteboardType("public.webp")) != nil {
                    contentType = UTType("public.webp") ?? .data
                } else {
                    contentType = .tiff
                }
                
                newItem = ClipboardItem(imageData: imageData, contentType: contentType)
            }
            
            // 2. Prüfe auf URLs
            else if let urlString = item.string(forType: NSPasteboard.PasteboardType("public.url")) ?? 
                                   item.string(forType: NSPasteboard.PasteboardType("public.file-url")) {
                newItem = ClipboardItem(url: urlString)
            }
            
            // 3. Prüfe auf HTML
            else if let htmlData = item.data(forType: .html),
                    let htmlString = String(data: htmlData, encoding: .utf8) {
                newItem = ClipboardItem(htmlContent: htmlString)
            }
            
            // 4. Prüfe auf RTF
            else if let rtfData = item.data(forType: .rtf) {
                newItem = ClipboardItem(rtfData: rtfData)
            }
            
            // 5. Prüfe auf Dateien (File Promise)
            else if let fileURL = getFileURL(from: item) {
                if let fileData = try? Data(contentsOf: fileURL),
                   let mimeType = getMimeType(for: fileURL) {
                    let fileName = fileURL.lastPathComponent
                    newItem = ClipboardItem(fileData: fileData, fileName: fileName, mimeType: mimeType)
                }
            }
            
            // 6. Prüfe auf einfachen Text (niedrigste Priorität)
            else if let text = item.string(forType: .string) {
                newItem = ClipboardItem(text: text)
            }
            
            // Item hinzufügen falls gefunden
            if let item = newItem {
                addNewItem(item)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .clipboardAutoActivated, object: nil)
                }
                
                break // Nur das erste gefundene Item verarbeiten
            }
        }
    }
    
    private func getFileURL(from item: NSPasteboardItem) -> URL? {
        // Versuche verschiedene Wege, an eine Datei-URL zu kommen
        if let urlString = item.string(forType: NSPasteboard.PasteboardType("public.file-url")),
           let url = URL(string: urlString) {
            return url
        }
        
        if let urlString = item.string(forType: .fileURL),
           let url = URL(string: urlString) {
            return url
        }
        
        // Prüfe auf Finder File Promise
        if let data = item.data(forType: NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url")),
           let urlString = String(data: data, encoding: .utf8),
           let url = URL(string: urlString) {
            return url
        }
        
        return nil
    }
    
    private func getMimeType(for url: URL) -> String? {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "heic": return "image/heic"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        case "html", "htm": return "text/html"
        case "rtf": return "text/rtf"
        case "json": return "application/json"
        case "xml": return "application/xml"
        case "zip": return "application/zip"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "doc": return "application/msword"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls": return "application/vnd.ms-excel"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "ppt": return "application/vnd.ms-powerpoint"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        default:
            // Fallback: Verwende UTType
            if let type = UTType(filenameExtension: pathExtension) {
                return type.preferredMIMEType ?? "application/octet-stream"
            }
            return "application/octet-stream"
        }
    }
    
    private func addNewItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // Prüfe auf Duplikate basierend auf Inhalt
            let isDuplicate = self.isDuplicateItem(item)
            
            if !isDuplicate {
                self.clipboardItems.insert(item, at: 0)
                
                let maxItems = AppSettings.shared.maxItems
                if maxItems > 0 && self.clipboardItems.count > maxItems {
                    self.clipboardItems = Array(self.clipboardItems.prefix(maxItems))
                }
                
                self.saveItems()
                let itemType = self.getItemTypeDescription(item)
                print("📋 Neues \(itemType) hinzugefügt. Gesamt: \(self.clipboardItems.count)")
            }
        }
    }
    
    private func isDuplicateItem(_ newItem: ClipboardItem) -> Bool {
        return clipboardItems.contains { existingItem in
            switch (newItem.content, existingItem.content) {
            case (.image(let newData), .image(let existingData)):
                return newData == existingData
            case (.text(let newText), .text(let existingText)):
                return newText == existingText
            case (.file(let newData, let newName, let newMime), .file(let existingData, let existingName, let existingMime)):
                return newData == existingData && newName == existingName && newMime == existingMime
            case (.url(let newURL), .url(let existingURL)):
                return newURL == existingURL
            case (.rtf(let newData), .rtf(let existingData)):
                return newData == existingData
            case (.html(let newHTML), .html(let existingHTML)):
                return newHTML == existingHTML
            default:
                return false
            }
        }
    }
    
    private func getItemTypeDescription(_ item: ClipboardItem) -> String {
        switch item.content {
        case .image: return "Bild"
        case .text: return "Text"
        case .file(_, let name, _): return "Datei (\(name))"
        case .url: return "URL"
        case .rtf: return "RTF-Dokument"
        case .html: return "HTML-Dokument"
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
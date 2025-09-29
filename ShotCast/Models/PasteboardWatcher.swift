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
    private let dataManager = ReliableDataManager.shared
    private let processingQueue = DispatchQueue(label: "com.shotcast.pasteboard", qos: .userInitiated)
    private let maxRetries = 3
    
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
        // Robust change detection with retry logic
        var currentChangeCount: Int = 0
        var retryCount = 0
        
        repeat {
            currentChangeCount = pasteboard.changeCount
            retryCount += 1
            
            // If changeCount is unreliable, wait and retry
            if retryCount > 1 {
                Thread.sleep(forTimeInterval: 0.05 * Double(retryCount))
            }
            
        } while retryCount <= maxRetries && currentChangeCount < 0
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Process on background queue to avoid blocking UI
            processingQueue.async { [weak self] in
                self?.handlePasteboardChangeReliably()
            }
        }
    }
    
    private func handlePasteboardChangeReliably() {
        // Robust pasteboard item extraction with retries
        var items: [NSPasteboardItem]?
        var retryCount = 0
        
        repeat {
            items = pasteboard.pasteboardItems
            if items != nil { break }
            
            retryCount += 1
            if retryCount <= maxRetries {
                Thread.sleep(forTimeInterval: 0.1 * Double(retryCount))
            }
        } while retryCount <= maxRetries
        
        guard let pasteboardItems = items, !pasteboardItems.isEmpty else {
            print("❌ No pasteboard items found after \(maxRetries) retries")
            return
        }
        
        for item in pasteboardItems {
            var newItem: ClipboardItem? = nil
            
            // 1. Prüfe ZUERST auf file-URLs von iOS die Bilder sein könnten
            if let fileURLString = item.string(forType: NSPasteboard.PasteboardType("public.file-url")),
               let fileURL = URL(string: fileURLString),
               fileURL.pathExtension.lowercased() == "png" || fileURL.pathExtension.lowercased() == "jpg" || fileURL.pathExtension.lowercased() == "jpeg" {
                // Versuche die Datei als Bild zu laden
                if let imageData = try? Data(contentsOf: fileURL), 
                   imageData.count > 0,
                   NSImage(data: imageData) != nil {
                    let contentType: UTType = fileURL.pathExtension.lowercased() == "png" ? .png : .jpeg
                    newItem = ClipboardItem(imageData: imageData, contentType: contentType)
                    print("✅ iOS Bild erfolgreich geladen: \(fileURL.lastPathComponent)")
                }
            }
            
            // 2. Prüfe auf normale Bilder mit Datenvalidierung
            else if let imageData = extractImageDataReliably(from: item) {
                
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
            
            // 3. Prüfe auf andere URLs (nicht file-urls)
            else if let urlString = item.string(forType: NSPasteboard.PasteboardType("public.url")) {
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
                print("📋 New \(itemType) added. Total: \(self.clipboardItems.count)")
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
        // Use ReliableDataManager for robust saving
        let result = dataManager.saveReliably(clipboardItems, forKey: "clipboardItems", withBackup: true)
        switch result {
        case .success():
            print("✅ Saved \(clipboardItems.count) clipboard items reliably")
        case .failure(let error):
            print("❌ Failed to save clipboard items: \(error.localizedDescription)")
            // Fallback to UserDefaults
            if let encoded = try? JSONEncoder().encode(clipboardItems) {
                UserDefaults.standard.set(encoded, forKey: "clipboardItems")
                print("⚠️ Used UserDefaults fallback")
            }
        }
    }
    
    private func loadSavedItems() {
        // Use ReliableDataManager for robust loading
        switch dataManager.loadReliably([ClipboardItem].self, forKey: "clipboardItems") {
        case .success(let savedItems):
            self.clipboardItems = savedItems ?? []
            print("✅ Loaded \(self.clipboardItems.count) clipboard items reliably")
        case .failure(let error):
            print("❌ Failed to load clipboard items: \(error.localizedDescription)")
            self.clipboardItems = []
        }
    }
    
    // MARK: - Robust Data Extraction Methods
    
    private func extractImageDataReliably(from item: NSPasteboardItem) -> Data? {
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png,
            NSPasteboard.PasteboardType("public.jpeg"),
            .tiff,
            NSPasteboard.PasteboardType("public.heic"),
            NSPasteboard.PasteboardType("public.webp")
        ]
        
        for imageType in imageTypes {
            if let data = extractDataWithValidation(from: item, type: imageType, minSize: 100) {
                // Validate that it's actually image data
                if NSImage(data: data) != nil {
                    return data
                }
            }
        }
        
        return nil
    }
    
    private func extractDataWithValidation(from item: NSPasteboardItem, type: NSPasteboard.PasteboardType, minSize: Int = 0) -> Data? {
        var data: Data?
        var retryCount = 0
        
        repeat {
            data = item.data(forType: type)
            if let extractedData = data {
                // Validate data size
                if extractedData.count >= minSize {
                    // Additional validation for specific types
                    if validateDataIntegrity(extractedData, for: type) {
                        return extractedData
                    }
                }
            }
            
            retryCount += 1
            if retryCount <= maxRetries {
                Thread.sleep(forTimeInterval: 0.05 * Double(retryCount))
            }
            
        } while retryCount <= maxRetries
        
        return nil
    }
    
    private func validateDataIntegrity(_ data: Data, for type: NSPasteboard.PasteboardType) -> Bool {
        // Basic validation based on data type
        switch type.rawValue {
        case "public.png":
            return data.starts(with: [0x89, 0x50, 0x4E, 0x47]) // PNG signature
        case "public.jpeg":
            return data.starts(with: [0xFF, 0xD8, 0xFF]) // JPEG signature
        case "public.tiff":
            return data.starts(with: [0x49, 0x49, 0x2A, 0x00]) || 
                   data.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) // TIFF signatures
        default:
            return data.count > 0 // Basic non-empty check
        }
    }
}
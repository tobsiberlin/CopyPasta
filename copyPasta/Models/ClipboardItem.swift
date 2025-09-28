import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Repräsentiert einen einzelnen Clipboard-Eintrag mit allen Metadaten
// Represents a single clipboard entry with all metadata
struct ClipboardItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let timestamp: Date
    let source: ClipboardSource
    let contentType: UTType
    var imageData: Data
    var thumbnail: NSImage?
    var isFavorite: Bool = false
    let hash: String // SHA256 für Deduplikation
    
    // Quelle des Clipboard-Inhalts
    // Source of clipboard content
    enum ClipboardSource {
        case local
        case universalClipboard(deviceName: String?)
        case unknown
    }
    
    // Berechnet relative Zeit für Anzeige ("vor 2 Min", "Heute 14:32")
    // Calculates relative time for display ("2 min ago", "Today 14:32")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    // Formatiertes Datum für längere Zeiträume
    // Formatted date for longer time periods
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        if Calendar.current.isDateInToday(timestamp) {
            formatter.dateFormat = "'Heute' HH:mm"
        } else if Calendar.current.isDateInYesterday(timestamp) {
            formatter.dateFormat = "'Gestern' HH:mm"
        } else if Calendar.current.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE HH:mm"
        } else {
            formatter.dateFormat = "d. MMM HH:mm"
        }
        
        return formatter.string(from: timestamp)
    }
    
    // Erstellt Thumbnail für Grid-Anzeige
    // Creates thumbnail for grid display
    mutating func generateThumbnail(targetSize: CGSize = CGSize(width: 200, height: 200)) {
        guard let image = NSImage(data: imageData) else { return }
        
        // Smart Cropping - behält Seitenverhältnis bei
        // Smart Cropping - maintains aspect ratio
        let scaleFactor = min(targetSize.width / image.size.width,
                             targetSize.height / image.size.height)
        let scaledSize = CGSize(width: image.size.width * scaleFactor,
                               height: image.size.height * scaleFactor)
        
        let thumbnailImage = NSImage(size: scaledSize)
        thumbnailImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: scaledSize))
        
        thumbnailImage.unlockFocus()
        self.thumbnail = thumbnailImage
    }
    
    // Berechnet SHA256 Hash für Deduplikation
    // Calculates SHA256 hash for deduplication
    static func calculateHash(for data: Data) -> String {
        let hash = data.sha256()
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Extension für SHA256 Berechnung
// Extension for SHA256 calculation
extension Data {
    func sha256() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash
    }
}

// Für CommonCrypto SHA256
// For CommonCrypto SHA256
import CommonCrypto
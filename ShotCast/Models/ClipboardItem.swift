import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum ClipboardContent: Codable, Equatable {
    case image(data: Data)
    case text(content: String)
    case file(data: Data, name: String, mimeType: String)
    case url(urlString: String)
    case rtf(data: Data)
    case html(content: String)
    
    enum CodingKeys: String, CodingKey {
        case type, data, content, name, mimeType, urlString
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "image":
            let data = try container.decode(Data.self, forKey: .data)
            self = .image(data: data)
        case "text":
            let content = try container.decode(String.self, forKey: .content)
            self = .text(content: content)
        case "file":
            let data = try container.decode(Data.self, forKey: .data)
            let name = try container.decode(String.self, forKey: .name)
            let mimeType = try container.decode(String.self, forKey: .mimeType)
            self = .file(data: data, name: name, mimeType: mimeType)
        case "url":
            let urlString = try container.decode(String.self, forKey: .urlString)
            self = .url(urlString: urlString)
        case "rtf":
            let data = try container.decode(Data.self, forKey: .data)
            self = .rtf(data: data)
        case "html":
            let content = try container.decode(String.self, forKey: .content)
            self = .html(content: content)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .image(let data):
            try container.encode("image", forKey: .type)
            try container.encode(data, forKey: .data)
        case .text(let content):
            try container.encode("text", forKey: .type)
            try container.encode(content, forKey: .content)
        case .file(let data, let name, let mimeType):
            try container.encode("file", forKey: .type)
            try container.encode(data, forKey: .data)
            try container.encode(name, forKey: .name)
            try container.encode(mimeType, forKey: .mimeType)
        case .url(let urlString):
            try container.encode("url", forKey: .type)
            try container.encode(urlString, forKey: .urlString)
        case .rtf(let data):
            try container.encode("rtf", forKey: .type)
            try container.encode(data, forKey: .data)
        case .html(let content):
            try container.encode("html", forKey: .type)
            try container.encode(content, forKey: .content)
        }
    }
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let content: ClipboardContent
    let contentType: UTType
    let timestamp: Date
    var isFavorite: Bool = false
    var sourceInfo: SourceDetector.SourceInfo?
    
    enum CodingKeys: CodingKey {
        case content, contentType, timestamp, isFavorite, sourceInfo
    }
    
    init(imageData: Data, contentType: UTType, timestamp: Date = Date()) {
        self.content = .image(data: imageData)
        self.contentType = contentType
        self.timestamp = timestamp
        self.sourceInfo = SourceDetector.shared.detectSource()
    }
    
    init(text: String, timestamp: Date = Date()) {
        self.content = .text(content: text)
        self.contentType = .plainText
        self.timestamp = timestamp
        self.sourceInfo = SourceDetector.shared.detectSource()
    }
    
    init(fileData: Data, fileName: String, mimeType: String, timestamp: Date = Date()) {
        self.content = .file(data: fileData, name: fileName, mimeType: mimeType)
        self.contentType = UTType(mimeType: mimeType) ?? .data
        self.timestamp = timestamp
        self.sourceInfo = SourceDetector.shared.detectSource()
    }
    
    init(url: String, timestamp: Date = Date()) {
        self.content = .url(urlString: url)
        self.contentType = .url
        self.timestamp = timestamp
        self.sourceInfo = SourceDetector.shared.detectSource()
    }
    
    init(rtfData: Data, timestamp: Date = Date()) {
        self.content = .rtf(data: rtfData)
        self.contentType = .rtf
        self.timestamp = timestamp
        self.sourceInfo = SourceDetector.shared.detectSource()
    }
    
    init(htmlContent: String, timestamp: Date = Date()) {
        self.content = .html(content: htmlContent)
        self.contentType = .html
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Für Abwärtskompatibilität: Alte Items haben imageData statt content
        if let imageData = try? container.decode(Data.self, forKey: .content) {
            self.content = .image(data: imageData)
        } else {
            self.content = try container.decode(ClipboardContent.self, forKey: .content)
        }
        
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        
        let typeString = try container.decode(String.self, forKey: .contentType)
        contentType = UTType(typeString) ?? .png
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(contentType.identifier, forKey: .contentType)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
    
    // Kompatibilitäts-Properties
    var imageData: Data? {
        if case .image(let data) = content {
            return data
        }
        return nil
    }
    
    var textContent: String? {
        if case .text(let content) = content {
            return content
        }
        return nil
    }
    
    var isImage: Bool {
        if case .image = content {
            return true
        }
        return false
    }
    
    var isText: Bool {
        if case .text = content {
            return true
        }
        return false
    }
    
    var isFile: Bool {
        if case .file = content {
            return true
        }
        return false
    }
    
    var isURL: Bool {
        if case .url = content {
            return true
        }
        return false
    }
    
    var isRTF: Bool {
        if case .rtf = content {
            return true
        }
        return false
    }
    
    var isHTML: Bool {
        if case .html = content {
            return true
        }
        return false
    }
    
    var fileName: String? {
        if case .file(_, let name, _) = content {
            return name
        }
        return nil
    }
    
    var fileData: Data? {
        if case .file(let data, _, _) = content {
            return data
        }
        return nil
    }
    
    var urlString: String? {
        if case .url(let urlString) = content {
            return urlString
        }
        return nil
    }
    
    var rtfData: Data? {
        if case .rtf(let data) = content {
            return data
        }
        return nil
    }
    
    var htmlContent: String? {
        if case .html(let content) = content {
            return content
        }
        return nil
    }
    
    // Erweiterte Dateityp-Erkennung
    var fileTypeCategory: FileTypeCategory {
        if isImage { return .image }
        if isText { return .text }
        if isURL { return .url }
        if isHTML || isRTF { return .document }
        
        if isFile {
            guard let mimeType = mimeType else { return .other }
            
            if mimeType.hasPrefix("image/") { return .image }
            if mimeType.hasPrefix("video/") { return .video }
            if mimeType.hasPrefix("audio/") { return .audio }
            if mimeType == "application/pdf" { return .pdf }
            if mimeType.hasPrefix("application/") && (
                mimeType.contains("zip") || 
                mimeType.contains("archive") || 
                mimeType.contains("compressed")
            ) { return .archive }
            
            // Code-Dateien erkennen
            if isCodeFile(mimeType: mimeType) { return .code }
            
            if mimeType.hasPrefix("text/") { return .document }
            
            return .document
        }
        
        return .other
    }
    
    var mimeType: String? {
        if case .file(_, _, let mimeType) = content {
            return mimeType
        }
        return nil
    }
    
    private func isCodeFile(mimeType: String) -> Bool {
        let codeTypes = [
            "text/javascript", "application/javascript",
            "text/css", "text/html", "application/json",
            "text/xml", "application/xml",
            "text/x-python", "text/x-java-source",
            "text/x-swift", "text/x-c", "text/x-c++",
            "text/x-objective-c", "text/x-php",
            "text/x-ruby", "text/x-go", "text/x-rust",
            "text/x-kotlin", "text/x-dart"
        ]
        return codeTypes.contains(mimeType)
    }
    
    enum FileTypeCategory {
        case image, text, document, pdf, video, audio, archive, url, code, other
        
        var icon: String {
            switch self {
            case .image: return "photo.artframe" // Süßeres Bild-Icon mit Rahmen
            case .text: return "doc.text.magnifyingglass" // Text mit Lupe
            case .document: return "doc.text.fill"
            case .pdf: return "doc.richtext.fill"
            case .video: return "play.rectangle.fill" 
            case .audio: return "music.note.list" // Musik-Liste Icon
            case .archive: return "archivebox.fill"
            case .url: return "safari.fill" // Safari-Icon für URLs
            case .code: return "terminal.fill" // Terminal für Code
            case .other: return "questionmark.folder.fill" // Fragezeichen-Ordner
            }
        }
        
        var sourceBadge: String? {
            // Spezielle Source-Badges wie im Screenshot - immer anzeigen
            switch self {
            case .image: return "S" // Screenshot badge
            case .text: return "T" // Text badge
            case .document: return "D" // Document badge
            case .pdf: return "P" // PDF badge
            case .video: return "V" // Video badge
            case .audio: return "A" // Audio badge
            case .archive: return "Z" // Zip badge
            case .url: return "L" // Link badge
            case .code: return "C" // Code badge
            case .other: return "F" // File badge
            }
        }

        var badgeColor: Color {
            // Badge-Farben für die Buchstaben-Fallbacks
            switch self {
            case .image: return .red // Wie im Screenshot - rotes "S"
            case .text: return .green
            case .document: return .blue
            case .pdf: return .red
            case .video: return .purple
            case .audio: return .orange
            case .archive: return .brown
            case .url: return .teal
            case .code: return .indigo
            case .other: return .gray
            }
        }
        
        var colors: [Color] {
            // Süße Pastell-Farben wie im Screenshot
            switch self {
            case .image: return [Color(.systemBlue), Color(.systemCyan)]
            case .text: return [Color(.systemGreen), Color(.systemMint)] 
            case .document: return [Color(.systemIndigo), Color(.systemBlue)]
            case .pdf: return [Color(.systemRed), Color(.systemOrange)]
            case .video: return [Color(.systemPurple), Color(.systemPink)]
            case .audio: return [Color(.systemOrange), Color(.systemYellow)]
            case .archive: return [Color(.systemBrown), Color(.systemOrange)]
            case .url: return [Color(.systemTeal), Color(.systemCyan)]
            case .code: return [Color(.systemPurple), Color(.systemIndigo)]
            case .other: return [Color(.systemGray), Color(.systemGray)]
            }
        }
        
        
        var color: Color {
            // Hauptfarben für die Icon-Darstellung
            switch self {
            case .image: return .blue
            case .text: return .green
            case .document: return .indigo
            case .pdf: return .red
            case .video: return .purple
            case .audio: return .orange
            case .archive: return .brown
            case .url: return .teal
            case .code: return .purple
            case .other: return .gray
            }
        }
        
        var displayName: String {
            // Anzeigename für den Dateityp
            switch self {
            case .image: return "Bild"
            case .text: return "Text" 
            case .document: return "Dokument"
            case .pdf: return "PDF"
            case .video: return "Video"
            case .audio: return "Audio"
            case .archive: return "Archiv"
            case .url: return "URL"
            case .code: return "Code"
            case .other: return "Datei"
            }
        }
    }
}

extension Notification.Name {
    static let clipboardAutoActivated = Notification.Name("clipboardAutoActivated")
    static let showToast = Notification.Name("showToast")
}

struct ToastInfo {
    let message: String
    let duration: TimeInterval
}
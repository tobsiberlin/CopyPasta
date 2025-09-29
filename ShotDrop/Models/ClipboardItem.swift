import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum ClipboardContent: Codable {
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

struct ClipboardItem: Identifiable, Codable {
    let id = UUID()
    let content: ClipboardContent
    let contentType: UTType
    let timestamp: Date
    var isFavorite: Bool = false
    
    enum CodingKeys: CodingKey {
        case content, contentType, timestamp, isFavorite
    }
    
    init(imageData: Data, contentType: UTType, timestamp: Date = Date()) {
        self.content = .image(data: imageData)
        self.contentType = contentType
        self.timestamp = timestamp
    }
    
    init(text: String, timestamp: Date = Date()) {
        self.content = .text(content: text)
        self.contentType = .plainText
        self.timestamp = timestamp
    }
    
    init(fileData: Data, fileName: String, mimeType: String, timestamp: Date = Date()) {
        self.content = .file(data: fileData, name: fileName, mimeType: mimeType)
        self.contentType = UTType(mimeType: mimeType) ?? .data
        self.timestamp = timestamp
    }
    
    init(url: String, timestamp: Date = Date()) {
        self.content = .url(urlString: url)
        self.contentType = .url
        self.timestamp = timestamp
    }
    
    init(rtfData: Data, timestamp: Date = Date()) {
        self.content = .rtf(data: rtfData)
        self.contentType = .rtf
        self.timestamp = timestamp
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
    
    enum FileTypeCategory {
        case image, text, document, pdf, video, audio, archive, url, other
        
        var icon: String {
            switch self {
            case .image: return "photo"
            case .text: return "doc.text"
            case .document: return "doc"
            case .pdf: return "doc.richtext"
            case .video: return "video"
            case .audio: return "music.note"
            case .archive: return "archivebox"
            case .url: return "link"
            case .other: return "doc.questionmark"
            }
        }
        
        var colors: [Color] {
            switch self {
            case .image: return [.blue, .cyan]
            case .text: return [.green, .mint]
            case .document: return [.indigo, .blue]
            case .pdf: return [.red, .orange]
            case .video: return [.purple, .pink]
            case .audio: return [.orange, .yellow]
            case .archive: return [.brown, .orange]
            case .url: return [.teal, .cyan]
            case .other: return [.gray, .secondary]
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
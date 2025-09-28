import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ClipboardItem: Identifiable, Codable {
    let id = UUID()
    let imageData: Data
    let contentType: UTType
    let timestamp: Date
    var isFavorite: Bool = false
    
    enum CodingKeys: CodingKey {
        case imageData, contentType, timestamp, isFavorite
    }
    
    init(imageData: Data, contentType: UTType, timestamp: Date = Date()) {
        self.imageData = imageData
        self.contentType = contentType
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageData = try container.decode(Data.self, forKey: .imageData)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        
        let typeString = try container.decode(String.self, forKey: .contentType)
        contentType = UTType(typeString) ?? .png
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageData, forKey: .imageData)
        try container.encode(contentType.identifier, forKey: .contentType)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
}

extension Notification.Name {
    static let clipboardAutoActivated = Notification.Name("clipboardAutoActivated")
}
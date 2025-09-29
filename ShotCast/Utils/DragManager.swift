import Foundation
import AppKit
import UniformTypeIdentifiers
import SwiftUI

class DragManager {
    static let shared = DragManager()
    
    private init() {}
    
    /// Creates a professional NSItemProvider for dragging various clipboard items
    func createItemProvider(for item: ClipboardItem) -> NSItemProvider {
        let itemProvider = NSItemProvider()
        
        // Prioritize native data types first for better compatibility
        if item.isImage, let imageData = item.imageData {
            addImageTypes(to: itemProvider, with: imageData, contentType: item.contentType)
        } else if item.isText, let text = item.textContent {
            addTextTypes(to: itemProvider, with: text)
        } else if item.isURL, let urlString = item.urlString {
            addURLTypes(to: itemProvider, with: urlString)
        } else if let fileName = item.fileName, let data = item.imageData {
            addFileTypes(to: itemProvider, with: data, fileName: fileName, contentType: item.contentType)
        }
        
        return itemProvider
    }
    
    /// Creates a comprehensive drag preview that matches the item type
    func createDragPreview(for item: ClipboardItem, size: CGSize = CGSize(width: 80, height: 80)) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            if item.isImage, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width - 8, height: size.height - 8)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: item.fileTypeCategory.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: item.fileTypeCategory.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    if item.isText, let text = item.textContent {
                        Text(String(text.prefix(12)) + (text.count > 12 ? "..." : ""))
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                    } else if item.isURL, let urlString = item.urlString {
                        Text(URL(string: urlString)?.host ?? URL(string: urlString)?.lastPathComponent ?? "URL")
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                    } else if let fileName = item.fileName {
                        Text(fileName)
                            .font(.caption2)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 4)
                    }
                }
            }
            
            // Add type indicator badge
            VStack {
                HStack {
                    Spacer()
                    Text(getTypeIndicator(for: item))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(item.fileTypeCategory.colors.first ?? .blue)
                        )
                }
                Spacer()
            }
            .padding(4)
        }
        .frame(width: size.width, height: size.height)
    }
    
    // MARK: - Private Helper Methods
    
    private func addImageTypes(to provider: NSItemProvider, with data: Data, contentType: UTType) {
        // Add specific image type first
        provider.registerDataRepresentation(forTypeIdentifier: contentType.identifier, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }
        
        // Add common image types for broader compatibility
        let imageTypes: [UTType] = [.png, .jpeg, .tiff, .heic]
        for type in imageTypes {
            if type != contentType {
                provider.registerDataRepresentation(forTypeIdentifier: type.identifier, visibility: .all) { completion in
                    if let nsImage = NSImage(data: data) {
                        if let convertedData = self.convertImageData(nsImage, to: type) {
                            completion(convertedData, nil)
                        } else {
                            completion(data, nil)
                        }
                    } else {
                        completion(data, nil)
                    }
                    return nil
                }
            }
        }
        
        // Add as file promise for desktop drops
        if let tempURL = saveToTemporaryFile(data: data, extension: contentType.preferredFilenameExtension ?? "png") {
            provider.registerFileRepresentation(forTypeIdentifier: contentType.identifier, visibility: .all) { completion in
                completion(tempURL, true, nil)
                return nil
            }
        }
    }
    
    private func addTextTypes(to provider: NSItemProvider, with text: String) {
        // Add as plain text
        provider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
            completion(text.data(using: .utf8), nil)
            return nil
        }
        
        // Add as UTF-8 text for better compatibility
        provider.registerDataRepresentation(forTypeIdentifier: UTType.utf8PlainText.identifier, visibility: .all) { completion in
            completion(text.data(using: .utf8), nil)
            return nil
        }
        
        // Add as RTF for rich applications
        provider.registerDataRepresentation(forTypeIdentifier: UTType.rtf.identifier, visibility: .all) { completion in
            if let rtfData = text.data(using: .utf8) {
                completion(rtfData, nil)
            } else {
                completion(nil, NSError(domain: "DragError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert text to RTF"]))
            }
            return nil
        }
    }
    
    private func addURLTypes(to provider: NSItemProvider, with urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        // Add as URL
        provider.registerDataRepresentation(forTypeIdentifier: UTType.url.identifier, visibility: .all) { completion in
            completion(url.absoluteString.data(using: .utf8), nil)
            return nil
        }
        
        // Add as file URL if applicable
        if url.isFileURL {
            provider.registerFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier, visibility: .all) { completion in
                completion(url, true, nil)
                return nil
            }
        }
        
        // Add as plain text fallback
        provider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
            completion(urlString.data(using: .utf8), nil)
            return nil
        }
    }
    
    private func addFileTypes(to provider: NSItemProvider, with data: Data, fileName: String, contentType: UTType) {
        // Add as specific file type
        provider.registerDataRepresentation(forTypeIdentifier: contentType.identifier, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }
        
        // Create temporary file for file system operations
        if let tempURL = saveToTemporaryFile(data: data, extension: fileName) {
            provider.registerFileRepresentation(forTypeIdentifier: contentType.identifier, visibility: .all) { completion in
                completion(tempURL, true, nil)
                return nil
            }
        }
    }
    
    private func convertImageData(_ image: NSImage, to type: UTType) -> Data? {
        guard let tiffData = image.tiffRepresentation else { return nil }
        let bitmap = NSBitmapImageRep(data: tiffData)
        
        switch type {
        case .png:
            return bitmap?.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmap?.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        case .tiff:
            return tiffData
        default:
            return bitmap?.representation(using: .png, properties: [:])
        }
    }
    
    private func saveToTemporaryFile(data: Data, extension fileExtension: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "ShotCast_Drag_\\(UUID().uuidString).\\(fileExtension)"
        let tempURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("❌ Failed to create temporary file: \\(error)")
            return nil
        }
    }
    
    private func getTypeIndicator(for item: ClipboardItem) -> String {
        switch item.fileTypeCategory {
        case .image:
            switch item.contentType {
            case .png: return "PNG"
            case .jpeg: return "JPG" 
            case .tiff: return "TIFF"
            case .heic: return "HEIC"
            default: return "IMG"
            }
        case .text: return "TXT"
        case .document: return "DOC"
        case .pdf: return "PDF"
        case .video: return "VID"
        case .audio: return "AUD"
        case .archive: return "ZIP"
        case .url: return "URL"
        case .code: return "CODE"
        case .other: return "FILE"
        }
    }
}
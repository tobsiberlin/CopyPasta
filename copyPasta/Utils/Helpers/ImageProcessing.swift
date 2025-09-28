import Foundation
import AppKit
import UniformTypeIdentifiers

// Erweiterte Bildverarbeitung und Smart Cropping
// Advanced image processing and smart cropping
class ImageProcessing {
    
    // Smart Cropping für Thumbnails
    // Smart cropping for thumbnails
    static func smartCropImage(_ image: NSImage, targetSize: CGSize) -> NSImage {
        let originalSize = image.size
        
        // Berechne Seitenverhältnisse
        // Calculate aspect ratios
        let targetAspect = targetSize.width / targetSize.height
        let imageAspect = originalSize.width / originalSize.height
        
        var drawRect = NSRect.zero
        
        if imageAspect > targetAspect {
            // Bild ist breiter - schneide links/rechts ab
            // Image is wider - crop left/right
            let scaledHeight = targetSize.height
            let scaledWidth = scaledHeight * imageAspect
            let xOffset = (scaledWidth - targetSize.width) / 2
            drawRect = NSRect(x: -xOffset, y: 0, width: scaledWidth, height: scaledHeight)
        } else {
            // Bild ist höher - schneide oben/unten ab
            // Image is taller - crop top/bottom
            let scaledWidth = targetSize.width
            let scaledHeight = scaledWidth / imageAspect
            let yOffset = (scaledHeight - targetSize.height) / 2
            drawRect = NSRect(x: 0, y: -yOffset, width: scaledWidth, height: scaledHeight)
        }
        
        // Erstelle cropped Image
        // Create cropped image
        let croppedImage = NSImage(size: targetSize)
        croppedImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: drawRect)
        
        croppedImage.unlockFocus()
        
        return croppedImage
    }
    
    // Konvertiert Bild in verschiedene Formate
    // Converts image to different formats
    static func convertImage(_ imageData: Data, to format: UTType) -> Data? {
        guard let image = NSImage(data: imageData) else { return nil }
        
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage!)
        
        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        case .tiff:
            return bitmapRep.representation(using: .tiff, properties: [:])
        default:
            return nil
        }
    }
    
    // Optimiert Bildgröße für Speicherung
    // Optimizes image size for storage
    static func optimizeImageData(_ imageData: Data, maxSize: CGSize) -> Data? {
        guard let image = NSImage(data: imageData) else { return nil }
        
        let originalSize = image.size
        
        // Prüfe ob Skalierung nötig ist
        // Check if scaling is needed
        if originalSize.width <= maxSize.width && originalSize.height <= maxSize.height {
            return imageData
        }
        
        // Berechne Skalierungsfaktor
        // Calculate scale factor
        let scale = min(maxSize.width / originalSize.width,
                       maxSize.height / originalSize.height)
        
        let newSize = CGSize(width: originalSize.width * scale,
                           height: originalSize.height * scale)
        
        // Skaliere Bild
        // Scale image
        let scaledImage = NSImage(size: newSize)
        scaledImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize))
        
        scaledImage.unlockFocus()
        
        // Konvertiere zu optimiertem JPEG
        // Convert to optimized JPEG
        guard let tiffData = scaledImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    }
    
    // Erkennt dominante Farben im Bild
    // Detects dominant colors in image
    static func getDominantColors(from imageData: Data, count: Int = 3) -> [NSColor] {
        // TODO: Implementierung für Farberkennung
        // TODO: Implementation for color detection
        return [.systemBlue, .systemPurple, .systemPink]
    }
}
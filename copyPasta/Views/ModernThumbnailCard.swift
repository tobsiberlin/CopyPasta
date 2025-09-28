import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Moderne Thumbnail-Karte für die Bottom Bar
// Modern thumbnail card for the bottom bar
struct ModernThumbnailCard: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isHovered: Bool
    let cornerRadius: CGFloat
    
    @State private var thumbnailImage: NSImage?
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Hintergrund mit modernem Glaseffekt
            // Background with modern glass effect
            backgroundView
            
            // Thumbnail-Inhalt
            // Thumbnail content
            thumbnailContent
            
            // Overlay für Status-Indikatoren
            // Overlay for status indicators
            overlayView
        }
        .scaleEffect(isDragging ? 1.1 : (isHovered ? 1.05 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isDragging)
        .onDrag {
            isDragging = true
            return createDragProvider()
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    // Moderner Hintergrund
    // Modern background
    private var backgroundView: some View {
        ZStack {
            // Basis-Glaseffekt
            // Base glass effect
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Selected/Hover States
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.blue, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.blue.opacity(0.1))
                    )
            } else if isHovered {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    // Thumbnail-Inhalt
    // Thumbnail content
    private var thumbnailContent: some View {
        Group {
            if let thumbnail = thumbnailImage {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 2))
            } else {
                // Loading State
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius - 2)
                        .fill(.gray.opacity(0.2))
                    
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
        .padding(4)
    }
    
    // Overlay für Indikatoren
    // Overlay for indicators
    private var overlayView: some View {
        VStack {
            HStack {
                Spacer()
                
                // Status-Indikatoren
                // Status indicators
                VStack(spacing: 4) {
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 16, height: 16)
                            )
                    }
                    
                    if case .universalClipboard = item.source {
                        Image(systemName: "iphone")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 16, height: 16)
                            )
                    }
                }
            }
            
            Spacer()
            
            // Zeit-Indikator am unteren Rand
            // Time indicator at bottom
            if isHovered {
                HStack {
                    Text(item.relativeTimeString)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.6))
                        )
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(6)
    }
    
    // Thumbnail laden mit besserer Qualität
    // Load thumbnail with better quality
    private func loadThumbnail() {
        guard thumbnailImage == nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = generateHighQualityThumbnail()
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.thumbnailImage = thumbnail
                }
            }
        }
    }
    
    // Hochqualitatives Thumbnail generieren
    // Generate high-quality thumbnail
    private func generateHighQualityThumbnail() -> NSImage? {
        guard let originalImage = NSImage(data: item.imageData) else { return nil }
        
        let targetSize = CGSize(width: 200, height: 200)
        let imageSize = originalImage.size
        
        // Berechne optimale Skalierung
        // Calculate optimal scaling
        let scale = max(targetSize.width / imageSize.width,
                       targetSize.height / imageSize.height)
        
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Smart Crop für quadratisches Format
        // Smart crop for square format
        let cropRect = CGRect(
            x: (scaledSize.width - targetSize.width) / 2,
            y: (scaledSize.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        originalImage.draw(
            in: NSRect(origin: CGPoint(x: -cropRect.minX, y: -cropRect.minY), size: scaledSize)
        )
        
        thumbnail.unlockFocus()
        return thumbnail
    }
    
    // Drag Provider für funktionierendes Drag & Drop
    // Drag provider for working drag & drop
    private func createDragProvider() -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Registriere das Bild in verschiedenen Formaten
        // Register image in various formats
        provider.registerDataRepresentation(forTypeIdentifier: item.contentType.identifier, visibility: .all) { completion in
            completion(item.imageData, nil)
            return nil
        }
        
        // Zusätzliche Formate für bessere Kompatibilität
        // Additional formats for better compatibility
        provider.registerDataRepresentation(forTypeIdentifier: UTType.png.identifier, visibility: .all) { completion in
            if item.contentType != .png {
                // Konvertiere zu PNG wenn nötig
                // Convert to PNG if necessary
                if let image = NSImage(data: item.imageData),
                   let tiffData = image.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    completion(pngData, nil)
                } else {
                    completion(item.imageData, nil)
                }
            } else {
                completion(item.imageData, nil)
            }
            return nil
        }
        
        // Preview-Image für Drag-Vorschau
        // Preview image for drag preview
        if let thumbnail = thumbnailImage {
            provider.previewImageHandler = { handler, expectedClass, options in
                handler?(thumbnail as NSSecureCoding, nil)
            }
        }
        
        return provider
    }
}
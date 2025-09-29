import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Einzelne Kachel im Paste-Style für Clipboard-Items
// Single tile in Paste style for clipboard items
struct ThumbnailCard: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isHovered: Bool
    
    @State private var isDragging = false
    @State private var thumbnailImage: NSImage?
    
    // Paste-Style Farben
    // Paste-style colors
    private let cardBackground = Color(NSColor.controlBackgroundColor)
    private let hoverBackground = Color(NSColor.selectedControlColor).opacity(0.1)
    private let selectedBackground = Color.accentColor.opacity(0.15)
    
    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail-Bereich
            // Thumbnail area
            thumbnailView
                .aspectRatio(1, contentMode: .fit)
            
            // Metadaten-Bereich
            // Metadata area
            metadataView
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
        .background(backgroundView)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(isDragging ? 0.3 : 0.1), 
                radius: isDragging ? 12 : 6, 
                x: 0, 
                y: isDragging ? 6 : 2)
        .scaleEffect(isDragging ? 1.05 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .onDrag {
            isDragging = true
            return createDragProvider()
        }
        .onDrop(of: [.image], delegate: CardDropDelegate(isDragging: $isDragging))
        .onAppear {
            loadThumbnail()
        }
    }
    
    // Hintergrund mit Hover/Selected States
    // Background with hover/selected states
    private var backgroundView: some View {
        ZStack {
            cardBackground
            
            if isSelected {
                selectedBackground
            } else if isHovered {
                hoverBackground
            }
            
            // Paste-Style Border für Selected
            // Paste-style border for selected
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
    }
    
    // Thumbnail-Ansicht
    // Thumbnail view
    private var thumbnailView: some View {
        Group {
            if let thumbnail = thumbnailImage {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                // Placeholder während Laden
                // Placeholder while loading
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
            }
        }
    }
    
    // Metadaten-Ansicht
    // Metadata view
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Zeit-Label
                // Time label
                Text(item.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Icons für Status
                // Icons for status
                HStack(spacing: 4) {
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    
                    // Universal Clipboard Indikator
                    // Universal Clipboard indicator
                    if case .universalClipboard(let device) = item.source {
                        Image(systemName: "iphone")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                            .help(device ?? "iPhone")
                    }
                }
            }
            
            // Größen-Info
            // Size info
            Text(formatFileSize(item.imageData.count))
                .font(.caption2)
                .foregroundColor(Color.secondary.opacity(0.7))
        }
    }
    
    // Thumbnail laden
    // Load thumbnail
    private func loadThumbnail() {
        guard thumbnailImage == nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = generateThumbnail()
            DispatchQueue.main.async {
                withAnimation {
                    self.thumbnailImage = thumbnail
                }
            }
        }
    }
    
    // Thumbnail generieren mit Smart Cropping
    // Generate thumbnail with smart cropping
    private func generateThumbnail() -> NSImage? {
        guard let originalImage = NSImage(data: item.imageData) else { return nil }
        
        let targetSize = CGSize(width: 200, height: 200)
        let scaleFactor = min(targetSize.width / originalImage.size.width,
                             targetSize.height / originalImage.size.height)
        
        let scaledSize = CGSize(width: originalImage.size.width * scaleFactor,
                               height: originalImage.size.height * scaleFactor)
        
        let thumbnail = NSImage(size: scaledSize)
        thumbnail.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        originalImage.draw(in: NSRect(origin: .zero, size: scaledSize))
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
    
    // Drag Provider erstellen
    // Create drag provider
    private func createDragProvider() -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Bietet verschiedene Formate an
        // Offers different formats
        provider.registerDataRepresentation(forTypeIdentifier: item.contentType.identifier, 
                                          visibility: .all) { completion in
            completion(item.imageData, nil)
            return nil
        }
        
        // Preview-Image für Drag
        // Preview image for drag
        if let thumbnail = thumbnailImage {
            provider.previewImageHandler = { (handler, _, _) -> Void in
                handler?(thumbnail as NSSecureCoding, nil)
            }
        }
        
        return provider
    }
    
    // Dateigröße formatieren
    // Format file size
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// Drop Delegate für Drag & Drop
// Drop Delegate for Drag & Drop
struct CardDropDelegate: DropDelegate {
    @Binding var isDragging: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        isDragging = false
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Optional: Visual feedback
    }
    
    func dropExited(info: DropInfo) {
        isDragging = false
    }
}
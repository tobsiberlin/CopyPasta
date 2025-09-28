import SwiftUI
import AppKit
import QuickLookUI

// Vollbild-Preview für Clipboard-Bilder
// Full-screen preview for clipboard images
struct PreviewView: View {
    let item: ClipboardItem
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var image: NSImage?
    
    var body: some View {
        ZStack {
            // Dunkler Hintergrund
            // Dark background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Bild mit Zoom und Pan
            // Image with zoom and pan
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(0.5, min(5.0, value))
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            if scale != 1.0 {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
            } else {
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            // Overlay mit Metadaten
            // Overlay with metadata
            VStack {
                HStack {
                    // Metadaten
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.formattedDate)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            if case .universalClipboard(let device) = item.source {
                                Label(device ?? "iPhone", systemImage: "iphone")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Text(formatImageSize())
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Close Button
                    Button(action: {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                
                Spacer()
                
                // Action Bar
                HStack(spacing: 20) {
                    PreviewActionButton(
                        icon: "doc.on.clipboard",
                        title: "Kopieren",
                        action: copyToClipboard
                    )
                    
                    PreviewActionButton(
                        icon: "square.and.arrow.down",
                        title: "Speichern",
                        action: saveImage
                    )
                    
                    PreviewActionButton(
                        icon: item.isFavorite ? "star.fill" : "star",
                        title: "Favorit",
                        action: toggleFavorite
                    )
                    
                    PreviewActionButton(
                        icon: "trash",
                        title: "Löschen",
                        action: deleteItem
                    )
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
            }
            .padding()
        }
        .onAppear {
            loadFullImage()
        }
        .onKeyboardShortcut(.escape) {
            isPresented = false
        }
        .onKeyboardShortcut(.space) {
            // Quick Look alternative
            openInQuickLook()
        }
    }
    
    // Lädt das Bild in voller Auflösung
    // Loads the image in full resolution
    private func loadFullImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fullImage = NSImage(data: item.imageData)
            DispatchQueue.main.async {
                withAnimation {
                    self.image = fullImage
                }
            }
        }
    }
    
    // Format Bildgröße und Dimensionen
    // Format image size and dimensions
    private func formatImageSize() -> String {
        guard let image = NSImage(data: item.imageData) else { return "" }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        let sizeString = formatter.string(fromByteCount: Int64(item.imageData.count))
        
        let dimensions = "\(Int(image.size.width))×\(Int(image.size.height))"
        
        return "\(dimensions) • \(sizeString)"
    }
    
    // Actions
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(item.imageData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        
        // Visual feedback
        NSSound.beep()
    }
    
    private func saveImage() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [item.contentType]
        savePanel.nameFieldStringValue = "CopyPasta_\(Int(item.timestamp.timeIntervalSince1970))"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? item.imageData.write(to: url)
            }
        }
    }
    
    private func toggleFavorite() {
        // TODO: Implement favorite toggle
    }
    
    private func deleteItem() {
        // TODO: Implement delete
        isPresented = false
    }
    
    private func openInQuickLook() {
        // Create temporary file for Quick Look
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CopyPasta_\(item.id)")
            .appendingPathExtension(item.contentType.preferredFilenameExtension ?? "png")
        
        try? item.imageData.write(to: tempURL)
        
        NSWorkspace.shared.open(tempURL)
    }
}

// Action Button Component
struct PreviewActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(isHovered ? Color.white.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
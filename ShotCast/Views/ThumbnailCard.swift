import SwiftUI
import AppKit

struct ThumbnailCard: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isHovered: Bool
    let onDoubleClick: () -> Void
    let onOCRExtract: ((String) -> Void)?
    
    init(item: ClipboardItem, isSelected: Bool, isHovered: Bool, onDoubleClick: @escaping () -> Void, onOCRExtract: ((String) -> Void)? = nil) {
        self.item = item
        self.isSelected = isSelected
        self.isHovered = isHovered
        self.onDoubleClick = onDoubleClick
        self.onOCRExtract = onOCRExtract
    }
    
    private var borderColor: Color {
        if isSelected {
            return .accentColor
        } else {
            return Color(NSColor.separatorColor).opacity(0.8)
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected {
            return 3.0
        } else if isHovered {
            return 2.0
        } else {
            return 1.5
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                        .animation(.easeInOut(duration: 0.2), value: borderWidth)
                        .animation(.easeInOut(duration: 0.2), value: borderColor)
                )
            
            // Dynamische Darstellung basierend auf Dateityp
            Group {
                if item.isImage {
                    if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(4)
                    } else {
                        fileTypeIconView
                    }
                } else {
                    fileTypeIconView
                }
            }
            
            // OCR Button für Bilder (placeholder)
            if item.isImage && isHovered {
                VStack {
                    HStack {
                        Button(action: {
                            // TODO: OCR implementieren
                            print("🚧 OCR-Funktionalität wird implementiert")
                        }) {
                            Image(systemName: "text.viewfinder")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(.ultraThickMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.blue.opacity(0.5), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Text per OCR extrahieren (wird implementiert)")
                        
                        Spacer()
                    }
                    Spacer()
                }
                .padding(4)
            }
            
            // Dateityp-Indikator und Favorit
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 2) {
                        if item.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption2)
                        }
                        
                        Text(getFileTypeIndicator())
                            .font(.caption2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: getFileTypeColors(),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.ultraThickMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                    }
                }
                Spacer()
            }
            .padding(4)
        }
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .shadow(color: isSelected ? .accentColor.opacity(0.3) : .clear, radius: 8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture(count: 2, perform: onDoubleClick)
        .draggable(getDraggableContent()) {
            // Drag Preview
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                
                if item.isImage, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: item.fileTypeCategory.icon)
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: item.fileTypeCategory.colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        if item.isText, let text = item.textContent {
                            Text(String(text.prefix(10)) + (text.count > 10 ? "..." : ""))
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        } else if item.isURL, let urlString = item.urlString {
                            Text(URL(string: urlString)?.host ?? urlString)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        } else if let fileName = item.fileName {
                            Text(fileName)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .opacity(0.8)
        }
    }
    
    private func getDraggableContent() -> Data {
        if let imageData = item.imageData {
            return imageData
        } else if let text = item.textContent {
            return text.data(using: .utf8) ?? Data()
        }
        return Data()
    }
    
    // Neue kompakte Icon-Darstellung für alle Dateitypen
    private var fileTypeIconView: some View {
        VStack(spacing: 8) {
            ZStack {
                // Hintergrund-Kreis mit Farbverlauf
                Circle()
                    .fill(
                        LinearGradient(
                            colors: item.fileTypeCategory.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: item.fileTypeCategory.colors.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)
                
                // Icon
                Image(systemName: item.fileTypeCategory.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Dateiname oder Inhalt
            if item.isText, let text = item.textContent {
                Text(String(text.prefix(20)))
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
            } else if item.isURL, let urlString = item.urlString {
                Text(URL(string: urlString)?.host ?? urlString)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
            } else if let fileName = item.fileName {
                Text(fileName)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 4)
            } else {
                Text(getFileTypeIndicator())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(8)
    }
    
    private func getFileTypeIndicator() -> String {
        switch item.fileTypeCategory {
        case .image:
            switch item.contentType {
            case .png: return "PNG"
            case .jpeg: return "JPG"
            case .tiff: return "TIFF"
            case .heic: return "HEIC"
            default: return "Image"
            }
        case .text: return "Text"
        case .document: return "Document"
        case .pdf: return "PDF"
        case .video: return "Video"
        case .audio: return "Audio"
        case .archive: return "Archive"
        case .url: return "URL"
        case .other: return "File"
        }
    }
    
    private func getFileTypeColors() -> [Color] {
        return item.fileTypeCategory.colors
    }
}
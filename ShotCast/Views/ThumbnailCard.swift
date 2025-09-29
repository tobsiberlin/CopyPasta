import SwiftUI
import AppKit
import Vision

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
            RoundedRectangle(cornerRadius: 12) // Leicht abgerundet
                .fill(Color(NSColor.controlBackgroundColor)) // Vollständig opak
                .aspectRatio(1.0, contentMode: .fit) // Quadratisch
                .overlay(
                    RoundedRectangle(cornerRadius: 12) // Leicht abgerundet
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
                            .clipShape(RoundedRectangle(cornerRadius: 10)) // Leicht abgerundet, passend zur Card
                            .padding(6)
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
                            performOCR()
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
                        .help(String(localized: .ocrExtract))
                        
                        Spacer()
                    }
                    Spacer()
                }
                .padding(4)
            }
            
            // Source-Badge und Favorit (wie im Screenshot)
            VStack {
                HStack {
                    // Favorit-Icon links oben
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption2)
                            .background(
                                Circle()
                                    .fill(.ultraThickMaterial)
                                    .frame(width: 20, height: 20)
                            )
                    }
                    
                    Spacer()
                    
                    // App-Source-Badge rechts oben (Shottr "S", VS Code "</>", etc.)
                    if let sourceInfo = item.sourceInfo,
                       let sourceBadge = sourceInfo.badge {
                        Text(sourceBadge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .fill(sourceInfo.badgeColor)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                            .help("\(LocalizationManager.shared.localizedString(.sourceLabel)): \(sourceInfo.displayName)")
                    }
                }
                Spacer()
                
                // Dateityp-Indikator unten rechts
                HStack {
                    Spacer()
                    Text(getFileTypeIndicator())
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.6))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                }
            }
            .padding(4)
        }
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .shadow(color: isSelected ? .accentColor.opacity(0.3) : .clear, radius: 8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture(count: 2, perform: onDoubleClick)
        .onDrag {
            DragManager.shared.createItemProvider(for: item)
        }
    }
    
    // Süße Icon-Darstellung wie im Screenshot
    private var fileTypeIconView: some View {
        VStack(spacing: 6) {
            ZStack {
                // Süßer Hintergrund-Kreis mit Verlauf und Schatten
                Circle()
                    .fill(
                        LinearGradient(
                            colors: item.fileTypeCategory.colors.map { $0.opacity(0.9) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: item.fileTypeCategory.colors.first?.opacity(0.3) ?? .clear, radius: 6, x: 0, y: 3)
                
                // Süßes Icon mit besserer Typo
                Image(systemName: item.fileTypeCategory.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
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
        let locManager = LocalizationManager.shared
        switch item.fileTypeCategory {
        case .image:
            switch item.contentType {
            case .png: return "PNG"
            case .jpeg: return "JPG"
            case .tiff: return "TIFF"
            case .heic: return "HEIC"
            default: return locManager.localizedString(.fileTypeImage)
            }
        case .text: return locManager.localizedString(.fileTypeText)
        case .document: return locManager.localizedString(.fileTypeDocument)
        case .pdf: return locManager.localizedString(.fileTypePDF)
        case .video: return locManager.localizedString(.fileTypeVideo)
        case .audio: return locManager.localizedString(.fileTypeAudio)
        case .archive: return locManager.localizedString(.fileTypeArchive)
        case .url: return locManager.localizedString(.fileTypeURL)
        case .code: return locManager.localizedString(.fileTypeCode)
        case .other: return locManager.localizedString(.fileTypeOther)
        }
    }
    
    private func getFileTypeColors() -> [Color] {
        return item.fileTypeCategory.colors
    }
    
    private func performOCR() {
        guard item.isImage, let imageData = item.imageData else { return }
        
        OCRManager.shared.extractText(from: imageData, accuracy: .balanced) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ocrResult):
                    onOCRExtract?(ocrResult.text)
                    print("✅ OCR text recognized: \(ocrResult.text.prefix(50))... (Confidence: \(String(format: "%.1f%%", ocrResult.confidence * 100)), Language: \(ocrResult.detectedLanguage))")
                    
                    // Show success feedback (could be a toast notification)
                    // NotificationCenter.default.post(name: .ocrSuccess, object: ocrResult)
                    
                case .failure(let error):
                    print("❌ OCR error: \(error.localizedDescription)")
                    // Show error feedback
                    // NotificationCenter.default.post(name: .ocrError, object: error)
                }
            }
        }
    }
}
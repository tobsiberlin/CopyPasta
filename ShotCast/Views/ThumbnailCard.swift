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
            // Paste-ähnlicher sauberer Hintergrund
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white) // Komplett weiß wie bei Paste
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
            
            // Saubere Bild-Darstellung wie bei Paste
            Group {
                if item.isImage {
                    if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 6)) // Weniger abgerundet
                            .padding(3) // Minimales Padding
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
            
            // Sichtbare Source-Badges und Info wie bei Paste
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    // Favorit-Icon links oben
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                            .padding(2)
                            .background(Circle().fill(.white).shadow(radius: 1))
                    }
                    
                    Spacer()
                    
                    // App-Source-Badge rechts oben - IMMER SICHTBAR
                    if let sourceInfo = item.sourceInfo,
                       let sourceBadge = sourceInfo.badge {
                        Text(sourceBadge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(
                                Circle()
                                    .fill(Color.red) // Wie bei Paste - roter Kreis
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                
                Spacer()
                
                // Dateityp-Badge unten links wie bei Paste
                HStack {
                    Text(getFileTypeIndicator())
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.9))
                                .shadow(radius: 1)
                        )
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
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

        OCRManager.shared.extractText(from: imageData, accuracy: OCRManager.OCRAccuracy.balanced) { result in
            switch result {
            case .success(let ocrResult):
                DispatchQueue.main.async {
                    onOCRExtract?(ocrResult.text)
                    print("✅ OCR text recognized: \(ocrResult.text.prefix(50))... (Confidence: \(String(format: "%.1f%%", ocrResult.confidence * 100)), Language: \(ocrResult.detectedLanguage))")

                    // Show success feedback (could be a toast notification)
                    // NotificationCenter.default.post(name: .ocrSuccess, object: ocrResult)
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    print("❌ OCR error: \(error.localizedDescription)")
                    // Show error feedback
                    // NotificationCenter.default.post(name: .ocrError, object: error)
                }
            }
        }
    }
}
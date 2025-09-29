import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BottomBarView: View {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedItem: ClipboardItem?
    @State private var hoveredItemID: UUID?
    
    var filteredItems: [ClipboardItem] {
        let items = pasteboardWatcher.clipboardItems
        if settings.maxItems == -1 || settings.maxItems > 999 {
            return items
        }
        return Array(items.prefix(settings.maxItems))
    }
    
    private var preferredColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var body: some View {
        // EXAKT WIE PASTE - sauber und minimalistisch
        if filteredItems.isEmpty {
            emptyStateView
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) { // Sehr enger Abstand
                    ForEach(filteredItems) { item in
                        pasteStyleCard(item: item)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }
    
    private func pasteStyleCard(item: ClipboardItem) -> some View {
        ZStack {
            // Weißer Hintergrund mit Schatten
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 68, height: 68)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedItem?.id == item.id ? Color.blue : Color.clear, lineWidth: 2)
                )
            
            // Inhalt
            if item.isImage, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: item.fileTypeCategory.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    
                    Text(fileTypeText(for: item))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Source Badge
            VStack {
                HStack {
                    Spacer()
                    if let sourceInfo = item.sourceInfo, let badge = sourceInfo.badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.red))
                            .offset(x: 6, y: -6)
                    }
                }
                Spacer()
            }
        }
        .onTapGesture {
            selectedItem = item
            copyItemToPasteboard(item)
        }
        .onHover { isHovered in
            hoveredItemID = isHovered ? item.id : nil
        }
        .contextMenu {
            contextMenu(for: item)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 24))
                .foregroundColor(.gray)
            
            Text(localizationManager.localizedString(.emptyClipboard))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(height: 80)
    }
    
    private func fileTypeText(for item: ClipboardItem) -> String {
        switch item.fileTypeCategory {
        case .image: return "IMG"
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
    
    private func copyItemToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if let imageData = item.imageData {
            pasteboard.setData(imageData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        } else if let textContent = item.textContent {
            pasteboard.setString(textContent, forType: .string)
        }
        
        selectedItem = item
        NSSound.beep()
    }
    
    private func contextMenu(for item: ClipboardItem) -> some View {
        Group {
            Button(localizationManager.localizedString(.contextCopy)) {
                copyItemToPasteboard(item)
            }
            
            Button(item.isFavorite ? localizationManager.localizedString(.contextUnfavorite) : localizationManager.localizedString(.contextFavorite)) {
                pasteboardWatcher.toggleFavorite(item)
            }
            
            Divider()
            
            Button(localizationManager.localizedString(.contextDelete)) {
                pasteboardWatcher.deleteItem(item)
            }
        }
    }
}
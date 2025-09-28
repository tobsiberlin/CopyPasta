import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Paste-Style Bottom Bar Hauptansicht
// Paste-style bottom bar main view
struct BottomBarView: View {
    @EnvironmentObject var pasteboardWatcher: PasteboardWatcher
    @EnvironmentObject var windowManager: WindowManager
    @StateObject private var settings = AppSettings.shared
    
    @State private var selectedItem: ClipboardItem?
    @State private var hoveredItemID: UUID?
    @State private var showingSettings = false
    
    // Gefilterte Items basierend auf Limit
    // Filtered items based on limit
    var filteredItems: [ClipboardItem] {
        let items = pasteboardWatcher.clipboardItems
        if settings.maxItems == -1 || settings.maxItems > 999 {
            return items
        }
        return Array(items.prefix(settings.maxItems))
    }
    
    var body: some View {
        ZStack {
            // Moderner Transparenz-Hintergrund
            // Modern transparency background
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(settings.cornerRadius)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            
            HStack(spacing: 0) {
                // Settings-Button links
                // Settings button left
                settingsButton
                    .padding(.leading, 16)
                
                // Horizontale Scroll-Leiste mit Items
                // Horizontal scroll bar with items
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    itemScrollView
                }
                
                // Resize-Handle rechts
                // Resize handle right
                resizeHandle
                    .padding(.trailing, 8)
            }
        }
        .frame(height: settings.barHeight)
        .opacity(settings.barOpacity)
        .onHover { isHovered in
            if isHovered {
                windowManager.handleMouseEntered()
            } else {
                windowManager.handleMouseExited()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // Settings-Button
    private var settingsButton: some View {
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help("Einstellungen")
    }
    
    // Item Scroll View
    private var itemScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: settings.itemSpacing) {
                ForEach(filteredItems) { item in
                    ModernThumbnailCard(
                        item: item,
                        isSelected: selectedItem?.id == item.id,
                        isHovered: hoveredItemID == item.id,
                        cornerRadius: settings.cornerRadius
                    )
                    .frame(height: settings.barHeight - 20)
                    .aspectRatio(1.0, contentMode: .fit)
                    .onTapGesture {
                        selectedItem = item
                        copyItemToPasteboard(item)
                    }
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredItemID = isHovered ? item.id : nil
                        }
                    }
                    .contextMenu {
                        itemContextMenu(for: item)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .clipped()
    }
    
    // Empty State
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Keine Bilder im Clipboard")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
    
    // Resize Handle
    private var resizeHandle: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 3, height: 20)
            .cornerRadius(1.5)
            .onTapGesture(count: 2) {
                // Doppelklick zum Zurücksetzen
                // Double click to reset
                settings.barHeight = 120
                windowManager.updateWindowFrame()
            }
            .onHover { isHovered in
                if isHovered {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .help("Größe anpassen")
    }
    
    // Kontextmenü für Items
    // Context menu for items
    private func itemContextMenu(for item: ClipboardItem) -> some View {
        Group {
            Button("Kopieren") {
                copyItemToPasteboard(item)
            }
            
            Button(item.isFavorite ? "Aus Favoriten" : "Zu Favoriten") {
                pasteboardWatcher.toggleFavorite(item)
            }
            
            Divider()
            
            Button("Als Datei speichern...") {
                saveItemToFile(item)
            }
            
            Divider()
            
            Button("Löschen") {
                pasteboardWatcher.deleteItem(item)
            }
        }
    }
    
    // Item in Zwischenablage kopieren
    // Copy item to clipboard
    private func copyItemToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(item.imageData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        
        // Visuelles Feedback
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedItem = item
        }
        
        // Sound Feedback
        NSSound.beep()
    }
    
    // Item als Datei speichern
    // Save item as file
    private func saveItemToFile(_ item: ClipboardItem) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [item.contentType]
        savePanel.nameFieldStringValue = "CopyPasta_\(Int(item.timestamp.timeIntervalSince1970))"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? item.imageData.write(to: url)
            }
        }
    }
}
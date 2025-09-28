import SwiftUI
import AppKit

// Hauptansicht mit Paste-inspiriertem Grid Layout
// Main view with Paste-inspired grid layout
struct MainContentView: View {
    @EnvironmentObject var pasteboardWatcher: PasteboardWatcher
    @EnvironmentObject var windowManager: WindowManager
    @State private var searchText = ""
    @State private var selectedItem: ClipboardItem?
    @State private var hoveredItemID: UUID?
    @State private var showingPreview = false
    @State private var gridColumns = 4
    @State private var previewItem: ClipboardItem?
    
    // Gefilterte Items basierend auf Suche
    // Filtered items based on search
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return pasteboardWatcher.clipboardItems
        }
        return pasteboardWatcher.clipboardItems.filter { item in
            // Suche in Zeitstempel und Metadaten
            // Search in timestamp and metadata
            item.formattedDate.localizedCaseInsensitiveContains(searchText) ||
            (item.source.deviceName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    // Dynamische Grid-Spalten wie in Paste
    // Dynamic grid columns like in Paste
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: gridColumns)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header mit Suchleiste
            // Header with search bar
            headerView
                .padding()
                .background(Material.ultraThin)
            
            Divider()
            
            // Grid mit Clipboard-Items
            // Grid with clipboard items
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                gridView
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: .focusNewClipboardItem)) { _ in
            // Fokussiere neues Item
            // Focus new item
            if let firstItem = pasteboardWatcher.clipboardItems.first {
                selectedItem = firstItem
                withAnimation(.spring()) {
                    hoveredItemID = firstItem.id
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            if let previewItem = previewItem {
                PreviewView(item: previewItem, isPresented: $showingPreview)
            }
        }
        .onKeyboardShortcut(.return, modifiers: .command) {
            // Cmd+Return: Paste selected item
            if let selected = selectedItem {
                copyItemToPasteboard(selected)
            }
        }
        .onKeyboardShortcut(.delete) {
            // Delete: Remove selected item
            if let selected = selectedItem {
                pasteboardWatcher.deleteItem(selected)
                selectedItem = nil
            }
        }
        .onKeyboardShortcut(.space) {
            // Space: Preview selected item
            if let selected = selectedItem {
                previewItem = selected
                showingPreview = true
            }
        }
        .onKeyboardShortcut(KeyEquivalent("f"), modifiers: .command) {
            // Cmd+F: Toggle favorite
            if let selected = selectedItem {
                pasteboardWatcher.toggleFavorite(selected)
            }
        }
    }
    
    // Header-Bereich
    // Header area
    private var headerView: some View {
        HStack(spacing: 16) {
            // Such-Icon und Feld
            // Search icon and field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Suchen...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Aktions-Buttons
            // Action buttons
            HStack(spacing: 8) {
                // Grid-Größe
                // Grid size
                Menu {
                    ForEach(2...6, id: \.self) { count in
                        Button("\(count) Spalten") {
                            withAnimation {
                                gridColumns = count
                            }
                        }
                    }
                } label: {
                    Image(systemName: "square.grid.3x3")
                        .symbolRenderingMode(.hierarchical)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 30)
                
                // Alle löschen
                // Clear all
                Button(action: {
                    pasteboardWatcher.clearAll()
                }) {
                    Image(systemName: "trash")
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .disabled(pasteboardWatcher.clipboardItems.isEmpty)
            }
        }
    }
    
    // Grid-Ansicht
    // Grid view
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredItems) { item in
                    ThumbnailCard(
                        item: item,
                        isSelected: selectedItem?.id == item.id,
                        isHovered: hoveredItemID == item.id
                    )
                    .onTapGesture {
                        selectedItem = item
                    }
                    .onTapGesture(count: 2) {
                        previewItem = item
                        showingPreview = true
                    }
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredItemID = isHovered ? item.id : nil
                        }
                    }
                    .contextMenu {
                        itemContextMenu(for: item)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .padding()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: filteredItems)
    }
    
    // Leerer Zustand
    // Empty state
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "photo.on.rectangle.angled" : "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "Keine Bilder im Clipboard" : "Keine Ergebnisse")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Text("Kopiere ein Bild auf deinem iPhone oder Mac")
                    .font(.callout)
                    .foregroundColor(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // Kontextmenü für Items
    // Context menu for items
    private func itemContextMenu(for item: ClipboardItem) -> some View {
        Group {
            Button(action: {
                copyItemToPasteboard(item)
            }) {
                Label("Kopieren", systemImage: "doc.on.clipboard")
            }
            
            Button(action: {
                pasteboardWatcher.toggleFavorite(item)
            }) {
                Label(item.isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten", 
                      systemImage: item.isFavorite ? "star.fill" : "star")
            }
            
            Divider()
            
            Button(action: {
                saveItemToFile(item)
            }) {
                Label("Als Datei speichern...", systemImage: "square.and.arrow.down")
            }
            
            Divider()
            
            Button(action: {
                pasteboardWatcher.deleteItem(item)
            }) {
                Label("Löschen", systemImage: "trash")
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
    }
    
    // Item als Datei speichern
    // Save item as file
    private func saveItemToFile(_ item: ClipboardItem) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [item.contentType]
        savePanel.nameFieldStringValue = "CopyPasta_\(item.timestamp.timeIntervalSince1970)"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? item.imageData.write(to: url)
            }
        }
    }
}

// Erweiterung für ClipboardSource Device Name
// Extension for ClipboardSource device name
extension ClipboardItem.ClipboardSource {
    var deviceName: String? {
        switch self {
        case .universalClipboard(let name):
            return name
        default:
            return nil
        }
    }
}
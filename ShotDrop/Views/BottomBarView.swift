import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BottomBarView: View {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var windowManager = WindowManager.shared
    @StateObject private var settings = AppSettings.shared
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
    
    private var backgroundGradient: LinearGradient {
        switch settings.themeMode {
        case .light:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color.purple.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .system:
            return colorScheme == .dark ? 
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.9),
                        Color.purple.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.95),
                        Color.blue.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
        }
    }
    
    private var accentGradient: LinearGradient {
        switch settings.themeMode {
        case .light:
            return LinearGradient(
                colors: [.blue, .cyan, .green],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .dark:
            return LinearGradient(
                colors: [.purple, .pink, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .system:
            return colorScheme == .dark ? 
                LinearGradient(
                    colors: [.purple, .pink, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [.blue, .cyan, .green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                resizeArea
                    .frame(height: 8)
                
                mainContent
            }
            .background(
                ZStack {
                    backgroundGradient
                    
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        .opacity(0.4)
                    
                    VStack {
                        Rectangle()
                            .fill(accentGradient)
                            .frame(height: 3)
                            .shadow(color: .accentColor.opacity(0.5), radius: 4, x: 0, y: 2)
                        Spacer()
                    }
                    
                    particleOverlay
                }
                .cornerRadius(settings.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: settings.cornerRadius)
                        .stroke(accentGradient, lineWidth: 1.5)
                        .opacity(0.6)
                )
                .shadow(color: .accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
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
        .preferredColorScheme(preferredColorScheme)
    }
    
    private var particleOverlay: some View {
        HStack(spacing: 40) {
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(accentGradient)
                    .frame(width: 2, height: 2)
                    .opacity(0.6)
                    .scaleEffect(hoveredItemID != nil ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: hoveredItemID)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 10)
        .padding(.trailing, 30)
    }
    
    private var preferredColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    private var resizeArea: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = max(60, min(200, settings.barHeight - value.translation.height))
                        settings.barHeight = newHeight
                        windowManager.updateWindowFrame()
                    }
            )
            .onHover { isHovered in
                if isHovered {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
    
    private var mainContent: some View {
        HStack(spacing: 0) {
            settingsButton
                .padding(.leading, 16)
            
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                itemScrollView
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                SettingsWindowManager.shared.showSettingsWindow()
            }
        }) {
            Image(systemName: "gear")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(accentGradient)
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        Circle()
                            .fill(backgroundGradient)
                            .opacity(0.8)
                        
                        Circle()
                            .stroke(accentGradient, lineWidth: 2)
                            .opacity(0.8)
                        
                        Circle()
                            .fill(accentGradient)
                            .opacity(0.1)
                            .scaleEffect(0.7)
                    }
                )
                .scaleEffect(hoveredItemID?.uuidString == "settings-button" ? 1.2 : 1.0)
                .shadow(color: .accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .help("ShotDrop Einstellungen")
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.3)) {
                if isHovered {
                    hoveredItemID = UUID(uuidString: "12345678-1234-1234-1234-123456789abc")
                } else {
                    hoveredItemID = nil
                }
            }
        }
    }
    
    private var itemScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            itemsStack
        }
        .clipped()
    }
    
    private var itemsStack: some View {
        LazyHStack(spacing: settings.itemSpacing) {
            ForEach(filteredItems) { item in
                itemCard(item: item)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func itemCard(item: ClipboardItem) -> some View {
        ThumbnailCard(
            item: item,
            isSelected: selectedItem?.id == item.id,
            isHovered: hoveredItemID == item.id
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
    
    private func copyItemToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(item.imageData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedItem = item
        }
        
        NSSound.beep()
    }
    
    private func saveItemToFile(_ item: ClipboardItem) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [item.contentType]
        savePanel.nameFieldStringValue = "ShotDrop_\(Int(item.timestamp.timeIntervalSince1970))"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? item.imageData.write(to: url)
            }
        }
    }
}
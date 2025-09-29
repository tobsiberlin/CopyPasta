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
    @State private var showingToast = false
    @State private var toastMessage = ""
    
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
                    Color.white.opacity(0.98),
                    Color(red: 0.98, green: 0.99, blue: 1.0).opacity(0.95),
                    Color(red: 0.96, green: 0.98, blue: 1.0).opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.9),
                    Color.blue.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .system:
            return colorScheme == .dark ? 
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.9),
                        Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.9),
                        Color.blue.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.98),
                        Color(red: 0.98, green: 0.99, blue: 1.0).opacity(0.95),
                        Color(red: 0.96, green: 0.98, blue: 1.0).opacity(0.9)
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
                colors: [
                    Color(red: 0.2, green: 0.6, blue: 1.0),
                    Color(red: 0.4, green: 0.8, blue: 1.0),
                    Color(red: 0.6, green: 0.9, blue: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.8),
                    Color(red: 0.3, green: 0.6, blue: 1.0),
                    Color(red: 0.5, green: 0.8, blue: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .system:
            return colorScheme == .dark ? 
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.4, blue: 0.8),
                        Color(red: 0.3, green: 0.6, blue: 1.0),
                        Color(red: 0.5, green: 0.8, blue: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.6, blue: 1.0),
                        Color(red: 0.4, green: 0.8, blue: 1.0),
                        Color(red: 0.6, green: 0.9, blue: 1.0)
                    ],
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
            
            // Toast Overlay
            if showingToast {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kopiert!")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(toastMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThickMaterial)
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [.green.opacity(0.5), .mint.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showingToast = false
                            }
                        }
                    }
                }
                .allowsHitTesting(false)
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
        HStack(spacing: 0) {
            // Links-Resize für Breite
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 20)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            windowManager.resizeWindowHorizontally(delta: -value.translation.width)
                        }
                )
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            
            // Mitte-Resize für Höhe
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
            
            // Rechts-Resize für Breite
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 20)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            windowManager.resizeWindowHorizontally(delta: value.translation.width)
                        }
                )
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
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
            
            closeButton
                .padding(.trailing, 16)
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                SettingsWindowManager.shared.showSettingsWindow()
            }
        }) {
            Image(systemName: "slider.horizontal.3")
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
        .help("ShotCast Einstellungen")
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
    
    private var closeButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                windowManager.hideWindow()
            }
        }) {
            Image(systemName: "power")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: 40, height: 40)
                .background(
                    ZStack {
                        Circle()
                            .fill(backgroundGradient)
                            .opacity(0.8)
                        
                        Circle()
                            .stroke(LinearGradient(
                                colors: [.red.opacity(0.6), .orange.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ), lineWidth: 2)
                            .opacity(0.8)
                        
                        Circle()
                            .fill(LinearGradient(
                                colors: [.red.opacity(0.1), .orange.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .scaleEffect(0.7)
                    }
                )
                .scaleEffect(hoveredItemID?.uuidString == "close-button" ? 1.2 : 1.0)
                .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .help("ShotCast schließen")
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.3)) {
                if isHovered {
                    hoveredItemID = UUID(uuidString: "12345678-1234-1234-1234-123456789def")
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
            isHovered: hoveredItemID == item.id,
            onDoubleClick: {
                handleDoubleClick(item: item)
            }
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
            
            Text("Keine Inhalte im Clipboard")
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
        
        if let imageData = item.imageData {
            pasteboard.setData(imageData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        } else if let textContent = item.textContent {
            pasteboard.setString(textContent, forType: .string)
            // Zeige Toast für Text
            toastMessage = "Text wurde in die Zwischenablage kopiert und kann jetzt in Tools eingefügt werden"
            showingToast = true
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedItem = item
        }
        
        NSSound.beep()
    }
    
    private func saveItemToFile(_ item: ClipboardItem) {
        let savePanel = NSSavePanel()
        
        if item.isImage {
            savePanel.allowedContentTypes = [item.contentType]
            savePanel.nameFieldStringValue = "ShotCast_\(Int(item.timestamp.timeIntervalSince1970))"
            
            savePanel.begin { result in
                if result == .OK, let url = savePanel.url, let imageData = item.imageData {
                    try? imageData.write(to: url)
                }
            }
        } else if item.isText {
            savePanel.allowedContentTypes = [.plainText]
            savePanel.nameFieldStringValue = "ShotCast_Text_\(Int(item.timestamp.timeIntervalSince1970)).txt"
            
            savePanel.begin { result in
                if result == .OK, let url = savePanel.url, let textContent = item.textContent {
                    try? textContent.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        }
    }
    
    private func handleDoubleClick(item: ClipboardItem) {
        if item.isImage, let imageData = item.imageData {
            // Öffne Bild in Preview
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ShotCast_\(UUID().uuidString).png")
            
            do {
                try imageData.write(to: tempURL)
                NSWorkspace.shared.open(tempURL)
                
                // Lösche die temporäre Datei nach 10 Sekunden
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    try? FileManager.default.removeItem(at: tempURL)
                }
            } catch {
                print("Fehler beim Öffnen des Bildes: \(error)")
            }
        } else if item.isText, let textContent = item.textContent {
            // Öffne Text in TextEdit
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ShotCast_\(UUID().uuidString).txt")
            
            do {
                try textContent.write(to: tempURL, atomically: true, encoding: .utf8)
                NSWorkspace.shared.open(tempURL)
                
                // Lösche die temporäre Datei nach 10 Sekunden
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    try? FileManager.default.removeItem(at: tempURL)
                }
            } catch {
                print("Fehler beim Öffnen des Textes: \(error)")
            }
        }
    }
    
}
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BottomBarView: View {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var windowManager = WindowManager.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var localizationManager = LocalizationManager.shared
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
    
    private var glassBackground: some View {
        ZStack {
            // Base blur layer with enhanced material
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .opacity(0.95)
            
            // Colorful gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.08),
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Ambient light effect
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.1),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 50,
                endRadius: 300
            )
            
            // Enhanced border with color
            RoundedRectangle(cornerRadius: settings.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.3),
                            Color.purple.opacity(0.2),
                            Color.blue.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
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
            // Simple clean design like Paste
            if filteredItems.isEmpty {
                emptyStateView
                    .frame(height: settings.barHeight)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) { // Fester Abstand wie bei Paste
                        ForEach(filteredItems) { item in
                            itemCard(item: item)
                        }
                    }
                    .padding(.horizontal, 12) // Weniger Padding
                    .padding(.vertical, 8) // Minimal padding
                }
                .frame(height: settings.barHeight)
                .background(
                    // Paste-ähnlicher sauberer Hintergrund
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
            }
            
            // Resize handles (invisible overlays)
            VStack(spacing: 0) {
                // Top resize
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 8)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newHeight = max(60, min(120, settings.barHeight - value.translation.height))
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
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                // Left resize  
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 8)
                    .contentShape(Rectangle())
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
                
                Spacer()
                
                // Right resize
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 8)
                    .contentShape(Rectangle())
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
                            Text(localizationManager.localizedString(.copied))
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
    
    private var windowDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                windowManager.updateDragPosition(delta: NSPoint(x: value.translation.width, y: -value.translation.height))
            }
            .onEnded { _ in
                windowManager.endDragging()
            }
    }
    
    // Removed - now integrated into main body
    
    private var topControlBar: some View {
        HStack {
            // Settings button in top left
            settingsButton
                .padding(.leading, 12)
            
            Spacer()
            
            // Close button in top right
            closeButton
                .padding(.trailing, 12)
        }
        .padding(.vertical, 4)
    }
    
    private var mainContent: some View {
        HStack(spacing: 0) {
            resizeIndicator
                .padding(.leading, 12)
            
            // Center content with drag handle
            ZStack {
                // Drag handle background
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(windowDragGesture)
                
                // Content
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    itemScrollView
                }
            }
            
            Spacer()
                .frame(width: dynamicPadding)
        }
    }
    
    private var resizeIndicator: some View {
        VStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 3, height: 3)
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                SettingsWindowManager.shared.showSettingsWindow()
            }
        }) {
            Image(systemName: "gearshape")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(hoveredItemID?.uuidString == "settings-button" ? 1.1 : 1.0)
                .opacity(hoveredItemID?.uuidString == "settings-button" ? 0.8 : 0.6)
        }
        .buttonStyle(.plain)
        .help(localizationManager.localizedString(.helpSettings))
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
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(hoveredItemID?.uuidString == "close-button" ? 1.1 : 1.0)
                .opacity(hoveredItemID?.uuidString == "close-button" ? 0.8 : 0.5)
        }
        .buttonStyle(.plain)
        .help(localizationManager.localizedString(.helpClose))
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
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                itemsStack
            }
            .clipped()
            .overlay(alignment: .trailing) {
                // Right-side scroll trigger area
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50)
                    .contentShape(Rectangle())
                    .onHover { isHovered in
                        if isHovered && filteredItems.count > 3 {
                            // Scroll to the right (showing older items)
                            if let lastItem = filteredItems.last {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    proxy.scrollTo(lastItem.id, anchor: .trailing)
                                }
                            }
                        }
                    }
            }
            .overlay(alignment: .leading) {
                // Left-side scroll trigger area (back to newest)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 50)
                    .contentShape(Rectangle())
                    .onHover { isHovered in
                        if isHovered && filteredItems.count > 3 {
                            // Scroll to the left (showing newest items)
                            if let firstItem = filteredItems.first {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    proxy.scrollTo(firstItem.id, anchor: .leading)
                                }
                            }
                        }
                    }
            }
        }
    }
    
    private var itemsStack: some View {
        LazyHStack(spacing: dynamicItemSpacing) {
            ForEach(filteredItems) { item in
                itemCard(item: item)
            }
        }
        .padding(.horizontal, dynamicPadding)
        .padding(.vertical, dynamicVerticalPadding)
    }
    
    // Dynamic padding based on bar height
    private var dynamicPadding: CGFloat {
        let ratio = settings.barHeight / 120.0 // 120 is default height
        return max(8, 16 * ratio)
    }
    
    private var dynamicVerticalPadding: CGFloat {
        let ratio = settings.barHeight / 120.0
        return max(5, 10 * ratio)
    }
    
    private var dynamicItemSpacing: CGFloat {
        let ratio = settings.barHeight / 120.0
        return max(6, settings.itemSpacing * ratio)
    }
    
    private func itemCard(item: ClipboardItem) -> some View {
        ThumbnailCard(
            item: item,
            isSelected: selectedItem?.id == item.id,
            isHovered: hoveredItemID == item.id,
            onDoubleClick: {
                handleDoubleClick(item: item)
            },
            onOCRExtract: { extractedText in
                showOCRToast(with: extractedText)
            }
        )
        .frame(width: settings.barHeight - 16, height: settings.barHeight - 16) // Quadratisch wie bei Paste
        .onTapGesture {
            selectedItem = item
            copyItemToPasteboard(item)
        }
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
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
            
            Text(localizationManager.localizedString(.emptyClipboard))
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
    
    private func itemContextMenu(for item: ClipboardItem) -> some View {
        Group {
            Button(localizationManager.localizedString(.contextCopy)) {
                copyItemToPasteboard(item)
            }
            
            Button(item.isFavorite ? localizationManager.localizedString(.contextUnfavorite) : localizationManager.localizedString(.contextFavorite)) {
                pasteboardWatcher.toggleFavorite(item)
            }
            
            Divider()
            
            Button(localizationManager.localizedString(.contextSaveAsFile)) {
                saveItemToFile(item)
            }
            
            Divider()
            
            Button(localizationManager.localizedString(.contextDelete)) {
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
            toastMessage = localizationManager.localizedString(.copyText)
            showingToast = true
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedItem = item
        }
        
        NSSound.beep()
    }
    
    private func saveItemToFile(_ item: ClipboardItem) {
        // Ensure we're on the main thread for UI operations
        DispatchQueue.main.async {
            let savePanel = NSSavePanel()
            
            if item.isImage {
                savePanel.allowedContentTypes = [item.contentType]
                savePanel.nameFieldStringValue = "ShotCast_\(Int(item.timestamp.timeIntervalSince1970))"
                
                savePanel.begin { result in
                    if result == .OK, let url = savePanel.url, let imageData = item.imageData {
                        do {
                            try imageData.write(to: url)
                            self.toastMessage = self.localizationManager.localizedString(.copied)
                            self.showingToast = true
                        } catch {
                            print("Error saving image: \(error)")
                        }
                    }
                }
            } else if item.isText {
                savePanel.allowedContentTypes = [.plainText]
                savePanel.nameFieldStringValue = "ShotCast_Text_\(Int(item.timestamp.timeIntervalSince1970)).txt"
                
                savePanel.begin { result in
                    if result == .OK, let url = savePanel.url, let textContent = item.textContent {
                        do {
                            try textContent.write(to: url, atomically: true, encoding: .utf8)
                            self.toastMessage = self.localizationManager.localizedString(.copied)
                            self.showingToast = true
                        } catch {
                            print("Error saving text: \(error)")
                        }
                    }
                }
            } else {
                // Handle other file types (like files copied to clipboard)
                if let data = item.fileData {
                    savePanel.allowedContentTypes = [item.contentType]
                    let fileExtension = item.contentType.preferredFilenameExtension ?? "file"
                    savePanel.nameFieldStringValue = "ShotCast_\(Int(item.timestamp.timeIntervalSince1970)).\(fileExtension)"
                    
                    savePanel.begin { result in
                        if result == .OK, let url = savePanel.url {
                            do {
                                try data.write(to: url)
                                self.toastMessage = self.localizationManager.localizedString(.copied)
                                self.showingToast = true
                            } catch {
                                print("Error saving file: \(error)")
                            }
                        }
                    }
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
                print("Error opening image: \(error)")
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
                print("Error opening text: \(error)")
            }
        }
    }
    
    private func showOCRToast(with text: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            toastMessage = localizationManager.localizedString(.ocrSuccess) + ": \(String(text.prefix(50)))\(text.count > 50 ? "..." : "")"
            showingToast = true
        }
    }
    
}
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Vision

struct BottomBarView: View {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var windowManager = WindowManager.shared
    @Environment(\.colorScheme) var colorScheme


    @State private var selectedItem: ClipboardItem?
    @State private var hoveredItemID: UUID?
    @State private var draggedItem: ClipboardItem?
    @State private var showFavorites = false
    @State private var isDraggingWindow = false
    @State private var isResizing = false
    @State private var dragStartPoint: CGPoint = .zero

    // Gefilterte Items
    var favoriteItems: [ClipboardItem] {
        pasteboardWatcher.clipboardItems.filter { $0.isFavorite }
    }

    var recentItems: [ClipboardItem] {
        // ZEIGE ALLE ITEMS in normaler Ansicht (auch Favoriten!)
        let items = pasteboardWatcher.clipboardItems
        if settings.maxItems == -1 || settings.maxItems > 999 {
            return items
        }
        return Array(items.prefix(settings.maxItems))
    }

    // Alle Items für Anzeige
    var displayItems: [ClipboardItem] {
        if showFavorites && !favoriteItems.isEmpty {
            return favoriteItems
        } else {
            return recentItems
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Control Bar
            topControlBar
                .frame(height: 50)
                .zIndex(100)

            // Favoriten Toggle (nur wenn Favoriten vorhanden)
            if !favoriteItems.isEmpty {
                favoritesToggleBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }

            // Main Content Area
            if displayItems.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(displayItems) { item in
                            itemCard(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(modernBackground)
        .opacity(settings.barOpacity)
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            setupListeners()
        }
    }

    // MARK: - Top Control Bar
    private var topControlBar: some View {
        HStack(spacing: 12) {
            // Left Resize Handle
            resizeHandle(direction: .left)

            // Settings Button
            Button(action: {
                openSettingsWithFocus()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)

            Spacer()

            // FUNKTIONIERENDER DRAG HANDLE
            dragHandle

            Spacer()

            // Close Button
            Button(action: {
                windowManager.hideWindow()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)

            // Right Resize Handle
            resizeHandle(direction: .right)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - FUNKTIONIERENDER Drag Handle
    private var dragHandle: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { _ in
                Circle()
                    .fill(isDraggingWindow ? Color.accentColor : Color.secondary.opacity(0.4))
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(isDraggingWindow ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isDraggingWindow ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDraggingWindow)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDraggingWindow {
                        isDraggingWindow = true
                        dragStartPoint = value.startLocation
                    }

                    // Direkte Bewegung ohne Verzögerung
                    let deltaX = value.translation.width - (dragStartPoint.x - value.startLocation.x)
                    let deltaY = -(value.translation.height - (dragStartPoint.y - value.startLocation.y)) // macOS Koordinaten

                    windowManager.updateDragPosition(delta: NSPoint(x: deltaX, y: deltaY))

                    // Update für nächsten Frame
                    dragStartPoint = CGPoint(x: value.location.x, y: value.location.y)
                }
                .onEnded { _ in
                    isDraggingWindow = false
                    windowManager.endDragging()
                }
        )
    }

    // MARK: - Favorites Toggle Bar
    private var favoritesToggleBar: some View {
        HStack(spacing: 12) {
            // Zwischenablage Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFavorites = false
                }
            }) {
                Label("Zwischenablage", systemImage: "doc.on.clipboard")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(!showFavorites ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(!showFavorites ? Color.accentColor : Color.clear)
                    )
            }
            .buttonStyle(.plain)

            // Favoriten Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showFavorites = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.red)
                    Text("Favoriten")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(showFavorites ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(showFavorites ? Color.red : Color.clear)
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Item Card
    private func itemCard(item: ClipboardItem) -> some View {
        VStack(spacing: 6) {
            // Header mit SÜSSEN App Icon und Favoriten-Stern
            HStack(spacing: 8) {
                // SÜSSES App Icon - IMMER sichtbar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.1), radius: 2)

                    if let sourceInfo = item.sourceInfo {
                        appOrDeviceIcon(for: sourceInfo)
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: "app.badge")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                // SÜSSER Dateitype-Icon - IMMER sichtbar
                ZStack {
                    Circle()
                        .fill(item.fileTypeCategory.color.opacity(0.2))
                        .frame(width: 20, height: 20)

                    Image(systemName: item.fileTypeCategory.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(item.fileTypeCategory.color)
                }

                // FAVORITEN STERN - mit korrekter Logik
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pasteboardWatcher.toggleFavorite(item)
                    }
                }) {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(item.isFavorite ? .yellow : .secondary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .opacity(hoveredItemID == item.id ? 1 : 0.3)
                        )
                }
                .buttonStyle(.plain)
            }

            // Content Preview
            contentView(for: item)
                .frame(width: settings.screenshotSize, height: settings.screenshotSize)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    // MARKIERUNGSRAHMEN
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedItem?.id == item.id ? Color.accentColor : Color.clear, lineWidth: 3)
                )

            // Footer - DATEINAME IMMER sichtbar und süß
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    // Mini Dateitype-Icon
                    Image(systemName: item.fileTypeCategory.icon)
                        .font(.system(size: 8))
                        .foregroundColor(item.fileTypeCategory.color)

                    Text(getDisplayName(for: item))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Text(getTimeLabel(for: item))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(width: settings.screenshotSize, alignment: .leading)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(hoveredItemID == item.id ? 0.15 : 0.08),
                       radius: hoveredItemID == item.id ? 8 : 4)
        )
        .scaleEffect(hoveredItemID == item.id ? 1.02 : 1.0)
        .scaleEffect(draggedItem?.id == item.id ? 0.95 : 1.0)
        .opacity(draggedItem?.id == item.id ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: hoveredItemID)
        .animation(.easeInOut(duration: 0.15), value: draggedItem?.id)
        .onTapGesture {
            selectItem(item)
        }
        .onHover { isHovered in
            hoveredItemID = isHovered ? item.id : nil
        }
        .contextMenu {
            contextMenu(for: item)
        }
        // DRAG & DROP
        .onDrag {
            draggedItem = item
            return createItemProvider(for: item)
        }
    }

    // MARK: - App/Device Icon
    private func appOrDeviceIcon(for sourceInfo: SourceDetector.SourceInfo) -> some View {
        Group {
            if case .universalClipboard(let deviceType) = sourceInfo.source {
                // iPhone/iPad spezifische Icons
                Image(systemName: deviceType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            } else if let bundleId = sourceInfo.bundleIdentifier,
                      let appIcon = getAppIcon(bundleId: bundleId) {
                // Echtes App Icon
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Fallback
                Image(systemName: sourceInfo.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Content View
    private func contentView(for item: ClipboardItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.controlBackgroundColor))

            if item.isImage {
                imageContent(for: item)
            } else if item.isText {
                textContent(for: item)
            } else {
                fileContent(for: item)
            }
        }
    }

    private func imageContent(for item: ClipboardItem) -> some View {
        Group {
            if let imageData = item.imageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: settings.screenshotSize - 4,
                           maxHeight: settings.screenshotSize - 4)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func textContent(for item: ClipboardItem) -> some View {
        Group {
            if let text = item.textContent {
                ScrollView {
                    Text(text)
                        .font(.system(size: 11))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func fileContent(for item: ClipboardItem) -> some View {
        VStack(spacing: 4) {
            Image(systemName: item.fileTypeCategory.icon)
                .font(.system(size: 30))
                .foregroundColor(item.fileTypeCategory.color)

            if let fileName = item.fileName {
                Text(fileName)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Context Menu
    private func contextMenu(for item: ClipboardItem) -> some View {
        Group {
            Button("Kopieren") {
                copyItemToPasteboard(item)
            }

            Button(item.isFavorite ? "Aus Favoriten entfernen" : "Als Favorit markieren") {
                pasteboardWatcher.toggleFavorite(item)
            }

            Divider()

            if item.isImage {
                Button("OCR - Text erkennen") {
                    performOCR(on: item)
                }
            }

            Button("Speichern unter...") {
                if item.isText {
                    saveTextWithTextEdit(item)
                } else {
                    saveItemToDisk(item)
                }
            }

            Divider()

            Button("Löschen") {
                pasteboardWatcher.deleteItem(item)
            }
        }
    }

    // MARK: - Actions
    private func selectItem(_ item: ClipboardItem) {
        selectedItem = item
        copyItemToPasteboard(item)

        let feedback = NSHapticFeedbackManager.defaultPerformer
        feedback.perform(.alignment, performanceTime: .now)
    }

    private func copyItemToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let imageData = item.imageData {
            pasteboard.setData(imageData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        } else if let text = item.textContent {
            pasteboard.setString(text, forType: .string)
        } else if let fileData = item.fileData {
            pasteboard.setData(fileData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        }

        NSSound.beep()
    }

    // MARK: - Settings mit Fokus
    private func openSettingsWithFocus() {
        SettingsWindowManager.shared.showSettingsWindow()

        // Fenster nach vorne bringen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let settingsWindow = NSApplication.shared.windows.first(where: { $0.title.contains("Einstellungen") || $0.title.contains("Settings") }) {
                settingsWindow.makeKeyAndOrderFront(nil)
                settingsWindow.orderFrontRegardless()
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - Drag & Drop
    private func createItemProvider(for item: ClipboardItem) -> NSItemProvider {
        let provider = NSItemProvider()

        if item.isImage, let imageData = item.imageData {
            provider.registerDataRepresentation(
                forTypeIdentifier: item.contentType.identifier,
                visibility: .all
            ) { completion in
                completion(imageData, nil)
                return nil
            }
        } else if item.isText, let text = item.textContent {
            provider.registerDataRepresentation(
                forTypeIdentifier: UTType.plainText.identifier,
                visibility: .all
            ) { completion in
                completion(text.data(using: .utf8), nil)
                return nil
            }
        } else if item.isFile, let fileData = item.fileData {
            provider.registerDataRepresentation(
                forTypeIdentifier: item.contentType.identifier,
                visibility: .all
            ) { completion in
                completion(fileData, nil)
                return nil
            }
        }

        return provider
    }

    // MARK: - Save Text with TextEdit
    private func saveTextWithTextEdit(_ item: ClipboardItem) {
        guard let text = item.textContent else { return }

        DispatchQueue.main.async {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("ShotCast-\(UUID().uuidString).txt")

            do {
                try text.write(to: tempURL, atomically: true, encoding: .utf8)

                NSWorkspace.shared.open(
                    [tempURL],
                    withApplicationAt: URL(fileURLWithPath: "/System/Applications/TextEdit.app"),
                    configuration: NSWorkspace.OpenConfiguration()
                ) { _, error in
                    if error == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.triggerSaveDialog()
                        }
                    }
                }
            } catch {
                print("Error saving temp file: \(error)")
            }
        }
    }

    private func triggerSaveDialog() {
        let saveEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: [.command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "s",
            charactersIgnoringModifiers: "s",
            isARepeat: false,
            keyCode: 1
        )

        if let saveEvent = saveEvent {
            NSApplication.shared.sendEvent(saveEvent)
        }
    }

    // MARK: - ABSOLUT CRASHSICHERES Speichern
    private func saveItemToDisk(_ item: ClipboardItem) {
        // Verwende RunLoop statt DispatchQueue für UI-Operationen
        let panel = NSSavePanel()
        panel.title = "Datei speichern"
        panel.canCreateDirectories = true

        if item.isImage {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            panel.nameFieldStringValue = "Screenshot-\(formatter.string(from: item.timestamp)).png"
            panel.allowedContentTypes = [.png, .jpeg]
        } else if let fileName = item.fileName {
            panel.nameFieldStringValue = fileName
        } else if item.isText {
            panel.nameFieldStringValue = "Text.txt"
            panel.allowedContentTypes = [.plainText]
        }

        // Verwende runModal statt begin für mehr Stabilität
        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            // File-Operation auf Background-Thread
            Task.detached {
                do {
                    if let imageData = item.imageData {
                        try imageData.write(to: url)
                    } else if let text = item.textContent {
                        try text.write(to: url, atomically: true, encoding: .utf8)
                    } else if let fileData = item.fileData {
                        try fileData.write(to: url)
                    }

                    // Feedback auf Main-Thread
                    await MainActor.run {
                        NSSound.beep()
                        let feedback = NSHapticFeedbackManager.defaultPerformer
                        feedback.perform(.levelChange, performanceTime: .now)
                    }
                } catch {
                    await MainActor.run {
                        print("Save error: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - OCR
    private func performOCR(on item: ClipboardItem) {
        guard let imageData = item.imageData,
              let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

            if !text.isEmpty {
                DispatchQueue.main.async {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    NSSound.beep()
                }
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["de-DE", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    // MARK: - Resize Handle
    private func resizeHandle(direction: ResizeDirection) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 16, height: 32)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .fill(isResizing ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 4, height: 24)
            )
            .onHover { isHovered in
                if isHovered {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isResizing = true
                        let delta = direction == .right ? value.translation.width : -value.translation.width
                        windowManager.resizeWindow(deltaWidth: delta, fromLeft: direction == .left)
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
    }

    enum ResizeDirection {
        case left, right
    }

    // MARK: - Helpers
    private func getAppIcon(bundleId: String) -> NSImage? {
        // Verwende den persistenten Icon-Cache
        return AppIconCache.shared.getIcon(for: bundleId)
    }

    private func getDisplayName(for item: ClipboardItem) -> String {
        if let fileName = item.fileName {
            return fileName
        } else if item.isText, let text = item.textContent {
            return String(text.prefix(30))
        } else {
            return item.fileTypeCategory.displayName
        }
    }

    private func getTimeLabel(for item: ClipboardItem) -> String {
        let interval = Date().timeIntervalSince(item.timestamp)
        if interval < 60 {
            return "vor \(Int(interval))s"
        } else if interval < 3600 {
            return "vor \(Int(interval/60))m"
        } else {
            return "vor \(Int(interval/3600))h"
        }
    }

    // MARK: - Styling
    private var modernBackground: some View {
        RoundedRectangle(cornerRadius: settings.cornerRadius)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: settings.cornerRadius)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.secondary)

            Text("Keine Elemente in der Zwischenablage")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Kopiere etwas, um es hier zu sehen")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    // MARK: - Setup
    private func setupListeners() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SettingsLiveUpdate"),
            object: nil,
            queue: .main
        ) { _ in
            windowManager.updateWindowFrame()
        }
    }
}

#Preview {
    BottomBarView()
}
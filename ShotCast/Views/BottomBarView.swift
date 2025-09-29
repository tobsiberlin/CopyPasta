import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Vision

struct BottomBarView: View {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var windowManager = WindowManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedItem: ClipboardItem?
    @State private var hoveredItemID: UUID?
    @State private var scrollOffset: CGFloat = 0
    @State private var showScrollButtons: Bool = false
    @State private var currentScrollIndex: Int = 0
    
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
    
    private var canScrollLeft: Bool {
        currentScrollIndex > 0
    }
    
    private var canScrollRight: Bool {
        currentScrollIndex < max(0, filteredItems.count - visibleItemsCount)
    }
    
    private var visibleItemsCount: Int {
        // Estimate how many items fit in the visible area
        let itemWidth = settings.screenshotSize + settings.itemSpacing
        let availableWidth: CGFloat = 600 // Approximate container width
        return max(1, Int(availableWidth / itemWidth))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top bar mit Einstellungen und Schließen-Button
                HStack {
                    // Einstellungen-Button links
                    Button(action: {
                        SettingsWindowManager.shared.showSettingsWindow()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .padding(6)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Drag-Handle in der Mitte für Window-Move
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let deltaX = value.translation.width
                                    let deltaY = value.translation.height
                                    windowManager.updateDragPosition(delta: NSPoint(x: deltaX, y: deltaY))
                                }
                                .onEnded { _ in
                                    windowManager.endDragging()
                                }
                        )
                        .onHover { isHovering in
                            if isHovering {
                                NSCursor.openHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                    
                    Spacer()
                    
                    // Schließen-Button rechts - Funktional machen
                    Button(action: {
                        windowManager.hideWindow()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .padding(6)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .frame(height: 32)
                
                // Main content area
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    // Hauptbereich mit funktionierender ScrollViewReader-Navigation
                    HStack(spacing: 0) {
                        // Linker Scroll-Button 
                        if showScrollButtons {
                            Button(action: {
                                scrollToPrevious()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .opacity(canScrollLeft ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.2), value: canScrollLeft)
                            .padding(.leading, 8)
                        }
                        
                        // Screenshot-ScrollView mit korrekt funktionierendem ScrollViewReader
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: settings.itemSpacing) {
                                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                        pasteStyleCard(item: item)
                                            .id(index)
                                            .scaleEffect(selectedItem?.id == item.id ? 1.05 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedItem?.id)
                                    }
                                }
                                .padding(.horizontal, showScrollButtons ? 8 : 12)
                                .padding(.bottom, 12)
                                .background(
                                    GeometryReader { geometry in
                                        Color.clear
                                            .onAppear {
                                                updateScrollButtonVisibility(contentWidth: geometry.size.width)
                                            }
                                            .onChange(of: filteredItems.count) {
                                                updateScrollButtonVisibility(contentWidth: geometry.size.width)
                                            }
                                    }
                                )
                            }
                            .onChange(of: currentScrollIndex) { index in
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    proxy.scrollTo(index, anchor: .leading)
                                }
                            }
                            .onChange(of: selectedItem) { item in
                                if let item = item,
                                   let index = filteredItems.firstIndex(where: { $0.id == item.id }) {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        proxy.scrollTo(index, anchor: .center)
                                    }
                                }
                            }
                        }
                        
                        // Rechter Scroll-Button
                        if showScrollButtons {
                            Button(action: {
                                scrollToNext()
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .opacity(canScrollRight ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.2), value: canScrollRight)
                            .padding(.trailing, 8)
                        }
                    }
                }
            }
            .background(
                // Richtige abgerundete Ecken mit schönem Hintergrund
                RoundedRectangle(cornerRadius: settings.cornerRadius)
                    .fill(.regularMaterial) // Native Material-Hintergrund
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1) // Subtiler Rand
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4) // Weichere Schatten
            )
            
            // Resize handles
            resizeHandles
        }
        .frame(height: settings.barHeight)
        .opacity(settings.barOpacity)
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            setupKeyboardShortcuts()
            setupLivePreviewListener()
        }
        .onDisappear {
            removeKeyboardShortcuts()
        }
    }
    
    private func pasteStyleCard(item: ClipboardItem) -> some View {
        VStack(spacing: 6) {
            // Dateiname über dem Screenshot - SICHTBAR machen
            Text(getOriginalFileName(for: item))
                .font(.system(size: max(9, settings.screenshotSize * 0.06), weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: settings.screenshotSize)
            
            ZStack {
                // Screenshot-Container mit Drag-Funktionalität
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: settings.screenshotSize, height: settings.screenshotSize)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedItem?.id == item.id ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                // Bild- oder Icon-Darstellung
                if item.isImage, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: settings.screenshotSize - 4, height: settings.screenshotSize - 4)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .saturation(1.1)
                        .brightness(0.02)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: item.fileTypeCategory.icon)
                            .font(.system(size: settings.screenshotSize * 0.25))
                            .foregroundColor(item.fileTypeCategory.color)
                        
                        Text(fileTypeText(for: item))
                            .font(.system(size: max(8, settings.screenshotSize * 0.08), weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Source Badge rechts oben - IMMER SICHTBAR
                VStack {
                    HStack {
                        Spacer()
                        let badgeText = item.sourceInfo?.badge ?? item.fileTypeCategory.sourceBadge ?? "?"
                        let badgeColor = item.sourceInfo?.badge != nil ? Color.red : item.fileTypeCategory.badgeColor
                        
                        Text(badgeText)
                            .font(.system(size: max(8, settings.screenshotSize * 0.06), weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: max(14, settings.screenshotSize * 0.12), height: max(14, settings.screenshotSize * 0.12))
                            .background(Circle().fill(badgeColor))
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .offset(x: -2, y: 2)
                    }
                    Spacer()
                }
            }
            .gesture(
                // Screenshot Drag & Drop implementieren
                DragGesture()
                    .onChanged { value in
                        // Visual feedback während dem Drag
                    }
                    .onEnded { value in
                        // Drag-to-Desktop Export implementieren
                        performDragExport(item: item, location: value.location)
                    }
            )
            
            // Dateityp-Info unter dem Screenshot - SICHTBAR machen  
            HStack(spacing: 3) {
                Image(systemName: item.fileTypeCategory.icon)
                    .font(.system(size: max(8, settings.screenshotSize * 0.06)))
                    .foregroundColor(item.fileTypeCategory.color)
                Text(item.fileTypeCategory.displayName)
                    .font(.system(size: max(7, settings.screenshotSize * 0.05), weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedItem = item
            }
            
            // Haptic feedback für professionelles Gefühl
            let feedback = NSHapticFeedbackManager.defaultPerformer
            feedback.perform(.alignment, performanceTime: .now)
            
            copyItemToPasteboard(item)
        }
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredItemID = isHovered ? item.id : nil
            }
        }
        .scaleEffect(hoveredItemID == item.id ? 1.02 : 1.0)
        .shadow(
            color: hoveredItemID == item.id ? .black.opacity(0.15) : .clear,
            radius: hoveredItemID == item.id ? 8 : 0,
            x: 0, y: 4
        )
        .animation(.easeInOut(duration: 0.2), value: hoveredItemID)
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
    
    private func getOriginalFileName(for item: ClipboardItem) -> String {
        // Zeigt den ursprünglichen Dateinamen für kopierte Dateien
        if let fileName = item.fileName {
            return fileName
        } else if item.isImage {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: item.timestamp)
            
            switch item.contentType {
            case .png: return "Bild \(timeString).png"
            case .jpeg: return "Bild \(timeString).jpg"
            case .heic: return "Bild \(timeString).heic"
            default: return "Bild \(timeString)"
            }
        } else if item.isURL {
            if let urlString = item.urlString, let url = URL(string: urlString) {
                return url.host ?? "URL"
            }
            return "URL"
        } else {
            return item.fileTypeCategory.displayName
        }
    }
    
    private func getDetailedFileName(for item: ClipboardItem) -> String {
        // Detaillierte Namen wie bei Paste
        if item.isImage {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: item.timestamp)
            
            switch item.contentType {
            case .png: return "Bild \(timeString).png"
            case .jpeg: return "Bild \(timeString).jpg"
            case .heic: return "Bild \(timeString).heic"
            default: return "Bild \(timeString)"
            }
        } else if let fileName = item.fileName {
            return fileName
        } else if item.isText {
            return "Text"
        } else if item.isURL {
            if let urlString = item.urlString, let url = URL(string: urlString) {
                return url.host ?? "URL"
            }
            return "URL"
        } else {
            return fileTypeText(for: item)
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
    
    // MARK: - Resize Handles
    private var resizeHandles: some View {
        ZStack {
            // Linker Resize-Handle mit sichtbarem Icon
            HStack {
                VStack {
                    Spacer()
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.leading, 2)
                    Spacer()
                }
                .frame(width: 12)
                .contentShape(Rectangle())
                .onHover { isHovering in
                    if isHovering {
                        NSCursor.resizeLeftRight.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Resize von links - verändert Position und Breite
                            let deltaWidth = value.translation.width
                            windowManager.resizeWindow(deltaWidth: deltaWidth, fromLeft: true)
                        }
                )
                Spacer()
            }
            
            // Rechter Resize-Handle mit sichtbarem Icon 
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.trailing, 2)
                    Spacer()
                }
                .frame(width: 12)
                .contentShape(Rectangle())
                .onHover { isHovering in
                    if isHovering {
                        NSCursor.resizeLeftRight.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Resize von rechts - verändert nur Breite
                            let deltaWidth = value.translation.width
                            windowManager.resizeWindow(deltaWidth: deltaWidth, fromLeft: false)
                        }
                )
            }
        }
    }
    
    // MARK: - Context Menu mit "Speichern unter"
    private func contextMenu(for item: ClipboardItem) -> some View {
        Group {
            Button(localizationManager.localizedString(.contextCopy)) {
                copyItemToPasteboard(item)
            }
            
            Button(item.isFavorite ? localizationManager.localizedString(.contextUnfavorite) : localizationManager.localizedString(.contextFavorite)) {
                pasteboardWatcher.toggleFavorite(item)
            }
            
            Divider()
            
            // OCR - nur für Bilder
            if item.isImage {
                Button("Texterkennung / OCR") {
                    performOCR(on: item)
                }
                
                Divider()
            }
            
            // Speichern unter - nur für Bilder und Dateien
            if item.isImage || item.isFile {
                Button("Speichern unter...") {
                    saveItemAs(item)
                }
                
                Divider()
            }
            
            Button(localizationManager.localizedString(.contextDelete)) {
                pasteboardWatcher.deleteItem(item)
            }
        }
    }
    
    // MARK: - Speichern unter Funktion
    private func saveItemAs(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            let savePanel = NSSavePanel()
            savePanel.title = "Datei speichern"
            savePanel.showsResizeIndicator = true
            savePanel.showsHiddenFiles = false
            savePanel.canCreateDirectories = true
            
            // Dateiname und Extension basierend auf Item-Typ setzen
            if item.isImage {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                let timestamp = formatter.string(from: item.timestamp)
                
                switch item.contentType {
                case .png:
                    savePanel.nameFieldStringValue = "Screenshot-\(timestamp).png"
                    savePanel.allowedContentTypes = [.png]
                case .jpeg:
                    savePanel.nameFieldStringValue = "Screenshot-\(timestamp).jpg"
                    savePanel.allowedContentTypes = [.jpeg]
                case .heic:
                    savePanel.nameFieldStringValue = "Screenshot-\(timestamp).heic"
                    savePanel.allowedContentTypes = [.heic]
                default:
                    savePanel.nameFieldStringValue = "Screenshot-\(timestamp).png"
                    savePanel.allowedContentTypes = [.png]
                }
            } else if let fileName = item.fileName {
                savePanel.nameFieldStringValue = fileName
            } else {
                savePanel.nameFieldStringValue = "Datei.txt"
            }
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    self.saveItemToURL(item, url: url)
                }
            }
        }
    }
    
    private func saveItemToURL(_ item: ClipboardItem, url: URL) {
        do {
            if let imageData = item.imageData {
                try imageData.write(to: url)
            } else if let fileData = item.fileData {
                try fileData.write(to: url)
            } else if let textContent = item.textContent {
                try textContent.write(to: url, atomically: true, encoding: .utf8)
            }
            
            // Erfolgsmeldung
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("ToastNotification"),
                    object: nil,
                    userInfo: ["message": "Erfolgreich gespeichert"]
                )
            }
        } catch {
            print("❌ Fehler beim Speichern: \(error.localizedDescription)")
            
            // Fehlermeldung
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("ToastNotification"),
                    object: nil,
                    userInfo: ["message": "Fehler beim Speichern: \(error.localizedDescription)"]
                )
            }
        }
    }
    
    // MARK: - OCR Funktionalität
    private func performOCR(on item: ClipboardItem) {
        guard let imageData = item.imageData,
              let image = NSImage(data: imageData),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            showOCRResult("Fehler: Bild konnte nicht verarbeitet werden")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showOCRResult("OCR-Fehler: \(error.localizedDescription)")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.showOCRResult("Kein Text im Bild erkannt")
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    self.showOCRResult("Kein Text im Bild erkannt")
                } else {
                    // Text in Zwischenablage kopieren
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(recognizedText, forType: .string)
                    
                    self.showOCRResult(recognizedText)
                }
            }
        }
        
        // Verbesserte OCR-Einstellungen
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["de-DE", "en-US"] // Deutsch und Englisch
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.showOCRResult("OCR-Fehler: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showOCRResult(_ text: String) {
        // Einfaches Alert als OCR-Fenster
        let alert = NSAlert()
        alert.messageText = "Texterkennung"
        alert.informativeText = "Folgender Inhalt wurde in die Zwischenablage kopiert und kann nun eingefügt werden:\n\n\"\(text)\""
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        
        // Alert in eigenem Thread anzeigen 
        DispatchQueue.main.async {
            alert.runModal()
        }
    }
    
    // MARK: - Karussell-Navigation Funktionen - FUNKTIONSFÄHIG
    private func scrollToPrevious() {
        let newIndex = max(0, currentScrollIndex - 1)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScrollIndex = newIndex
        }
        triggerHapticFeedback()
    }
    
    private func scrollToNext() {
        let maxIndex = max(0, filteredItems.count - visibleItemsCount)
        let newIndex = min(maxIndex, currentScrollIndex + 1)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScrollIndex = newIndex
        }
        triggerHapticFeedback()
    }
    
    private func triggerHapticFeedback() {
        let feedback = NSHapticFeedbackManager.defaultPerformer
        feedback.perform(.generic, performanceTime: .now)
    }
    
    // MARK: - Drag Export Funktionalität
    private func performDragExport(item: ClipboardItem, location: CGPoint) {
        // Export zu Desktop oder andere Apps
        if item.isImage, let imageData = item.imageData {
            let tempURL = createTempFile(data: imageData, fileName: getOriginalFileName(for: item))
            // TODO: Implementiere echtes Drag & Drop mit NSPasteboard
            print("Dragging image to: \(location), temp file: \(tempURL?.path ?? "none")")
        }
    }
    
    private func createTempFile(data: Data, fileName: String) -> URL? {
        let tempDir = NSTemporaryDirectory()
        let tempURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        return tempURL
    }
    
    private func updateScrollButtonVisibility(contentWidth: CGFloat) {
        DispatchQueue.main.async {
            // Show scroll buttons if content overflows
            let containerWidth: CGFloat = 600 // Approximate
            showScrollButtons = contentWidth > containerWidth && filteredItems.count > visibleItemsCount
        }
    }
    
    // MARK: - Keyboard Shortcuts - NotificationCenter Approach
    private func setupKeyboardShortcuts() {
        // Setup Keyboard-Handler über WindowManager (da struct-closures problematisch sind)
        // Pfeiltasten werden über NotificationCenter gehandelt
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ScrollPrevious"),
            object: nil,
            queue: .main
        ) { _ in
            if canScrollLeft {
                scrollToPrevious()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ScrollNext"),
            object: nil,
            queue: .main
        ) { _ in
            if canScrollRight {
                scrollToNext()
            }
        }
    }
    
    private func removeKeyboardShortcuts() {
        // Cleanup wird automatisch von NSEvent gemacht
    }
    
    // MARK: - Live Preview Listener
    private func setupLivePreviewListener() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SettingsLiveUpdate"),
            object: nil,
            queue: .main
        ) { _ in
            // Sofortige UI-Updates bei Settings-Änderungen
            windowManager.updateWindowFrame()
            
            // Smooth Transition Animation
            withAnimation(.easeInOut(duration: 0.2)) {
                // Views werden automatisch updated durch @StateObject bindings
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowBottomBarForPreview"),
            object: nil,
            queue: .main
        ) { _ in
            windowManager.showWindow()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("HideBottomBarAfterPreview"),
            object: nil,
            queue: .main
        ) { _ in
            windowManager.hideWindow()
        }
    }
}
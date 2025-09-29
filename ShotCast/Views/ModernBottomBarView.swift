import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Vision

struct ModernBottomBarView: View {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var settings = AppSettings.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var windowManager = WindowManager.shared
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
        ZStack {
            // Hauptcontainer
            VStack(spacing: 0) {
                // Kompakte Top-Bar
                compactTopBar

                // Modern Content
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    modernContent
                }
            }
            .background(modernBackground)
        }
        .frame(height: max(120, settings.screenshotSize + 80)) // Dynamische Höhe
        .opacity(settings.barOpacity)
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            setupListeners()
        }
    }

    // MARK: - Top Bar
    private var compactTopBar: some View {
        HStack(spacing: 12) {
            // Settings Button
            Button(action: {
                SettingsWindowManager.shared.showSettingsWindow()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(Font.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)

            Spacer()

            // Close Button
            Button(action: {
                windowManager.hideWindow()
            }) {
                Image(systemName: "xmark")
                    .font(Font.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 40)
    }

    // MARK: - Modern Content
    private var modernContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) { // Moderner enger Abstand
                ForEach(filteredItems) { item in
                    modernCard(item: item)
                        .scaleEffect(selectedItem?.id == item.id ? 1.02 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: selectedItem?.id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Modern Card
    private func modernCard(item: ClipboardItem) -> some View {
        VStack(spacing: 0) {
            // Header mit elegantem Typ-Badge
            HStack(spacing: 6) {
                // Typ-Badge (farbcodiert)
                Text(getTypeLabel(for: item))
                    .font(Font.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(getTypeColor(for: item))
                    )

                Spacer()

                // Zeit-Badge
                Text(getTimeLabel(for: item))
                    .font(Font.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Content Area (immer quadratisch)
            contentArea(for: item)
                .frame(width: settings.screenshotSize, height: settings.screenshotSize)
                .clipped()

            // Footer mit wichtigen Infos (IMMER sichtbar)
            footerInfo(for: item)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .frame(width: settings.screenshotSize + 16) // Feste Breite + Padding
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(
            color: .black.opacity(hoveredItemID == item.id ? 0.2 : 0.08),
            radius: hoveredItemID == item.id ? 8 : 4,
            x: 0, y: hoveredItemID == item.id ? 4 : 2
        )
        .scaleEffect(hoveredItemID == item.id ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: hoveredItemID)
        .onTapGesture {
            selectItem(item)
        }
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredItemID = isHovered ? item.id : nil
            }
        }
        .contextMenu {
            contextMenu(for: item)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    performDragExport(item: item, location: value.location)
                }
        )
    }

    // MARK: - Content Area
    private func contentArea(for item: ClipboardItem) -> some View {
        ZStack {
            // Hintergrund
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.controlBackgroundColor))

            // Content basierend auf Typ
            if item.isImage {
                imageContent(for: item)
            } else if item.isText {
                textContent(for: item)
            } else {
                fileContent(for: item)
            }
        }
    }

    // MARK: - Content Types
    private func imageContent(for item: ClipboardItem) -> some View {
        Group {
            if let imageData = item.imageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: settings.screenshotSize - 4, height: settings.screenshotSize - 4)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .font(Font.system(size: settings.screenshotSize * 0.2))
                            .foregroundColor(.secondary)
                    )
            }
        }
    }

    private func textContent(for item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let textContent = item.textContent {
                Text(textContent)
                    .font(Font.system(size: max(8, settings.screenshotSize * 0.05), weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .padding(6)
            } else {
                Image(systemName: "doc.text")
                    .font(Font.system(size: settings.screenshotSize * 0.2))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func fileContent(for item: ClipboardItem) -> some View {
        VStack(spacing: 4) {
            Image(systemName: item.fileTypeCategory.icon)
                .font(Font.system(size: settings.screenshotSize * 0.15))
                .foregroundColor(item.fileTypeCategory.color)

            if let fileName = item.fileName {
                Text(fileName)
                    .font(Font.system(size: max(7, settings.screenshotSize * 0.04)))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer (IMMER sichtbar!)
    private func footerInfo(for item: ClipboardItem) -> some View {
        VStack(spacing: 3) {
            // Titel/Name (immer anzeigen)
            HStack {
                Text(getDisplayName(for: item))
                    .font(Font.system(size: max(9, settings.screenshotSize * 0.05), weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }

            // Icons und Badges (immer anzeigen)
            HStack(spacing: 4) {
                // Source Badge (immer zeigen)
                if let sourceInfo = item.sourceInfo, let badge = sourceInfo.badge {
                    Text(badge)
                        .font(Font.system(size: max(6, settings.screenshotSize * 0.03), weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: max(12, settings.screenshotSize * 0.06), height: max(12, settings.screenshotSize * 0.06))
                        .background(Circle().fill(.red))
                } else {
                    // Fallback-Badge basierend auf Dateityp
                    Text(item.fileTypeCategory.sourceBadge ?? "?")
                        .font(Font.system(size: max(6, settings.screenshotSize * 0.03), weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: max(12, settings.screenshotSize * 0.06), height: max(12, settings.screenshotSize * 0.06))
                        .background(Circle().fill(item.fileTypeCategory.badgeColor))
                }

                // Dateityp Icon (immer zeigen)
                Image(systemName: item.fileTypeCategory.icon)
                    .font(Font.system(size: max(8, settings.screenshotSize * 0.04)))
                    .foregroundColor(item.fileTypeCategory.color)

                Spacer()

                // Zusätzliche Info (Zeichen, Größe etc.) - immer zeigen
                Text(getAdditionalInfo(for: item))
                    .font(Font.system(size: max(7, settings.screenshotSize * 0.035), weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Helper Functions
    private func getTypeLabel(for item: ClipboardItem) -> String {
        switch item.fileTypeCategory {
        case .image: return "Bild"
        case .text: return "Text"
        case .document: return "Dokument"
        case .pdf: return "PDF"
        case .video: return "Video"
        case .audio: return "Audio"
        case .archive: return "Archiv"
        case .url: return "Link"
        case .code: return "Code"
        case .other: return "Datei"
        }
    }

    private func getTypeColor(for item: ClipboardItem) -> Color {
        switch item.fileTypeCategory {
        case .image: return settings.colorTheme.gradientColors.first ?? .blue
        case .text: return .green
        case .document: return .blue
        case .pdf: return .red
        case .video: return .purple
        case .audio: return .orange
        case .archive: return .brown
        case .url: return .teal
        case .code: return .indigo
        case .other: return .gray
        }
    }

    private func getTimeLabel(for item: ClipboardItem) -> String {
        let interval = Date().timeIntervalSince(item.timestamp)
        if interval < 60 {
            return "vor \(Int(interval)) Sek"
        } else if interval < 3600 {
            return "vor \(Int(interval/60)) Min"
        } else if interval < 86400 {
            return "vor \(Int(interval/3600)) Std"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            return formatter.string(from: item.timestamp)
        }
    }

    private func getDisplayName(for item: ClipboardItem) -> String {
        if let fileName = item.fileName {
            return fileName
        } else if item.isText, let textContent = item.textContent {
            let preview = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(preview.prefix(20)) + (preview.count > 20 ? "..." : "")
        } else if item.isURL, let urlString = item.urlString, let url = URL(string: urlString) {
            return url.host ?? "URL"
        } else {
            return getTypeLabel(for: item)
        }
    }

    private func getAdditionalInfo(for item: ClipboardItem) -> String {
        if item.isText, let textContent = item.textContent {
            return "\(textContent.count)"
        } else if item.isImage {
            return "IMG"
        } else {
            return ""
        }
    }

    // MARK: - Styling
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.regularMaterial)
            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
    }

    private var modernBackground: some View {
        RoundedRectangle(cornerRadius: settings.cornerRadius)
            .fill(.regularMaterial)
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(Font.system(size: 24, weight: .light))
                .foregroundColor(.secondary)

            Text("Keine Elemente")
                .font(Font.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions
    private func selectItem(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            selectedItem = item
        }

        let feedback = NSHapticFeedbackManager.defaultPerformer
        feedback.perform(.alignment, performanceTime: .now)

        copyItemToPasteboard(item)
    }

    private func copyItemToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let imageData = item.imageData {
            pasteboard.setData(imageData, forType: NSPasteboard.PasteboardType(item.contentType.identifier))
        } else if let textContent = item.textContent {
            pasteboard.setString(textContent, forType: .string)
        }

        NSSound.beep()
    }

    private func contextMenu(for item: ClipboardItem) -> some View {
        Group {
            Button("Kopieren") {
                copyItemToPasteboard(item)
            }

            Button(item.isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen") {
                pasteboardWatcher.toggleFavorite(item)
            }

            if item.isImage {
                Divider()
                Button("OCR - Text erkennen") {
                    performOCR(on: item)
                }
            }

            if item.isImage || item.isFile {
                Button("Speichern unter...") {
                    saveItemAs(item)
                }
            }

            Divider()
            Button("Löschen") {
                pasteboardWatcher.deleteItem(item)
            }
        }
    }

    // MARK: - OCR Implementation
    private func performOCR(on item: ClipboardItem) {
        guard let imageData = item.imageData,
              let image = NSImage(data: imageData),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            showOCRAlert("Fehler: Bild konnte nicht verarbeitet werden")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showOCRAlert("OCR-Fehler: \(error.localizedDescription)")
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.showOCRAlert("Kein Text im Bild erkannt")
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                if recognizedText.isEmpty {
                    self.showOCRAlert("Kein Text im Bild erkannt")
                } else {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(recognizedText, forType: .string)
                    self.showOCRAlert("Text erkannt und kopiert:\n\n\(recognizedText)")
                }
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["de-DE", "en-US", "es-ES", "fr-FR", "it-IT", "pt-PT", "nl-NL", "ru-RU", "zh-Hans", "ja-JP", "ko-KR", "ar-SA"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.showOCRAlert("OCR-Fehler: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showOCRAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Texterkennung"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        DispatchQueue.main.async {
            alert.runModal()
        }
    }

    // MARK: - Save Implementation
    private func saveItemAs(_ item: ClipboardItem) {
        let savePanel = NSSavePanel()
        savePanel.title = "Datei speichern"
        savePanel.canCreateDirectories = true

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
            default:
                savePanel.nameFieldStringValue = "Screenshot-\(timestamp).png"
                savePanel.allowedContentTypes = [.png]
            }
        } else if let fileName = item.fileName {
            savePanel.nameFieldStringValue = fileName
        } else if item.isText {
            savePanel.nameFieldStringValue = "Text.txt"
            savePanel.allowedContentTypes = [.plainText]
        }

        DispatchQueue.main.async {
            let response = savePanel.runModal()
            if response == .OK, let url = savePanel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.saveItemToURL(item, url: url)
                }
            }
        }
    }

    private func saveItemToURL(_ item: ClipboardItem, url: URL) {
        do {
            if let imageData = item.imageData {
                try imageData.write(to: url)
            } else if let textContent = item.textContent {
                try textContent.write(to: url, atomically: true, encoding: .utf8)
            }

            DispatchQueue.main.async {
                let feedback = NSHapticFeedbackManager.defaultPerformer
                feedback.perform(.levelChange, performanceTime: .now)
            }
        } catch {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Speichern fehlgeschlagen"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }

    // MARK: - Drag Export
    private func performDragExport(item: ClipboardItem, location: CGPoint) {
        // Simplified drag export
        print("Dragging item: \(getDisplayName(for: item))")
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

        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowBottomBarForPreview"),
            object: nil,
            queue: .main
        ) { _ in
            windowManager.showWindow()
        }
    }
}

#Preview {
    ModernBottomBarView()
}
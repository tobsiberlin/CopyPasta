import SwiftUI
import AppKit
import UniformTypeIdentifiers
import Vision

struct PerfectBottomBarView: View {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var settings = AppSettings.shared
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
        VStack(spacing: 0) {
            // Top Control Bar - IMMER sichtbar
            topControlBar
                .frame(height: 50)
                .zIndex(100)

            // Main Content
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                modernScrollContent
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
        HStack(spacing: 20) {
            // Settings Button - IMMER sichtbar
            Button(action: {
                SettingsWindowManager.shared.showSettingsWindow()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(Font.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            // Drag Handle
            Image(systemName: "rectangle.3.group")
                .font(Font.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .gesture(windowDragGesture)

            Spacer()

            // Close Button - IMMER sichtbar
            Button(action: {
                windowManager.hideWindow()
            }) {
                Image(systemName: "xmark")
                    .font(Font.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: - Modern Content
    private var modernScrollContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filteredItems) { item in
                    perfectCard(item: item)
                        .scaleEffect(selectedItem?.id == item.id ? 1.03 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedItem?.id)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Perfect Card
    private func perfectCard(item: ClipboardItem) -> some View {
        VStack(spacing: 10) {
            // Header mit App-Icon und Typ
            cardHeader(item: item)

            // Content Area
            cardContent(item: item)
                .frame(width: settings.screenshotSize, height: settings.screenshotSize)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Footer mit Infos - IMMER sichtbar
            cardFooter(item: item)
        }
        .frame(width: settings.screenshotSize + 24)
        .padding(12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: .black.opacity(hoveredItemID == item.id ? 0.15 : 0.08),
            radius: hoveredItemID == item.id ? 12 : 8,
            x: 0, y: hoveredItemID == item.id ? 6 : 4
        )
        .scaleEffect(hoveredItemID == item.id ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: hoveredItemID)
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
        .onDrag {
            createDragItem(for: item)
        }
    }

    // MARK: - Card Components
    private func cardHeader(item: ClipboardItem) -> some View {
        HStack(spacing: 8) {
            // App Icon statt Buchstaben
            modernAppIcon(for: item)
                .frame(width: 24, height: 24)

            // Typ Badge
            Text(getTypeLabel(for: item))
                .font(Font.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getTypeColor(for: item))
                )

            Spacer()

            // Zeit
            Text(getTimeLabel(for: item))
                .font(Font.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func cardContent(item: ClipboardItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
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

    private func cardFooter(item: ClipboardItem) -> some View {
        VStack(spacing: 6) {
            // Dateiname - IMMER sichtbar
            HStack {
                Text(getDisplayName(for: item))
                    .font(Font.system(size: max(11, settings.screenshotSize * 0.06), weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }

            // Icons Row - IMMER sichtbar
            HStack(spacing: 8) {
                // Source Badge
                sourceBadge(for: item)

                // File Type Icon
                Image(systemName: item.fileTypeCategory.icon)
                    .font(Font.system(size: max(12, settings.screenshotSize * 0.06)))
                    .foregroundColor(item.fileTypeCategory.color)

                Spacer()

                // Additional Info
                Text(getAdditionalInfo(for: item))
                    .font(Font.system(size: max(9, settings.screenshotSize * 0.05), weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Content Views
    private func imageContent(for item: ClipboardItem) -> some View {
        Group {
            if let imageData = item.imageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: settings.screenshotSize - 4, height: settings.screenshotSize - 4)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .font(Font.system(size: settings.screenshotSize * 0.2))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func textContent(for item: ClipboardItem) -> some View {
        Group {
            if let textContent = item.textContent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(textContent)
                            .font(Font.system(size: max(10, settings.screenshotSize * 0.06), weight: .regular))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                            .padding(10)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.textBackgroundColor))
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
            } else {
                Image(systemName: "doc.text")
                    .font(Font.system(size: settings.screenshotSize * 0.2))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func fileContent(for item: ClipboardItem) -> some View {
        VStack(spacing: 8) {
            Image(systemName: item.fileTypeCategory.icon)
                .font(Font.system(size: settings.screenshotSize * 0.15))
                .foregroundColor(item.fileTypeCategory.color)

            if let fileName = item.fileName {
                Text(fileName)
                    .font(Font.system(size: max(10, settings.screenshotSize * 0.05)))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Modern App Icon
    private func modernAppIcon(for item: ClipboardItem) -> some View {
        Group {
            if let sourceInfo = item.sourceInfo {
                // Echte App Icons
                if let appIcon = getAppIcon(from: sourceInfo) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Fallback System Icons
                    systemIconForSource(sourceInfo)
                }
            } else {
                // Default Icon
                Image(systemName: item.fileTypeCategory.icon)
                    .font(Font.system(size: 18))
                    .foregroundColor(item.fileTypeCategory.color)
            }
        }
    }

    private func sourceBadge(for item: ClipboardItem) -> some View {
        Group {
            if let sourceInfo = item.sourceInfo {
                if let badge = sourceInfo.badge {
                    Text(badge)
                        .font(Font.system(size: max(8, settings.screenshotSize * 0.04), weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: max(16, settings.screenshotSize * 0.08), height: max(16, settings.screenshotSize * 0.08))
                        .background(Circle().fill(.red))
                } else {
                    Text("?")
                        .font(Font.system(size: max(8, settings.screenshotSize * 0.04), weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: max(16, settings.screenshotSize * 0.08), height: max(16, settings.screenshotSize * 0.08))
                        .background(Circle().fill(.gray))
                }
            } else {
                Text(item.fileTypeCategory.sourceBadge ?? "F")
                    .font(Font.system(size: max(8, settings.screenshotSize * 0.04), weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: max(16, settings.screenshotSize * 0.08), height: max(16, settings.screenshotSize * 0.08))
                    .background(Circle().fill(item.fileTypeCategory.badgeColor))
            }
        }
    }

    // MARK: - Helper Functions
    private func getAppIcon(from sourceInfo: SourceDetector.SourceInfo) -> NSImage? {
        // Versuche App-Icon zu laden basierend auf Source-Info
        if let bundleId = sourceInfo.bundleIdentifier {
            let workspace = NSWorkspace.shared
            if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) {
                return workspace.icon(forFile: appURL.path)
            }
        }
        return nil
    }

    private func systemIconForSource(_ sourceInfo: SourceDetector.SourceInfo) -> some View {
        Group {
            let appName = sourceInfo.appName.lowercased()
            if !appName.isEmpty {
                switch true {
                case appName.contains("shottr"):
                    Image(systemName: "camera.viewfinder")
                        .font(Font.system(size: 18))
                        .foregroundColor(.blue)
                case appName.contains("code"), appName.contains("vscode"):
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(Font.system(size: 18))
                        .foregroundColor(.blue)
                case appName.contains("safari"):
                    Image(systemName: "safari")
                        .font(Font.system(size: 18))
                        .foregroundColor(.blue)
                case appName.contains("chrome"):
                    Image(systemName: "globe")
                        .font(Font.system(size: 18))
                        .foregroundColor(.red)
                default:
                    Image(systemName: "app.badge")
                        .font(Font.system(size: 18))
                        .foregroundColor(.secondary)
                }
            } else if case .universalClipboard(let deviceType) = sourceInfo.source {
                // iPhone/iPad Icons
                Image(systemName: deviceType.icon)
                    .font(Font.system(size: 18))
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "app.badge")
                    .font(Font.system(size: 18))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func getTypeLabel(for item: ClipboardItem) -> String {
        switch item.fileTypeCategory {
        case .image: return "Bild"
        case .text: return "Text"
        case .document: return "Doc"
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
        switch settings.colorTheme {
        case .blue: return .blue
        case .green: return .green
        case .red: return .red
        case .purple: return .purple
        }
    }

    private func getTimeLabel(for item: ClipboardItem) -> String {
        let interval = Date().timeIntervalSince(item.timestamp)
        if interval < 60 {
            return "vor \(Int(interval))s"
        } else if interval < 3600 {
            return "vor \(Int(interval/60))m"
        } else if interval < 86400 {
            return "vor \(Int(interval/3600))h"
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
            return String(preview.prefix(25)) + (preview.count > 25 ? "..." : "")
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

    // MARK: - Drag & Drop
    private func createDragItem(for item: ClipboardItem) -> NSItemProvider {
        let itemProvider = NSItemProvider()

        if item.isImage, let imageData = item.imageData {
            itemProvider.registerDataRepresentation(forTypeIdentifier: item.contentType.identifier, visibility: .all) { completion in
                completion(imageData, nil)
                return nil
            }
        } else if item.isText, let textContent = item.textContent {
            itemProvider.registerDataRepresentation(forTypeIdentifier: UTType.plainText.identifier, visibility: .all) { completion in
                completion(textContent.data(using: .utf8), nil)
                return nil
            }
        }

        return itemProvider
    }

    // MARK: - Context Menu
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

    // MARK: - OCR (Korrigiert)
    private func performOCR(on item: ClipboardItem) {
        guard let imageData = item.imageData,
              let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            showAlert(title: "OCR Fehler", message: "Bild konnte nicht verarbeitet werden")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "OCR Fehler", message: error.localizedDescription)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.showAlert(title: "OCR", message: "Kein Text im Bild erkannt")
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    return observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                if recognizedText.isEmpty {
                    self.showAlert(title: "OCR", message: "Kein Text im Bild erkannt")
                } else {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(recognizedText, forType: .string)
                    self.showAlert(title: "OCR Erfolgreich", message: "Text erkannt und kopiert")
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
                    self.showAlert(title: "OCR Fehler", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Save (Korrigiert)
    private func saveItemAs(_ item: ClipboardItem) {
        let savePanel = NSSavePanel()
        savePanel.title = "Datei speichern"
        savePanel.canCreateDirectories = true

        // Korrekte Dateityp-Zuordnung
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
            savePanel.allowedContentTypes = [.data]
        } else if item.isText {
            savePanel.nameFieldStringValue = "Text.txt"
            savePanel.allowedContentTypes = [.plainText]
        } else {
            savePanel.nameFieldStringValue = "Datei"
            savePanel.allowedContentTypes = [.data]
        }

        // Sicherer Modal Dialog
        savePanel.begin { response in
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
            } else if let fileData = item.fileData {
                try fileData.write(to: url)
            } else if let textContent = item.textContent {
                try textContent.write(to: url, atomically: true, encoding: .utf8)
            } else if let urlString = item.urlString {
                try urlString.write(to: url, atomically: true, encoding: .utf8)
            } else {
                throw CocoaError(.fileWriteUnknown)
            }

            DispatchQueue.main.async {
                let feedback = NSHapticFeedbackManager.defaultPerformer
                feedback.perform(.levelChange, performanceTime: .now)
                print("✅ Erfolgreich gespeichert: \(url.path)")
            }
        } catch {
            DispatchQueue.main.async {
                self.showAlert(title: "Speichern fehlgeschlagen", message: error.localizedDescription)
            }
        }
    }

    // MARK: - Window Dragging
    private var windowDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                windowManager.updateDragPosition(delta: NSPoint(x: value.translation.width, y: value.translation.height))
            }
            .onEnded { _ in
                windowManager.endDragging()
            }
    }

    // MARK: - Styling
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(.regularMaterial)
            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
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
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(Font.system(size: 40, weight: .light))
                .foregroundColor(.secondary)

            Text("Keine Elemente in der Zwischenablage")
                .font(Font.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Utilities
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .informational
        alert.runModal()
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
    PerfectBottomBarView()
}
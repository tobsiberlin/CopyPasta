import Foundation
import AppKit

class AppIconCache: ObservableObject {
    static let shared = AppIconCache()

    private var iconCache: [String: NSImage] = [:]
    private let cacheDirectory: URL

    private init() {
        // Cache-Verzeichnis erstellen
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheDirectory = appSupport.appendingPathComponent("ShotCast/IconCache", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        loadCachedIcons()
    }

    // MARK: - Icon Cache Management

    func getIcon(for bundleId: String) -> NSImage? {
        // Zuerst im Memory-Cache schauen
        if let cachedIcon = iconCache[bundleId] {
            return cachedIcon
        }

        // Dann im File-Cache schauen
        if let fileIcon = loadIconFromDisk(bundleId: bundleId) {
            iconCache[bundleId] = fileIcon
            return fileIcon
        }

        // Sonst vom System holen und cachen
        if let systemIcon = getSystemIcon(for: bundleId) {
            iconCache[bundleId] = systemIcon
            saveIconToDisk(icon: systemIcon, bundleId: bundleId)
            return systemIcon
        }

        return nil
    }

    private func getSystemIcon(for bundleId: String) -> NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    private func saveIconToDisk(icon: NSImage, bundleId: String) {
        let fileName = "\(bundleId.replacingOccurrences(of: ".", with: "_")).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        if let tiffData = icon.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: fileURL)
        }
    }

    private func loadIconFromDisk(bundleId: String) -> NSImage? {
        let fileName = "\(bundleId.replacingOccurrences(of: ".", with: "_")).png"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return NSImage(contentsOf: fileURL)
        }

        return nil
    }

    private func loadCachedIcons() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files {
            if file.pathExtension == "png" {
                let bundleId = file.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: ".")
                if let icon = NSImage(contentsOf: file) {
                    iconCache[bundleId] = icon
                }
            }
        }
    }

    // MARK: - Cache Management

    func clearCache() {
        iconCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func preloadIcon(for bundleId: String) {
        Task.detached {
            _ = self.getIcon(for: bundleId)
        }
    }
}
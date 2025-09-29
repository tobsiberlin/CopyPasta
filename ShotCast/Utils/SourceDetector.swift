import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

class SourceDetector {
    static let shared = SourceDetector()
    
    private init() {}
    
    enum ClipboardSource {
        case app(bundleId: String, name: String)
        case universalClipboard(deviceType: DeviceType)
        case unknown
        
        enum DeviceType {
            case iPhone, iPad, mac, appleWatch
            
            var icon: String {
                switch self {
                case .iPhone: return "iphone"
                case .iPad: return "ipad"
                case .mac: return "desktopcomputer"
                case .appleWatch: return "applewatch"
                }
            }
            
            var displayName: String {
                switch self {
                case .iPhone: return "iPhone"
                case .iPad: return "iPad" 
                case .mac: return "Mac"
                case .appleWatch: return "Apple Watch"
                }
            }
        }
    }
    
    struct SourceInfo {
        let source: ClipboardSource
        let icon: String
        let badge: String?
        let badgeColor: Color
        let displayName: String
        
        var iconImage: NSImage? {
            // Try to get actual app icon first
            if case .app(let bundleId, _) = source {
                return SourceDetector.shared.getAppIcon(for: bundleId)
            }
            return NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        }
    }
    
    /// Detects the source of clipboard content
    func detectSource() -> SourceInfo {
        // Check for Universal Clipboard first
        if let deviceSource = detectUniversalClipboardSource() {
            return createSourceInfo(for: .universalClipboard(deviceType: deviceSource))
        }
        
        // Check for app-specific sources
        if let appSource = detectAppSource() {
            return createSourceInfo(for: .app(bundleId: appSource.bundleId, name: appSource.name))
        }
        
        // Fallback to unknown
        return createSourceInfo(for: .unknown)
    }
    
    // MARK: - Private Detection Methods
    
    private func detectUniversalClipboardSource() -> ClipboardSource.DeviceType? {
        let pasteboard = NSPasteboard.general
        
        // Check pasteboard name for Universal Clipboard indicators
        let pasteboardName = pasteboard.name.rawValue
        if !pasteboardName.isEmpty {
            if pasteboardName.contains("Handoff") || pasteboardName.contains("Universal") {
                // Try to determine device type from pasteboard properties
                return detectHandoffDeviceType()
            }
        }
        
        // Check for iOS-specific UTTypes
        let availableTypes = pasteboard.types ?? []
        for type in availableTypes {
            if type.rawValue.contains("com.apple.handoff") {
                return detectHandoffDeviceType()
            }
        }
        
        return nil
    }
    
    private func detectHandoffDeviceType() -> ClipboardSource.DeviceType {
        // This is a simplified detection - in reality, you'd need more sophisticated logic
        // Could analyze device identifiers, screen sizes, or other Handoff metadata
        
        // For now, default to iPhone (most common case)
        // In a real implementation, you'd parse the actual Handoff data
        return .iPhone
    }
    
    private func detectAppSource() -> (bundleId: String, name: String)? {
        // Check running applications and recently active ones
        let workspace = NSWorkspace.shared
        _ = workspace.runningApplications
        
        // Get the frontmost (most recently active) application
        if let frontmostApp = workspace.frontmostApplication {
            if let bundleId = frontmostApp.bundleIdentifier,
               let name = frontmostApp.localizedName {
                
                // Skip Finder and ShotCast itself
                if bundleId != "com.apple.finder" && bundleId != Bundle.main.bundleIdentifier {
                    return (bundleId: bundleId, name: name)
                }
            }
        }
        
        return nil
    }
    
    private func createSourceInfo(for source: ClipboardSource) -> SourceInfo {
        switch source {
        case .app(let bundleId, let name):
            return createAppSourceInfo(bundleId: bundleId, name: name)
        case .universalClipboard(let deviceType):
            return createUniversalClipboardSourceInfo(deviceType: deviceType)
        case .unknown:
            return createUnknownSourceInfo()
        }
    }
    
    private func createAppSourceInfo(bundleId: String, name: String) -> SourceInfo {
        // Map known apps to their specific icons and badges
        switch bundleId {
        case "cc.ffitch.shottr":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "camera.fill",
                badge: "S",
                badgeColor: .red,
                displayName: "Shottr"
            )
        case "com.microsoft.VSCode":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "chevron.left.forwardslash.chevron.right",
                badge: "</>",
                badgeColor: .blue,
                displayName: "VS Code"
            )
        case "com.apple.Safari":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "safari.fill",
                badge: "🌐",
                badgeColor: .blue,
                displayName: "Safari"
            )
        case "com.apple.dt.Xcode":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "hammer.fill",
                badge: "X",
                badgeColor: .blue,
                displayName: "Xcode"
            )
        case "com.apple.Terminal":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "terminal.fill",
                badge: "$",
                badgeColor: .black,
                displayName: "Terminal"
            )
        case "com.adobe.Photoshop":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "photo.fill.on.rectangle.fill",
                badge: "Ps",
                badgeColor: .blue,
                displayName: "Photoshop"
            )
        case "com.figma.Desktop":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "paintbrush.pointed.fill",
                badge: "F",
                badgeColor: .orange,
                displayName: "Figma"
            )
        case "com.apple.finder":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "folder.fill",
                badge: "📁",
                badgeColor: .blue,
                displayName: "Finder"
            )
        case "com.googlecode.iterm2":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "terminal.fill",
                badge: "T",
                badgeColor: .green,
                displayName: "iTerm2"
            )
        case "com.apple.TextEdit":
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "doc.text.fill",
                badge: "A",
                badgeColor: .gray,
                displayName: "TextEdit"
            )
        default:
            // Generic app fallback - use first letter of app name
            let firstLetter = String(name.prefix(1)).uppercased()
            return SourceInfo(
                source: .app(bundleId: bundleId, name: name),
                icon: "app.fill",
                badge: firstLetter,
                badgeColor: .blue,
                displayName: name
            )
        }
    }
    
    private func createUniversalClipboardSourceInfo(deviceType: ClipboardSource.DeviceType) -> SourceInfo {
        switch deviceType {
        case .iPhone:
            return SourceInfo(
                source: .universalClipboard(deviceType: deviceType),
                icon: "iphone",
                badge: "📱",
                badgeColor: .blue,
                displayName: "iPhone"
            )
        case .iPad:
            return SourceInfo(
                source: .universalClipboard(deviceType: deviceType),
                icon: "ipad",
                badge: "📱",
                badgeColor: .purple,
                displayName: "iPad"
            )
        case .mac:
            return SourceInfo(
                source: .universalClipboard(deviceType: deviceType),
                icon: "desktopcomputer",
                badge: "💻",
                badgeColor: .gray,
                displayName: "Mac"
            )
        case .appleWatch:
            return SourceInfo(
                source: .universalClipboard(deviceType: deviceType),
                icon: "applewatch",
                badge: "⌚",
                badgeColor: .black,
                displayName: "Apple Watch"
            )
        }
    }
    
    private func createUnknownSourceInfo() -> SourceInfo {
        return SourceInfo(
            source: .unknown,
            icon: "questionmark.circle.fill",
            badge: "?",
            badgeColor: .gray,
            displayName: "Unknown"
        )
    }
    
    private func getAppIcon(for bundleId: String) -> NSImage? {
        let workspace = NSWorkspace.shared
        
        // Try to get the app's icon via bundle identifier
        if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) {
            return workspace.icon(forFile: appURL.path)
        }
        
        // Fallback: try to find running app
        let runningApps = workspace.runningApplications
        if let app = runningApps.first(where: { $0.bundleIdentifier == bundleId }) {
            return app.icon
        }
        
        return nil
    }
}


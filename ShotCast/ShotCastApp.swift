import SwiftUI
import AppKit

@main
struct ShotCastApp: App {
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var windowManager = WindowManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            StatusBarIconView()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Professional StatusBar Icon
struct StatusBarIconView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            // Try to load professional menubar icon first
            if let menuBarIcon = createMenuBarIcon() {
                Image(nsImage: menuBarIcon)
            } else if let appIcon = NSImage(named: "AppIcon") {
                // Fallback: use app icon with proper sizing
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16) // Standard menubar size
            } else {
                // Final fallback: Custom SF Symbol
                Image(systemName: "photo.stack")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private func createMenuBarIcon() -> NSImage? {
        // Try to load menubar-specific template icon
        if let templateIcon = NSImage(named: "MenuBarIcon") {
            templateIcon.isTemplate = true
            return templateIcon
        }
        
        // Try to load menubar icon with Template suffix (macOS convention)
        if let templateIcon = NSImage(named: "MenuBarIconTemplate") {
            templateIcon.isTemplate = true
            return templateIcon
        }
        
        // Create professional ShotCast icon programmatically
        return IconGenerator.shared.createMenuBarTemplateIcon()
    }
    
    private func createSFSymbolMenuBarIcon() -> NSImage? {
        // Create professional SF Symbol icon for ShotCast
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = NSImage(systemSymbolName: "photo.stack", accessibilityDescription: "ShotCast")
        
        if let symbolImage = image?.withSymbolConfiguration(config) {
            symbolImage.isTemplate = true
            return symbolImage
        }
        
        return nil
    }
}

struct MenuBarView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var isHoveringOpen = false
    @State private var isHoveringSettings = false
    @State private var isHoveringQuit = false
    
    var body: some View {
        VStack(spacing: 2) {
            MenuItemButton(
                icon: "arrow.up.left.square",
                title: localizationManager.localizedString(.menuOpen),
                isHovering: $isHoveringOpen,
                action: {
                    WindowManager.shared.showWindow()
                    NSApp.activate(ignoringOtherApps: true)
                }
            )
            
            Divider()
                .padding(.vertical, 4)
            
            MenuItemButton(
                icon: "gearshape.fill",
                title: localizationManager.localizedString(.menuSettings),
                isHovering: $isHoveringSettings,
                action: {
                    SettingsWindowManager.shared.showSettingsWindow()
                }
            )
            
            Divider()
                .padding(.vertical, 4)
            
            MenuItemButton(
                icon: "power",
                title: localizationManager.localizedString(.menuQuit),
                isHovering: $isHoveringQuit,
                isDestructive: true,
                action: {
                    NSApplication.shared.terminate(nil)
                }
            )
        }
        .padding(8)
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Modern Menu Item Button
struct MenuItemButton: View {
    let icon: String
    let title: String
    @Binding var isHovering: Bool
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                    .foregroundStyle(isDestructive ? Color.red : Color.accentColor)
                
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(isDestructive ? Color.red : Color.primary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? (isDestructive ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1)) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var pasteboardWatcher: PasteboardWatcher?
    private var windowManager = WindowManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        self.pasteboardWatcher = PasteboardWatcher.shared
        
        print("✅ ShotCast: PasteboardWatcher gestartet")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAutoActivation),
            name: .clipboardAutoActivated,
            object: nil
        )
    }
    
    @objc private func handleAutoActivation() {
        print("📱 Auto-Aktivierung: Bottom Bar wird angezeigt")
        windowManager.showWindow(animated: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        pasteboardWatcher?.stopMonitoring()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            windowManager.showWindow()
        }
        return true
    }
    
    
}
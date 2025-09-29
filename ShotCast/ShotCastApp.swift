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
                // Final fallback: SF Symbol
                Image(systemName: "photo.artframe")
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
        
        // Create professional icon from SF Symbol
        return createSFSymbolMenuBarIcon()
    }
    
    private func createSFSymbolMenuBarIcon() -> NSImage? {
        // Create professional SF Symbol icon
        let image = NSImage(systemSymbolName: "photo.artframe", accessibilityDescription: "ShotCast")
        image?.isTemplate = true
        return image
    }
}

struct MenuBarView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack {
            Button(localizationManager.localizedString(.menuOpen)) {
                WindowManager.shared.showWindow()
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Divider()
            
            Button(localizationManager.localizedString(.menuSettings)) {
                SettingsWindowManager.shared.showSettingsWindow()
            }
            
            Divider()
            
            Button(localizationManager.localizedString(.menuQuit)) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
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
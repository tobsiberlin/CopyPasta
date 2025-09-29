import Foundation
import SwiftUI
import AppKit

class SettingsWindowManager: ObservableObject {
    static let shared = SettingsWindowManager()
    
    private var settingsWindow: NSWindow?
    
    private init() {}
    
    func showSettingsWindow() {
        if settingsWindow == nil {
            createSettingsWindow()
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.center()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createSettingsWindow() {
        let contentView = ModernSettingsView()
            .environmentObject(AppSettings.shared)
            .environmentObject(LocalizationManager.shared)
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 550),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow?.title = LocalizationManager.shared.localizedString(.settingsTitle)
        settingsWindow?.contentView = NSHostingView(rootView: contentView)
        settingsWindow?.isReleasedWhenClosed = false
        settingsWindow?.titlebarAppearsTransparent = true
        settingsWindow?.center()
        settingsWindow?.minSize = NSSize(width: 750, height: 550)
    }
}
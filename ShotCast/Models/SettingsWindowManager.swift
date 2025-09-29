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
        let contentView = SettingsView()
            .environmentObject(AppSettings.shared)
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow?.title = "ShotCast Einstellungen"
        settingsWindow?.contentView = NSHostingView(rootView: contentView)
        settingsWindow?.isReleasedWhenClosed = false
        settingsWindow?.center()
    }
}
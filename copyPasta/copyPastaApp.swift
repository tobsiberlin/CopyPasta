//
//  copyPastaApp.swift
//  copyPasta
//
//  Created by Tobias Mattern on 28.09.25.
//

import SwiftUI
import AppKit

@main
struct copyPastaApp: App {
    // Singleton-Instanzen für App-weite Services
    // Singleton instances for app-wide services
    @StateObject private var pasteboardWatcher = PasteboardWatcher()
    @StateObject private var windowManager = WindowManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Unsichtbares Window Group für SwiftUI
        // Invisible Window Group for SwiftUI
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Entfernt Standard-Menüs die wir nicht brauchen
            // Removes standard menus we don't need
            CommandGroup(replacing: .newItem) { }
        }
    }
}

// App Delegate für erweiterte macOS-Funktionalität
// App Delegate for extended macOS functionality
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var pasteboardWatcher: PasteboardWatcher?
    private var windowManager = WindowManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App läuft im Hintergrund (kein Dock-Icon während Background-Betrieb)
        // App runs in background (no dock icon during background operation)
        NSApp.setActivationPolicy(.accessory)
        
        // Status Bar Icon erstellen
        // Create status bar icon
        setupStatusBarItem()
        
        // PasteboardWatcher initialisieren
        // Initialize PasteboardWatcher
        self.pasteboardWatcher = PasteboardWatcher()
        
        // Bottom Bar View für Paste-Style Interface
        // Bottom bar view for Paste-style interface
        let bottomBarView = BottomBarView()
            .environmentObject(pasteboardWatcher!)
            .environmentObject(windowManager)
        
        let hostingView = NSHostingView(rootView: bottomBarView)
        windowManager.setContentView(hostingView)
        
        // Window initial nicht anzeigen (Auto-Activation bei Copy)
        // Don't show window initially (auto-activation on copy)
        
        // Registriere für Notifications
        // Register for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAutoActivation),
            name: .clipboardAutoActivated,
            object: nil
        )
    }
    
    // Status Bar Item Setup
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // SF Symbol für modernes Design
            // SF Symbol for modern design
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "CopyPasta")
            button.image?.size = NSSize(width: 16, height: 16)
            button.image?.isTemplate = true
            
            // Click-Handler
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        // Kontextmenü
        // Context menu
        setupStatusBarMenu()
    }
    
    private func setupStatusBarMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "CopyPasta öffnen", action: #selector(showWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Einstellungen...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func statusBarButtonClicked() {
        // Links-Click: Toggle Window
        // Left click: Toggle window
        if let event = NSApp.currentEvent, event.type == .leftMouseUp {
            windowManager.toggleWindow()
            statusItem?.menu = nil // Menü temporär deaktivieren
        }
    }
    
    @objc private func showWindow() {
        windowManager.showWindow()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showPreferences() {
        // TODO: Preferences Window implementieren
        // TODO: Implement preferences window
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc private func handleAutoActivation() {
        print("📱 handleAutoActivation aufgerufen")
        // Bei Copy: Bottom Bar anzeigen
        // On copy: Show bottom bar
        windowManager.showWindow(animated: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        pasteboardWatcher?.stopMonitoring()
    }
    
    // Ermöglicht erneutes Öffnen des Fensters über Dock
    // Allows reopening window via dock
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            windowManager.showWindow()
        }
        return true
    }
}

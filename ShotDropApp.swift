//
//  ShotDropApp.swift
//  ShotDrop
//
//  Created by Tobias Mattern on 28.09.25.
//

import SwiftUI
import AppKit

@main
struct ShotDropApp: App {
    // Singleton-Instanzen für App-weite Services
    // Singleton instances for app-wide services
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var windowManager = WindowManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Verstecktes WindowGroup - niemals sichtbar
        // Hidden WindowGroup - never visible
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
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
        
        // Schließe alle StandardFenster sofort
        // Close all standard windows immediately
        for window in NSApp.windows {
            window.close()
        }
        
        // Status Bar Icon erstellen
        // Create status bar icon
        setupStatusBarItem()
        
        // PasteboardWatcher Singleton verwenden
        // Use PasteboardWatcher singleton
        self.pasteboardWatcher = PasteboardWatcher.shared
        
        print("✅ AppDelegate: PasteboardWatcher Singleton initialisiert")
        
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
            button.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "ShotDrop")
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
        
        menu.addItem(NSMenuItem(title: "ShotDrop öffnen", action: #selector(showWindow), keyEquivalent: "o"))
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
        // Settings über SettingsWindowManager öffnen
        // Open settings via SettingsWindowManager
        SettingsWindowManager.shared.showSettingsWindow()
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
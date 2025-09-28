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
    @StateObject private var pasteboardWatcher = PasteboardWatcher.shared
    @StateObject private var windowManager = WindowManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("ShotDrop", systemImage: "photo.on.rectangle.angled") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarView: View {
    var body: some View {
        VStack {
            Button("ShotDrop öffnen") {
                WindowManager.shared.showWindow()
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Divider()
            
            Button("Einstellungen...") {
                SettingsWindowManager.shared.showSettingsWindow()
            }
            
            Divider()
            
            Button("Beenden") {
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
        
        print("✅ AppDelegate: PasteboardWatcher Singleton initialisiert")
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAutoActivation),
            name: .clipboardAutoActivated,
            object: nil
        )
    }
    
    @objc private func handleAutoActivation() {
        print("📱 handleAutoActivation aufgerufen")
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
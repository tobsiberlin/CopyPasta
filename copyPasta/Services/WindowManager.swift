import Foundation
import SwiftUI
import AppKit
import Combine

// Verwaltet das App-Fenster und Auto-Activation
// Manages app window and auto-activation
class WindowManager: NSObject, ObservableObject {
    static let shared = WindowManager()
    
    @Published var isWindowVisible = false
    private var window: NSWindow?
    private var windowController: NSWindowController?
    
    // Window-Konfiguration
    private let windowWidth: CGFloat = 800
    private let windowHeight: CGFloat = 600
    private let windowMinWidth: CGFloat = 400
    private let windowMinHeight: CGFloat = 300
    
    private override init() {
        super.init()
        setupWindow()
    }
    
    // Erstellt und konfiguriert das Hauptfenster
    // Creates and configures the main window
    private func setupWindow() {
        // Window Style: Modern macOS mit visuellen Effekten
        // Window Style: Modern macOS with visual effects
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Window-Eigenschaften
        // Window properties
        window.title = "CopyPasta"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: windowMinWidth, height: windowMinHeight)
        
        // Visueller Effekt für macOS-Style
        // Visual effect for macOS style
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = true
        
        // Window-Position: Zentriert auf Hauptbildschirm
        // Window position: Centered on main screen
        window.center()
        
        // Window-Level für Floating-Verhalten
        // Window level for floating behavior
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Window-Delegate
        window.delegate = self
        
        self.window = window
        
        // Window Controller
        let windowController = NSWindowController(window: window)
        self.windowController = windowController
    }
    
    // Zeigt das Fenster mit Animation
    // Shows window with animation
    func showWindow(animated: Bool = true) {
        guard let window = window else { return }
        
        if animated {
            // Fade-in Animation
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1.0
            } completionHandler: { [weak self] in
                self?.isWindowVisible = true
            }
        } else {
            window.makeKeyAndOrderFront(nil)
            isWindowVisible = true
        }
        
        // App aktivieren
        // Activate app
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // Versteckt das Fenster mit Animation
    // Hides window with animation
    func hideWindow(animated: Bool = true) {
        guard let window = window else { return }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                window.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                window.orderOut(nil)
                self?.isWindowVisible = false
            }
        } else {
            window.orderOut(nil)
            isWindowVisible = false
        }
    }
    
    // Toggle Window-Sichtbarkeit
    // Toggle window visibility
    func toggleWindow() {
        if isWindowVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    // Auto-Activation mit Fokus auf neues Element
    // Auto-activation with focus on new element
    func autoActivateForNewContent() {
        showWindow(animated: true)
        
        // Notification für UI, um neues Element zu highlighten
        // Notification for UI to highlight new element
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: .focusNewClipboardItem, object: nil)
        }
    }
    
    // Setzt den Content View
    // Sets the content view
    func setContentView(_ view: NSView) {
        window?.contentView = view
    }
    
    // Window-Position speichern/wiederherstellen
    // Save/restore window position
    func saveWindowPosition() {
        guard let window = window else { return }
        let frame = window.frame
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: "CopyPastaWindowFrame")
    }
    
    func restoreWindowPosition() {
        guard let window = window,
              let frameString = UserDefaults.standard.string(forKey: "CopyPastaWindowFrame"),
              let screen = NSScreen.main else { return }
        
        let frame = NSRectFromString(frameString)
        
        // Prüfen ob Frame noch auf sichtbarem Bildschirm ist
        // Check if frame is still on visible screen
        if screen.visibleFrame.intersects(frame) {
            window.setFrame(frame, display: false)
        } else {
            window.center()
        }
    }
}

// MARK: - NSWindowDelegate
extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        isWindowVisible = false
        saveWindowPosition()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        // Window wurde aktiv
        // Window became active
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // Optional: Window automatisch verstecken wenn Fokus verloren
        // Optional: Auto-hide window when focus lost
        // hideWindow(animated: true)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let focusNewClipboardItem = Notification.Name("focusNewClipboardItem")
}
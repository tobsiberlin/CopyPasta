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
    private var settings = AppSettings.shared
    private var hideTimer: Timer?
    
    private override init() {
        super.init()
        setupWindow()
    }
    
    // Erstellt und konfiguriert das Paste-Style Bottom Bar Fenster
    // Creates and configures the Paste-style bottom bar window
    private func setupWindow() {
        guard let screen = NSScreen.main else { return }
        
        // Bottom Bar Dimensionen basierend auf Bildschirm
        // Bottom bar dimensions based on screen
        let screenFrame = screen.visibleFrame
        let barHeight = settings.barHeight
        let barFrame = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: screenFrame.width,
            height: barHeight
        )
        
        // Borderless Window für Bottom Bar
        // Borderless window for bottom bar
        let window = NSWindow(
            contentRect: barFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Paste-Style Window Eigenschaften
        // Paste-style window properties
        window.title = "CopyPasta"
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.canHide = false
        
        // Level für immer im Vordergrund aber nicht störend
        // Level for always on top but not intrusive
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        
        // Window-Delegate
        window.delegate = self
        
        self.window = window
        
        // Window Controller
        let windowController = NSWindowController(window: window)
        self.windowController = windowController
        
        // Initial verstecken
        // Initially hidden
        window.orderOut(nil)
    }
    
    // Zeigt die Bottom Bar mit Slide-Up Animation
    // Shows bottom bar with slide-up animation
    func showWindow(animated: Bool = true) {
        guard let window = window, let screen = NSScreen.main else { return }
        
        // Timer zurücksetzen
        // Reset timer
        hideTimer?.invalidate()
        
        if animated && !isWindowVisible {
            // Slide-up Animation wie Paste
            // Slide-up animation like Paste
            let screenFrame = screen.visibleFrame
            let finalFrame = NSRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: settings.barHeight
            )
            
            // Start-Position: Unter dem Bildschirm
            // Start position: Below screen
            let startFrame = NSRect(
                x: finalFrame.minX,
                y: finalFrame.minY - finalFrame.height,
                width: finalFrame.width,
                height: finalFrame.height
            )
            
            window.setFrame(startFrame, display: false)
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1)
                window.animator().setFrame(finalFrame, display: true)
                window.animator().alphaValue = settings.barOpacity
            } completionHandler: { [weak self] in
                self?.isWindowVisible = true
                self?.startHideTimer()
            }
        } else {
            // Sofort anzeigen
            // Show immediately
            updateWindowFrame()
            window.alphaValue = settings.barOpacity
            window.makeKeyAndOrderFront(nil)
            isWindowVisible = true
            startHideTimer()
        }
    }
    
    // Versteckt die Bottom Bar mit Slide-Down Animation
    // Hides bottom bar with slide-down animation
    func hideWindow(animated: Bool = true) {
        guard let window = window else { return }
        
        hideTimer?.invalidate()
        
        if animated && isWindowVisible {
            // Slide-down Animation
            // Slide-down animation
            let currentFrame = window.frame
            let hideFrame = NSRect(
                x: currentFrame.minX,
                y: currentFrame.minY - currentFrame.height,
                width: currentFrame.width,
                height: currentFrame.height
            )
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                window.animator().setFrame(hideFrame, display: true)
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
    
    // Auto-Hide Timer starten
    // Start auto-hide timer
    private func startHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: settings.hideDelay, repeats: false) { [weak self] _ in
            self?.hideWindow(animated: true)
        }
    }
    
    // Window-Frame basierend auf aktuellen Einstellungen aktualisieren
    // Update window frame based on current settings
    func updateWindowFrame() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let newFrame = NSRect(
            x: screenFrame.minX,
            y: screenFrame.minY,
            width: screenFrame.width,
            height: settings.barHeight
        )
        
        if isWindowVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                window.animator().setFrame(newFrame, display: true)
            }
        } else {
            window.setFrame(newFrame, display: false)
        }
    }
    
    // Reagiert auf Maus-Events für Interaktivität
    // Responds to mouse events for interactivity
    func handleMouseEntered() {
        hideTimer?.invalidate()
    }
    
    func handleMouseExited() {
        if isWindowVisible {
            startHideTimer()
        }
    }
}

// MARK: - NSWindowDelegate
extension WindowManager: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        isWindowVisible = false
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
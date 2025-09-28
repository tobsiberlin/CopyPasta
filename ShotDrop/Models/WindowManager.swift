import Foundation
import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var window: NSWindow?
    private var hideTimer: Timer?
    @Published var isVisible = false
    
    private init() {}
    
    func showWindow(animated: Bool = true) {
        if window == nil {
            createWindow()
        }
        
        guard let window = window else { return }
        
        positionWindow()
        
        if animated {
            window.alphaValue = 0
            window.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                window.animator().alphaValue = 1.0
            }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
        
        isVisible = true
        scheduleAutoHide()
    }
    
    func hideWindow(animated: Bool = true) {
        guard let window = window, isVisible else { return }
        
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                window.animator().alphaValue = 0
            }) {
                window.orderOut(nil)
                self.isVisible = false
            }
        } else {
            window.orderOut(nil)
            isVisible = false
        }
        
        cancelAutoHide()
    }
    
    func toggleWindow() {
        if isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    private func createWindow() {
        let contentView = ContentView()
            .environmentObject(AppSettings.shared)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: AppSettings.shared.barHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window?.contentView = NSHostingView(rootView: contentView)
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.level = .floating
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window?.isMovable = false
        window?.acceptsMouseMovedEvents = true
    }
    
    private func positionWindow() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = min(800, screenFrame.width - 40)
        let windowHeight = AppSettings.shared.barHeight
        
        let x = screenFrame.midX - windowWidth / 2
        let y = screenFrame.minY + 20
        
        window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
    }
    
    func updateWindowFrame() {
        guard let window = window else { return }
        
        let currentFrame = window.frame
        let newHeight = AppSettings.shared.barHeight
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y,
            width: currentFrame.width,
            height: newHeight
        )
        
        window.setFrame(newFrame, display: true, animate: true)
    }
    
    private func scheduleAutoHide() {
        guard AppSettings.shared.autoHideEnabled else { return }
        
        cancelAutoHide()
        
        hideTimer = Timer.scheduledTimer(withTimeInterval: AppSettings.shared.hideDelay, repeats: false) { [weak self] _ in
            self?.hideWindow()
        }
    }
    
    private func cancelAutoHide() {
        hideTimer?.invalidate()
        hideTimer = nil
    }
    
    func handleMouseEntered() {
        cancelAutoHide()
    }
    
    func handleMouseExited() {
        scheduleAutoHide()
    }
}
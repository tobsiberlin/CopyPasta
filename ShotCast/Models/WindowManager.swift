import Foundation
import SwiftUI
import AppKit

enum WindowEdge {
    case top, bottom, left, right, center
}

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    private var window: NSWindow?
    private var hideTimer: Timer?
    @Published var isVisible = false
    @Published var currentEdge: WindowEdge = .center
    
    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero
    private let snappingManager = WindowSnappingManager.shared
    
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
        
        let screenWidth = NSScreen.main?.visibleFrame.width ?? 1920
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: screenWidth - 40, height: AppSettings.shared.barHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window?.contentView = NSHostingView(rootView: contentView)
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.level = .floating
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window?.isMovable = true
        window?.acceptsMouseMovedEvents = true
    }
    
    private func positionWindow() {
        guard let window = window else { return }
        
        // Immer den Hauptbildschirm verwenden (nicht screen where mouse is)
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        let windowWidth: CGFloat = screenFrame.width - 40  // Fast die ganze Bildschirmbreite
        let windowHeight = AppSettings.shared.barHeight
        
        let x = screenFrame.midX - windowWidth / 2
        let y = screenFrame.minY + 20
        
        window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        
        // Stelle sicher, dass das Fenster auf dem korrekten Bildschirm ist
        if let windowScreen = window.screen, windowScreen != screen {
            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
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
    
    func resizeWindowHorizontally(delta: CGFloat) {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let currentFrame = window.frame
        let screenFrame = screen.visibleFrame
        let minWidth: CGFloat = 400
        let maxWidth: CGFloat = screenFrame.width - 40
        
        let newWidth = max(minWidth, min(maxWidth, currentFrame.width + delta))
        let newX = screenFrame.midX - newWidth / 2  // Zentriert halten
        
        let newFrame = NSRect(
            x: newX,
            y: currentFrame.origin.y,
            width: newWidth,
            height: currentFrame.height
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
    
    // MARK: - Professional Window Management
    
    func handleKeyboardShortcut(_ event: NSEvent) -> Bool {
        guard let window = window else { return false }
        return snappingManager.handleKeyboardShortcut(event, window: window)
    }
    
    func centerWindow() {
        guard let window = window else { return }
        snappingManager.centerWindow(window)
    }
    
    func snapToZone(_ zone: WindowSnappingManager.SnapZone) {
        guard let window = window else { return }
        snappingManager.snapWindow(window, to: zone, animated: true)
    }
    
    func moveToScreen(_ screen: NSScreen) {
        guard let window = window else { return }
        snappingManager.moveWindow(window, to: screen, maintainRelativePosition: true)
    }
    
    // MARK: - Window Dragging & Snapping
    
    func startDragging(at point: NSPoint) {
        isDragging = true
        dragStartPoint = point
    }
    
    func endDragging() {
        guard isDragging, let window = window else { return }
        isDragging = false
        
        // Professional multi-screen snapping
        let mouseLocation = NSEvent.mouseLocation
        if let snapZone = snappingManager.detectSnapZone(for: window, mouseLocation: mouseLocation) {
            snappingManager.snapWindow(window, to: snapZone, animated: true)
        } else {
            // Fallback to old snapping for compatibility
            snapToNearestEdge()
        }
        
        snappingManager.hideSnapPreview()
    }
    
    func updateDragPosition(delta: NSPoint) {
        guard isDragging, let window = window else { return }
        
        let currentFrame = window.frame
        let newFrame = NSRect(
            x: currentFrame.origin.x + delta.x,
            y: currentFrame.origin.y + delta.y,
            width: currentFrame.width,
            height: currentFrame.height
        )
        
        window.setFrame(newFrame, display: true, animate: false)
        
        // Show snap preview during dragging
        let mouseLocation = NSEvent.mouseLocation
        if let snapZone = snappingManager.detectSnapZone(for: window, mouseLocation: mouseLocation) {
            if let screen = window.screen {
                snappingManager.showSnapPreview(for: snapZone, on: screen)
            }
        } else {
            snappingManager.hideSnapPreview()
        }
    }
    
    private func snapToNearestEdge() {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let windowFrame = window.frame
        let screenFrame = screen.visibleFrame
        let snapDistance: CGFloat = 50 // Pixel-Abstand für Snapping
        
        // Koordinaten für zukünftige Verwendung
        let _ = windowFrame.midX  // windowCenterX
        let _ = windowFrame.midY  // windowCenterY
        
        var targetEdge: WindowEdge = .center
        var targetFrame = windowFrame
        
        // Prüfe Distanz zu den Rändern
        let distanceToTop = abs(windowFrame.maxY - screenFrame.maxY)
        let distanceToBottom = abs(windowFrame.minY - screenFrame.minY)
        let distanceToLeft = abs(windowFrame.minX - screenFrame.minX)
        let distanceToRight = abs(windowFrame.maxX - screenFrame.maxX)
        
        let minDistance = min(distanceToTop, distanceToBottom, distanceToLeft, distanceToRight)
        
        if minDistance <= snapDistance {
            if minDistance == distanceToTop {
                // Snap to top
                targetEdge = .top
                targetFrame = NSRect(
                    x: screenFrame.midX - windowFrame.width / 2,
                    y: screenFrame.maxY - windowFrame.height - 10,
                    width: windowFrame.width,
                    height: windowFrame.height
                )
            } else if minDistance == distanceToBottom {
                // Snap to bottom
                targetEdge = .bottom
                targetFrame = NSRect(
                    x: screenFrame.midX - windowFrame.width / 2,
                    y: screenFrame.minY + 10,
                    width: windowFrame.width,
                    height: windowFrame.height
                )
            } else if minDistance == distanceToLeft {
                // Snap to left
                targetEdge = .left
                targetFrame = NSRect(
                    x: screenFrame.minX + 10,
                    y: screenFrame.midY - windowFrame.height / 2,
                    width: windowFrame.width,
                    height: windowFrame.height
                )
            } else if minDistance == distanceToRight {
                // Snap to right
                targetEdge = .right
                targetFrame = NSRect(
                    x: screenFrame.maxX - windowFrame.width - 10,
                    y: screenFrame.midY - windowFrame.height / 2,
                    width: windowFrame.width,
                    height: windowFrame.height
                )
            }
            
            // Animiere zum Ziel
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(targetFrame, display: true)
            }
            
            currentEdge = targetEdge
        } else {
            currentEdge = .center
        }
    }
    
    func snapToEdge(_ edge: WindowEdge) {
        guard let window = window, let screen = NSScreen.main else { return }
        
        let windowFrame = window.frame
        let screenFrame = screen.visibleFrame
        var targetFrame = windowFrame
        
        switch edge {
        case .top:
            targetFrame = NSRect(
                x: screenFrame.midX - windowFrame.width / 2,
                y: screenFrame.maxY - windowFrame.height - 10,
                width: windowFrame.width,
                height: windowFrame.height
            )
        case .bottom:
            targetFrame = NSRect(
                x: screenFrame.midX - windowFrame.width / 2,
                y: screenFrame.minY + 10,
                width: windowFrame.width,
                height: windowFrame.height
            )
        case .left:
            targetFrame = NSRect(
                x: screenFrame.minX + 10,
                y: screenFrame.midY - windowFrame.height / 2,
                width: windowFrame.width,
                height: windowFrame.height
            )
        case .right:
            targetFrame = NSRect(
                x: screenFrame.maxX - windowFrame.width - 10,
                y: screenFrame.midY - windowFrame.height / 2,
                width: windowFrame.width,
                height: windowFrame.height
            )
        case .center:
            targetFrame = NSRect(
                x: screenFrame.midX - windowFrame.width / 2,
                y: screenFrame.minY + 20,
                width: windowFrame.width,
                height: windowFrame.height
            )
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(targetFrame, display: true)
        }
        
        currentEdge = edge
    }
}
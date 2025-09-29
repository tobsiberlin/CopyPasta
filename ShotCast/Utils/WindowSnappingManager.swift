import Foundation
import AppKit
import SwiftUI

class WindowSnappingManager: ObservableObject {
    static let shared = WindowSnappingManager()
    
    @Published var isSnapping = false
    @Published var snapPreviewVisible = false
    @Published var currentSnapZone: SnapZone?
    
    private var snapDistance: CGFloat = 25.0
    private var magneticDistance: CGFloat = 50.0
    private var elasticAnimationDuration: TimeInterval = 0.3
    
    enum SnapZone {
        case topLeft, top, topRight
        case left, center, right
        case bottomLeft, bottom, bottomRight
        case fullScreen
        
        var displayName: String {
            switch self {
            case .topLeft: return "Oben Links"
            case .top: return "Oben"
            case .topRight: return "Oben Rechts"
            case .left: return "Links"
            case .center: return "Mitte"
            case .right: return "Rechts"
            case .bottomLeft: return "Unten Links"
            case .bottom: return "Unten"
            case .bottomRight: return "Unten Rechts"
            case .fullScreen: return "Vollbild"
            }
        }
        
        var icon: String {
            switch self {
            case .topLeft: return "rectangle.topthird.inset.filled"
            case .top: return "rectangle.tophalf.inset.filled"
            case .topRight: return "rectangle.topthird.inset.filled"
            case .left: return "rectangle.lefthalf.inset.filled"
            case .center: return "rectangle.inset.filled"
            case .right: return "rectangle.righthalf.inset.filled"
            case .bottomLeft: return "rectangle.bottomthird.inset.filled"
            case .bottom: return "rectangle.bottomhalf.inset.filled"
            case .bottomRight: return "rectangle.bottomthird.inset.filled"
            case .fullScreen: return "rectangle.fill"
            }
        }
    }
    
    struct ScreenInfo {
        let screen: NSScreen
        let frame: CGRect
        let visibleFrame: CGRect
        let displayID: CGDirectDisplayID
        let isPrimary: Bool
        
        var snapZones: [SnapZone: CGRect] {
            let frame = visibleFrame
            let width = frame.width
            let height = frame.height
            let x = frame.minX
            let y = frame.minY
            
            return [
                .topLeft: CGRect(x: x, y: y + height * 0.5, width: width * 0.5, height: height * 0.5),
                .top: CGRect(x: x, y: y + height * 0.5, width: width, height: height * 0.5),
                .topRight: CGRect(x: x + width * 0.5, y: y + height * 0.5, width: width * 0.5, height: height * 0.5),
                .left: CGRect(x: x, y: y, width: width * 0.5, height: height),
                .center: CGRect(x: x + width * 0.25, y: y + height * 0.25, width: width * 0.5, height: height * 0.5),
                .right: CGRect(x: x + width * 0.5, y: y, width: width * 0.5, height: height),
                .bottomLeft: CGRect(x: x, y: y, width: width * 0.5, height: height * 0.5),
                .bottom: CGRect(x: x, y: y, width: width, height: height * 0.5),
                .bottomRight: CGRect(x: x + width * 0.5, y: y, width: width * 0.5, height: height * 0.5),
                .fullScreen: frame
            ]
        }
    }
    
    private init() {}
    
    /// Snaps a window to the specified position on the current screen
    func snapWindow(_ window: NSWindow, to zone: SnapZone, animated: Bool = true) {
        guard let screenInfo = getScreenInfo(for: window) else { return }
        
        let targetFrame = screenInfo.snapZones[zone] ?? screenInfo.visibleFrame
        
        DispatchQueue.main.async {
            self.isSnapping = true
            self.currentSnapZone = zone
            
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = self.elasticAnimationDuration
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    window.animator().setFrame(targetFrame, display: true)
                } completionHandler: {
                    self.isSnapping = false
                }
            } else {
                window.setFrame(targetFrame, display: true)
                self.isSnapping = false
            }
        }
    }
    
    /// Detects snap zones based on mouse position and window
    func detectSnapZone(for window: NSWindow, mouseLocation: CGPoint) -> SnapZone? {
        guard let screenInfo = getScreenInfo(for: window) else { return nil }
        
        let screenFrame = screenInfo.visibleFrame
        let edgeThreshold: CGFloat = 50.0
        
        // Check screen edges first
        let isNearLeft = mouseLocation.x <= screenFrame.minX + edgeThreshold
        let isNearRight = mouseLocation.x >= screenFrame.maxX - edgeThreshold
        let isNearTop = mouseLocation.y >= screenFrame.maxY - edgeThreshold
        let isNearBottom = mouseLocation.y <= screenFrame.minY + edgeThreshold
        
        // Corner detection
        if isNearTop && isNearLeft { return .topLeft }
        if isNearTop && isNearRight { return .topRight }
        if isNearBottom && isNearLeft { return .bottomLeft }
        if isNearBottom && isNearRight { return .bottomRight }
        
        // Edge detection
        if isNearTop { return .top }
        if isNearBottom { return .bottom }
        if isNearLeft { return .left }
        if isNearRight { return .right }
        
        // Center detection (middle of screen)
        let centerX = screenFrame.midX
        let centerY = screenFrame.midY
        let centerThreshold: CGFloat = 100.0
        
        if abs(mouseLocation.x - centerX) < centerThreshold && 
           abs(mouseLocation.y - centerY) < centerThreshold {
            return .center
        }
        
        return nil
    }
    
    /// Magnetic snapping - pulls window to snap zones when close
    func magneticSnap(for window: NSWindow, mouseLocation: CGPoint) -> SnapZone? {
        guard let screenInfo = getScreenInfo(for: window) else { return nil }
        
        var closestZone: SnapZone?
        var closestDistance: CGFloat = magneticDistance
        
        for (zone, rect) in screenInfo.snapZones {
            let distance = distanceToRect(point: mouseLocation, rect: rect)
            if distance < closestDistance {
                closestDistance = distance
                closestZone = zone
            }
        }
        
        return closestZone
    }
    
    /// Shows snap preview overlay
    func showSnapPreview(for zone: SnapZone, on screen: NSScreen) {
        // This would show a visual preview overlay
        // Implementation would involve creating a transparent overlay window
        DispatchQueue.main.async {
            self.currentSnapZone = zone
            self.snapPreviewVisible = true
        }
    }
    
    /// Hides snap preview overlay
    func hideSnapPreview() {
        DispatchQueue.main.async {
            self.snapPreviewVisible = false
            self.currentSnapZone = nil
        }
    }
    
    /// Keyboard shortcuts for direct snapping
    func handleKeyboardShortcut(_ event: NSEvent, window: NSWindow) -> Bool {
        let modifiers = event.modifierFlags
        let keyCode = event.keyCode
        
        // Cmd + Arrow Keys for snapping
        if modifiers.contains(.command) {
            switch keyCode {
            case 123: // Left Arrow
                if modifiers.contains(.shift) {
                    snapWindow(window, to: .left)
                } else if modifiers.contains(.option) {
                    snapWindow(window, to: .topLeft)
                } else {
                    snapWindow(window, to: .bottomLeft)
                }
                return true
            case 124: // Right Arrow
                if modifiers.contains(.shift) {
                    snapWindow(window, to: .right)
                } else if modifiers.contains(.option) {
                    snapWindow(window, to: .topRight)
                } else {
                    snapWindow(window, to: .bottomRight)
                }
                return true
            case 125: // Down Arrow
                if modifiers.contains(.shift) {
                    snapWindow(window, to: .bottom)
                } else {
                    snapWindow(window, to: .center)
                }
                return true
            case 126: // Up Arrow
                if modifiers.contains(.shift) {
                    snapWindow(window, to: .top)
                } else {
                    snapWindow(window, to: .fullScreen)
                }
                return true
            default:
                break
            }
        }
        
        return false
    }
    
    /// Centers window on current screen
    func centerWindow(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        let centeredOrigin = CGPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2
        )
        
        let centeredFrame = CGRect(origin: centeredOrigin, size: windowSize)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = elasticAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(centeredFrame, display: true)
        }
    }
    
    /// Gets all available screens with their info
    func getAllScreens() -> [ScreenInfo] {
        return NSScreen.screens.enumerated().map { index, screen in
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            
            return ScreenInfo(
                screen: screen,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                displayID: displayID,
                isPrimary: index == 0
            )
        }
    }
    
    /// Moves window to specific screen
    func moveWindow(_ window: NSWindow, to screen: NSScreen, maintainRelativePosition: Bool = true) {
        let currentScreen = window.screen ?? NSScreen.main!
        let currentFrame = window.frame
        let currentScreenFrame = currentScreen.visibleFrame
        let targetScreenFrame = screen.visibleFrame
        
        var targetFrame: CGRect
        
        if maintainRelativePosition {
            // Calculate relative position on current screen
            let relativeX = (currentFrame.minX - currentScreenFrame.minX) / currentScreenFrame.width
            let relativeY = (currentFrame.minY - currentScreenFrame.minY) / currentScreenFrame.height
            
            // Apply to target screen
            targetFrame = CGRect(
                x: targetScreenFrame.minX + relativeX * targetScreenFrame.width,
                y: targetScreenFrame.minY + relativeY * targetScreenFrame.height,
                width: min(currentFrame.width, targetScreenFrame.width),
                height: min(currentFrame.height, targetScreenFrame.height)
            )
        } else {
            // Center on target screen
            targetFrame = CGRect(
                x: targetScreenFrame.midX - currentFrame.width / 2,
                y: targetScreenFrame.midY - currentFrame.height / 2,
                width: currentFrame.width,
                height: currentFrame.height
            )
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = elasticAnimationDuration
            window.animator().setFrame(targetFrame, display: true)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func getScreenInfo(for window: NSWindow) -> ScreenInfo? {
        guard let screen = window.screen ?? NSScreen.main else { return nil }
        return getAllScreens().first { $0.screen == screen }
    }
    
    private func distanceToRect(point: CGPoint, rect: CGRect) -> CGFloat {
        let dx = max(0, max(rect.minX - point.x, point.x - rect.maxX))
        let dy = max(0, max(rect.minY - point.y, point.y - rect.maxY))
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Smart screen detection based on mouse position
    private func getScreenForPoint(_ point: CGPoint) -> NSScreen? {
        return NSScreen.screens.first { screen in
            screen.frame.contains(point)
        }
    }
    
    /// Configuration methods
    func setSnapDistance(_ distance: CGFloat) {
        snapDistance = max(10.0, min(distance, 100.0))
    }
    
    func setMagneticDistance(_ distance: CGFloat) {
        magneticDistance = max(25.0, min(distance, 200.0))
    }
    
    func setAnimationDuration(_ duration: TimeInterval) {
        elasticAnimationDuration = max(0.1, min(duration, 1.0))
    }
}

// MARK: - SwiftUI Integration
struct SnapPreviewOverlay: View {
    @StateObject private var snappingManager = WindowSnappingManager.shared
    
    var body: some View {
        if snappingManager.snapPreviewVisible,
           let zone = snappingManager.currentSnapZone {
            
            ZStack {
                Rectangle()
                    .fill(.blue.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .stroke(.blue, lineWidth: 2)
                    )
                
                VStack(spacing: 8) {
                    Image(systemName: zone.icon)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.blue)
                    
                    Text(zone.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .cornerRadius(8)
            .animation(.easeInOut(duration: 0.2), value: snappingManager.currentSnapZone)
        }
    }
}
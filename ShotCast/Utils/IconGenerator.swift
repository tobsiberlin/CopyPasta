import Foundation
import AppKit
import SwiftUI
import CoreGraphics

class IconGenerator {
    static let shared = IconGenerator()
    
    private init() {}
    
    /// Creates a professional menubar template icon programmatically
    func createMenuBarTemplateIcon() -> NSImage? {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create professional icon design
        let rect = NSRect(origin: .zero, size: size)
        
        // Set up graphics context
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        context.setFillColor(NSColor.black.cgColor)
        
        // Create sleek icon design - resembling a screenshot/frame
        let path = NSBezierPath()
        
        // Outer frame (like screenshot border)
        path.appendRect(NSRect(x: 1, y: 1, width: 14, height: 10))
        path.lineWidth = 1.5
        path.stroke()
        
        // Inner elements (like content indicators)
        let dotSize: CGFloat = 1.5
        context.fillEllipse(in: NSRect(x: 3, y: 8, width: dotSize, height: dotSize))
        context.fillEllipse(in: NSRect(x: 6, y: 8, width: dotSize, height: dotSize))
        context.fillEllipse(in: NSRect(x: 9, y: 8, width: dotSize, height: dotSize))
        
        // Small "S" for ShotCast
        let font = NSFont.systemFont(ofSize: 6, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let sString = NSAttributedString(string: "S", attributes: attributes)
        sString.draw(at: NSPoint(x: 11.5, y: 3))
        
        image.unlockFocus()
        
        // Make it a template image for automatic theme adaptation
        image.isTemplate = true
        
        return image
    }
    
    /// Creates app icons in different sizes programmatically (for development)
    func createAppIcon(size: NSSize) -> NSImage? {
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        let rect = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
        
        // Create gradient background
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            CGColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
            CGColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1.0)
        ]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) else {
            image.unlockFocus()
            return nil
        }
        
        // Fill with gradient
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: size.height),
            end: CGPoint(x: size.width, y: 0),
            options: []
        )
        
        // Add rounded corners
        let cornerRadius = size.width * 0.15
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()
        
        // Add icon elements
        context.setFillColor(NSColor.white.cgColor)
        
        // Camera/Screenshot symbol
        let symbolSize = size.width * 0.6
        let symbolRect = CGRect(
            x: (size.width - symbolSize) / 2,
            y: (size.height - symbolSize) / 2,
            width: symbolSize,
            height: symbolSize * 0.7
        )
        
        // Frame
        let frameRect = symbolRect.insetBy(dx: symbolSize * 0.1, dy: symbolSize * 0.1)
        context.stroke(frameRect, width: size.width * 0.05)
        
        // Lens
        let lensRadius = symbolSize * 0.15
        let lensCenter = CGPoint(x: symbolRect.midX, y: symbolRect.midY)
        context.fillEllipse(in: CGRect(
            x: lensCenter.x - lensRadius/2,
            y: lensCenter.y - lensRadius/2,
            width: lensRadius,
            height: lensRadius
        ))
        
        image.unlockFocus()
        return image
    }
    
    /// Saves generated icons to Assets catalog
    func generateAndSaveIcons() {
        // This would save icons to the asset catalog
        // For now, we'll just generate them in memory
        
        let iconSizes: [CGFloat] = [16, 32, 128, 256, 512, 1024]
        
        for size in iconSizes {
            if let icon = createAppIcon(size: NSSize(width: size, height: size)) {
                print("Generated app icon for size: \(size)x\(size)")
                // In a real implementation, you'd save this to the asset catalog
            }
        }
        
        if let menuBarIcon = createMenuBarTemplateIcon() {
            print("Generated professional menubar template icon")
        }
    }
}

// MARK: - SwiftUI Integration
extension NSImage {
    /// Creates a template version of the image
    func asTemplate() -> NSImage {
        let templateImage = self.copy() as! NSImage
        templateImage.isTemplate = true
        return templateImage
    }
    
    /// Creates a resized version maintaining aspect ratio
    func resized(to size: NSSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        
        let sourceRect = NSRect(origin: .zero, size: self.size)
        let destRect = NSRect(origin: .zero, size: size)
        
        self.draw(in: destRect, from: sourceRect, operation: .sourceOver, fraction: 1.0)
        
        resizedImage.unlockFocus()
        return resizedImage
    }
}
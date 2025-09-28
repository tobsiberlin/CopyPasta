import SwiftUI

// SwiftUI View Extensions für bessere Animationen und Effekte
// SwiftUI View Extensions for better animations and effects
extension View {
    
    // Paste-Style Glow Effect
    func glowEffect(color: Color = .accentColor, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.5), radius: radius * 0.4, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
    
    // Smooth Spring Animation
    func smoothSpring() -> some View {
        self.animation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0))
    }
    
    // Hover Scale Effect
    func hoverScale(_ scale: CGFloat = 1.05) -> some View {
        self.modifier(HoverScaleModifier(scale: scale))
    }
    
    // Fade Transition
    func fadeTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.9)),
            removal: .opacity.combined(with: .scale(scale: 0.9))
        ))
    }
}

// Hover Scale Modifier
struct HoverScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

// Blur Background Modifier
struct BlurBackgroundModifier: ViewModifier {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func body(content: Content) -> some View {
        content
            .background(VisualEffectView(material: material, blendingMode: blendingMode))
    }
}

// Visual Effect View für macOS
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = material
        effectView.blendingMode = blendingMode
        effectView.state = .active
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// Conditional View Modifier
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
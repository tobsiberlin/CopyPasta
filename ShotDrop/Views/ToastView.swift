import SwiftUI

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    let duration: TimeInterval
    
    @State private var workItem: DispatchWorkItem?
    
    var body: some View {
        VStack {
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kopiert!")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThickMaterial)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.green.opacity(0.5), .mint.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
                .onAppear {
                    showToast()
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
    }
    
    private func showToast() {
        workItem?.cancel()
        
        let task = DispatchWorkItem {
            withAnimation {
                isShowing = false
            }
        }
        
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                
                ToastView(
                    message: message,
                    isShowing: $isShowing,
                    duration: duration
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, duration: TimeInterval = 2.0) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message, duration: duration))
    }
}
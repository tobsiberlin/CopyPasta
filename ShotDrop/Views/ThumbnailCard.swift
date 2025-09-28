import SwiftUI
import AppKit

struct ThumbnailCard: View {
    let item: ClipboardItem
    let isSelected: Bool
    let isHovered: Bool
    
    private var borderColor: Color {
        if isSelected {
            return .accentColor
        } else {
            return Color(NSColor.separatorColor).opacity(0.8)
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected {
            return 3.0
        } else if isHovered {
            return 2.0
        } else {
            return 1.5
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                        .animation(.easeInOut(duration: 0.2), value: borderWidth)
                        .animation(.easeInOut(duration: 0.2), value: borderColor)
                )
            
            if let nsImage = NSImage(data: item.imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(4)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
            
            if item.isFavorite {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
        .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
        .shadow(color: isSelected ? .accentColor.opacity(0.3) : .clear, radius: 8)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}
import SwiftUI

// Moderne Einstellungen-Ansicht
// Modern settings view
struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @EnvironmentObject var windowManager: WindowManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Settings Content
            settingsContent
                .padding()
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 450, height: 520)
        .background(.ultraThinMaterial)
    }
    
    // Header
    private var headerView: some View {
        HStack {
            Image(systemName: "doc.on.clipboard")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("CopyPasta Einstellungen")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Passe die Bottom Bar an deine Bedürfnisse an")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // Settings Content
    private var settingsContent: some View {
        VStack(spacing: 24) {
            // Bar-Höhe
            barHeightSection
            
            // Screenshot-Limit
            screenshotLimitSection
            
            // Verhalten
            behaviorSection
            
            // Darstellung
            appearanceSection
        }
    }
    
    // Bar-Höhe Sektion
    private var barHeightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.and.down")
                    .foregroundColor(.blue)
                Text("Bar-Höhe")
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                Slider(value: $settings.barHeight, in: 60...200, step: 10) {
                    Text("Höhe")
                } minimumValueLabel: {
                    Text("60")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("200")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .onChange(of: settings.barHeight) { _ in
                    windowManager.updateWindowFrame()
                }
                
                Text("\(Int(settings.barHeight)) Pixel")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // Screenshot-Limit Sektion
    private var screenshotLimitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.stack")
                    .foregroundColor(.green)
                Text("Screenshot-Speicher")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                HStack {
                    ForEach(AppSettings.ItemLimit.allCases, id: \.self) { limit in
                        Button(action: {
                            settings.currentItemLimit = limit
                        }) {
                            Text(limit.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(settings.currentItemLimit == limit ? .blue : .gray.opacity(0.2))
                                )
                                .foregroundColor(settings.currentItemLimit == limit ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                
                Text("Wie viele Screenshots sollen gespeichert werden?")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // Verhalten Sektion
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "automaticdoor.open")
                    .foregroundColor(.orange)
                Text("Verhalten")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Toggle("Automatisch öffnen bei Copy", isOn: $settings.autoShowOnCopy)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Auto-Hide nach:")
                        Spacer()
                        Text("\(settings.hideDelay, specifier: "%.1f")s")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settings.hideDelay, in: 1.0...10.0, step: 0.5)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // Darstellung Sektion
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintbrush")
                    .foregroundColor(.purple)
                Text("Darstellung")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Transparenz:")
                        Spacer()
                        Text("\(Int(settings.barOpacity * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settings.barOpacity, in: 0.5...1.0, step: 0.05)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Item-Abstand:")
                        Spacer()
                        Text("\(Int(settings.itemSpacing))px")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settings.itemSpacing, in: 4...20, step: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Rundungen:")
                        Spacer()
                        Text("\(Int(settings.cornerRadius))px")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settings.cornerRadius, in: 4...20, step: 2)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // Footer
    private var footerView: some View {
        HStack {
            Button("Zurücksetzen") {
                settings.resetToDefaults()
                windowManager.updateWindowFrame()
            }
            .foregroundColor(.red)
            
            Spacer()
            
            Button("Fertig") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
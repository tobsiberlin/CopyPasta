import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    private var effectiveColorScheme: ColorScheme {
        switch settings.themeMode {
        case .system: return colorScheme
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                        themeSection
                        appearanceSection
                        behaviorSection
                        advancedSection
                        aboutSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .preferredColorScheme(settings.themeMode == .system ? nil : 
                            (settings.themeMode == .light ? .light : .dark))
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(modernGradient)
                .padding(.top, 20)
            
            Text("ShotDrop")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(modernGradient)
            
            Text("Universal Clipboard für macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                backgroundGradient
                
                RoundedRectangle(cornerRadius: 0)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
            }
        )
    }
    
    private var modernGradient: LinearGradient {
        switch effectiveColorScheme {
        case .light:
            return LinearGradient(
                colors: [.blue, .cyan, .green],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .dark:
            return LinearGradient(
                colors: [.purple, .pink, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        @unknown default:
            return LinearGradient(
                colors: [.blue, .cyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var backgroundGradient: LinearGradient {
        switch effectiveColorScheme {
        case .light:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.95),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color.purple.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        @unknown default:
            return LinearGradient(
                colors: [.gray.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var themeSection: some View {
        SettingsSection(title: "Design", icon: "paintbrush") {
            VStack(spacing: 16) {
                HStack {
                    Text("Farbschema")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("Theme", selection: $settings.themeMode) {
                        ForEach(AppSettings.ThemeMode.allCases, id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.icon)
                                Text(mode.displayName)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "Erscheinungsbild", icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                SliderSetting(
                    title: "Bar Höhe",
                    value: $settings.barHeight,
                    range: 60...200,
                    unit: "px"
                )
                
                SliderSetting(
                    title: "Transparenz",
                    value: $settings.barOpacity,
                    range: 0.3...1.0,
                    unit: "%",
                    formatter: { String(format: "%.0f", $0 * 100) }
                )
                
                SliderSetting(
                    title: "Ecken Rundung",
                    value: $settings.cornerRadius,
                    range: 0...24,
                    unit: "px"
                )
                
                SliderSetting(
                    title: "Element Abstand",
                    value: $settings.itemSpacing,
                    range: 4...24,
                    unit: "px"
                )
            }
        }
    }
    
    private var behaviorSection: some View {
        SettingsSection(title: "Verhalten", icon: "gearshape") {
            VStack(spacing: 16) {
                ToggleSetting(
                    title: "Automatisch anzeigen beim Kopieren",
                    description: "Bottom Bar wird automatisch angezeigt wenn etwas kopiert wird",
                    isOn: $settings.autoShowOnCopy
                )
                
                ToggleSetting(
                    title: "Bei iOS Copy offen lassen",
                    description: "Bottom Bar bleibt offen wenn von iOS-Gerät kopiert wird",
                    isOn: $settings.keepOpenOnIOSCopy
                )
                
                ToggleSetting(
                    title: "Automatisch ausblenden",
                    description: "Bottom Bar wird nach einiger Zeit automatisch ausgeblendet",
                    isOn: $settings.autoHideEnabled
                )
                
                if settings.autoHideEnabled {
                    SliderSetting(
                        title: "Ausblende-Verzögerung",
                        value: $settings.hideDelay,
                        range: 1.0...10.0,
                        unit: "s"
                    )
                }
            }
        }
    }
    
    private var advancedSection: some View {
        SettingsSection(title: "Erweitert", icon: "wrench.and.screwdriver") {
            VStack(spacing: 16) {
                HStack {
                    Text("Maximale Anzahl Items")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("Item Limit", selection: $settings.currentItemLimit) {
                        ForEach(AppSettings.ItemLimit.allCases, id: \.self) { limit in
                            Text(limit.displayName).tag(limit)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                HStack {
                    Spacer()
                    
                    Button("Auf Standard zurücksetzen") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "Über ShotDrop", icon: "info.circle") {
            VStack(spacing: 12) {
                Text("Version 1.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Universal Clipboard Manager für macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 16) {
                content
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SliderSetting: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let unit: String
    let formatter: ((CGFloat) -> String)?
    
    init(title: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, unit: String, formatter: ((CGFloat) -> String)? = nil) {
        self.title = title
        self._value = value
        self.range = range
        self.unit = unit
        self.formatter = formatter
    }
    
    init(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, formatter: ((Double) -> String)? = nil) {
        self.title = title
        self._value = Binding(
            get: { CGFloat(value.wrappedValue) },
            set: { value.wrappedValue = Double($0) }
        )
        self.range = CGFloat(range.lowerBound)...CGFloat(range.upperBound)
        self.unit = unit
        self.formatter = formatter.map { f in { f(Double($0)) } }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formattedValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range)
                .accentColor(.accentColor)
        }
    }
    
    private var formattedValue: String {
        if let formatter = formatter {
            return formatter(value)
        } else {
            return "\(Int(value))\(unit)"
        }
    }
}

struct ToggleSetting: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    
    init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
        }
    }
}

#Preview {
    SettingsView()
}
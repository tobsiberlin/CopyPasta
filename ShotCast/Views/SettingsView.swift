import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedLanguage: String = "system"
    @State private var showLivePreview: Bool = true
    
    private var effectiveColorScheme: ColorScheme {
        switch settings.themeMode {
        case .system: return colorScheme
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            ScrollView {
                VStack(spacing: 20) {
                    themeSection
                    appearanceSection  
                    behaviorSection
                    languageSection
                    advancedSection
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(backgroundGradient)
        .preferredColorScheme(settings.themeMode == .system ? nil : 
                            (settings.themeMode == .light ? .light : .dark))
        .onAppear {
            startLivePreview()
        }
        .onDisappear {
            stopLivePreview()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(modernGradient)
                .padding(.top, 20)
            
            Text("ShotCast")
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
            HStack {
                Text("Farbschema")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Theme", selection: $settings.themeMode) {
                    ForEach(AppSettings.ThemeMode.allCases, id: \.self) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                                .font(.system(size: 12))
                            Text(mode.displayName)
                                .font(.caption)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                .controlSize(.small)
            }
        }
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "Erscheinungsbild", icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                SliderSetting(
                    title: "Größe",
                    value: $settings.screenshotSize,
                    range: 100...300,
                    unit: "px"
                )
                
                SliderSetting(
                    title: "Transparenz",
                    value: Binding(
                        get: { settings.transparencyPercentage },
                        set: { settings.transparencyPercentage = $0 }
                    ),
                    range: 0...70,
                    unit: "%",
                    formatter: { String(format: "%.0f", $0) }
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
    
    private var languageSection: some View {
        SettingsSection(title: "Sprache", icon: "globe") {
            VStack(spacing: 16) {
                HStack {
                    Text("App-Sprache")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Picker("Sprache", selection: $selectedLanguage) {
                        ForEach(getSupportedLanguages(), id: \.id) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.name)
                            }
                            .tag(language.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                
                Text("Die App wird nach einem Neustart in der gewählten Sprache angezeigt.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var aboutSection: some View {
        SettingsSection(title: "Über ShotCast", icon: "info.circle") {
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
    
    private func getSupportedLanguages() -> [LanguageOption] {
        return [
            LanguageOption(id: "system", name: "System", flag: "🖥️"),
            LanguageOption(id: "en", name: "English", flag: "🇺🇸"),
            LanguageOption(id: "de", name: "Deutsch", flag: "🇩🇪"),
            LanguageOption(id: "it", name: "Italiano", flag: "🇮🇹"),
            LanguageOption(id: "es", name: "Español", flag: "🇪🇸"),
            LanguageOption(id: "fr", name: "Français", flag: "🇫🇷"),
            LanguageOption(id: "ja", name: "日本語", flag: "🇯🇵"),
            LanguageOption(id: "zh", name: "中文", flag: "🇨🇳")
        ]
    }
    
    // MARK: - Live Preview Funktionen
    private func startLivePreview() {
        // Trigger für Live-Updates aktivieren
        showLivePreview = true
        
        // Bottom Bar automatisch anzeigen wenn Einstellungen geöffnet werden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if settings.autoShowOnCopy {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowBottomBarForPreview"),
                    object: nil
                )
            }
        }
    }
    
    private func stopLivePreview() {
        showLivePreview = false
        
        // Optional: Bottom Bar ausblenden wenn Einstellungen geschlossen werden
        if !settings.autoShowOnCopy {
            NotificationCenter.default.post(
                name: Notification.Name("HideBottomBarAfterPreview"),
                object: nil
            )
        }
    }
}

struct LanguageOption {
    let id: String
    let name: String
    let flag: String
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
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.accentColor, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1)
                }
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
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
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formattedValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
            }
            
            Slider(value: $value, in: range)
                .accentColor(.accentColor)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 6)
                )
                .onChange(of: value) { _, _ in
                    // Sofortige Live-Preview bei Änderungen
                    triggerLivePreview()
                }
        }
    }
    
    private var formattedValue: String {
        if let formatter = formatter {
            return formatter(value)
        } else {
            return "\(Int(value))\(unit)"
        }
    }
    
    private func triggerLivePreview() {
        // Triggert sofortige Updates in der Bottom Bar
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("SettingsLiveUpdate"),
                object: nil
            )
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
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .scaleEffect(0.9)
                .onChange(of: isOn) { _, _ in
                    triggerLivePreview()
                }
        }
        .padding(.vertical, 4)
    }
    
    private func triggerLivePreview() {
        // Triggert sofortige Updates in der Bottom Bar
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("SettingsLiveUpdate"),
                object: nil
            )
        }
    }
}

#Preview {
    SettingsView()
}
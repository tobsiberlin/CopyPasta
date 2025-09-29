import SwiftUI
import AppKit

struct ModernSettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "general"
        case appearance = "appearance"
        case advanced = "advanced"
        
        var title: LocalizationKey {
            switch self {
            case .general: return .settingsGeneral
            case .appearance: return .settingsAppearance
            case .advanced: return .settingsAdvanced
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintbrush"
            case .advanced: return "wrench.and.screwdriver"
            }
        }
    }
    
    private var effectiveColorScheme: ColorScheme {
        switch settings.themeMode {
        case .system: return colorScheme
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with Tabs
            VStack(spacing: 0) {
                headerSection
                    .padding(.bottom, 20)
                
                VStack(spacing: 8) {
                    ForEach(SettingsTab.allCases, id: \.rawValue) { tab in
                        tabButton(for: tab)
                    }
                }
                .padding(.horizontal, 12)
                
                Spacer()
                
                footerSection
                    .padding(.top, 20)
            }
            .frame(minWidth: 200, maxWidth: 250)
            .background(sidebarBackground)
        } detail: {
            // Main Content
            contentView
                .frame(minWidth: 450, maxWidth: .infinity)
                .background(contentBackground)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 750, minHeight: 550)
        .background(windowBackground)
        .preferredColorScheme(settings.themeMode == .system ? nil : 
                            (settings.themeMode == .light ? .light : .dark))
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(modernGradient)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            
            VStack(spacing: 4) {
                Text(localizationManager.localizedString(.appName))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(localizationManager.localizedString(.settingsTitle))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 12)
            
            Text("Version 1.0")
                .font(.caption2)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
            
            Text("© 2024")
                .font(.caption2)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
        }
        .padding(.bottom, 20)
    }
    
    private func tabButton(for tab: SettingsTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedTab == tab ? AnyShapeStyle(modernGradient) : AnyShapeStyle(Color.clear))
                        .frame(width: 32, height: 32)
                        .shadow(color: selectedTab == tab ? .black.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                }
                
                Text(localizationManager.localizedString(tab.title))
                    .font(.subheadline)
                    .fontWeight(selectedTab == tab ? .semibold : .medium)
                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThin.opacity(selectedTab == tab ? 1.0 : 0.0))
                    .stroke(selectedTab == tab ? .clear : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch selectedTab {
                case .general:
                    generalTabContent
                case .appearance:
                    appearanceTabContent
                case .advanced:
                    advancedTabContent
                }
            }
            .padding(32)
        }
        .navigationTitle(localizationManager.localizedString(selectedTab.title))
        // .navigationBarTitleDisplayMode(.large) // Not available on macOS
    }
    
    private var generalTabContent: some View {
        VStack(spacing: 24) {
            // Language Section
            ModernSettingsCard(
                title: localizationManager.localizedString(.settingsLanguage),
                icon: "globe"
            ) {
                VStack(spacing: 16) {
                    HStack {
                        Text(localizationManager.localizedString(.settingsLanguage))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("", selection: $localizationManager.currentLanguage) {
                            ForEach(LocalizationManager.SupportedLanguage.allCases, id: \.self) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }
            }
            
            // Theme Section
            ModernSettingsCard(
                title: localizationManager.localizedString(.settingsTheme),
                icon: "paintbrush"
            ) {
                VStack(spacing: 16) {
                    HStack {
                        Text(localizationManager.localizedString(.settingsTheme))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("", selection: $settings.themeMode) {
                            ForEach(AppSettings.ThemeMode.allCases, id: \.self) { mode in
                                HStack {
                                    Image(systemName: mode.icon)
                                    Text(mode.displayName)
                                }
                                .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
            }
            
            // Behavior Section
            ModernSettingsCard(
                title: localizationManager.localizedString(.settingsBehavior),
                icon: "gearshape"
            ) {
                VStack(spacing: 20) {
                    ModernToggleSetting(
                        title: localizationManager.localizedString(.settingsAutoShow),
                        description: localizationManager.localizedString(.settingsAutoShowDescription),
                        isOn: $settings.autoShowOnCopy
                    )
                    
                    ModernToggleSetting(
                        title: localizationManager.localizedString(.settingsLaunchAtLogin),
                        description: localizationManager.localizedString(.settingsLaunchAtLoginDescription),
                        isOn: $settings.keepOpenOnIOSCopy
                    )
                    
                    ModernToggleSetting(
                        title: localizationManager.localizedString(.settingsAutoHide),
                        description: localizationManager.localizedString(.settingsAutoHideDescription),
                        isOn: $settings.autoHideEnabled
                    )
                    
                    if settings.autoHideEnabled {
                        ModernSliderSetting(
                            title: localizationManager.localizedString(.settingsHideDelay),
                            value: $settings.hideDelay,
                            range: 1.0...10.0,
                            unit: "s"
                        )
                    }
                }
            }
        }
    }
    
    private var appearanceTabContent: some View {
        VStack(spacing: 24) {
            ModernSettingsCard(
                title: localizationManager.localizedString(.settingsAppearance),
                icon: "slider.horizontal.3"
            ) {
                VStack(spacing: 20) {
                    ModernSliderSetting(
                        title: localizationManager.localizedString(.settingsBarHeight),
                        value: $settings.barHeight,
                        range: 60...200,
                        unit: "px"
                    )
                    
                    ModernSliderSetting(
                        title: localizationManager.localizedString(.settingsBarOpacity),
                        value: $settings.barOpacity,
                        range: 0.3...1.0,
                        unit: "%",
                        formatter: { String(format: "%.0f", $0 * 100) }
                    )
                    
                    ModernSliderSetting(
                        title: localizationManager.localizedString(.settingsCornerRadius),
                        value: $settings.cornerRadius,
                        range: 0...24,
                        unit: "px"
                    )
                    
                    ModernSliderSetting(
                        title: localizationManager.localizedString(.settingsItemSpacing),
                        value: $settings.itemSpacing,
                        range: 4...24,
                        unit: "px"
                    )
                }
            }
        }
    }
    
    private var advancedTabContent: some View {
        VStack(spacing: 24) {
            ModernSettingsCard(
                title: localizationManager.localizedString(.settingsAdvanced),
                icon: "wrench.and.screwdriver"
            ) {
                VStack(spacing: 20) {
                    HStack {
                        Text(localizationManager.localizedString(.settingsMaxItems))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("", selection: $settings.currentItemLimit) {
                            ForEach(AppSettings.ItemLimit.allCases, id: \.self) { limit in
                                Text(limit.displayName).tag(limit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    
                    Divider()
                    
                    HStack {
                        Spacer()
                        
                        Button(localizationManager.localizedString(.settingsResetDefaults)) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                settings.resetToDefaults()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
            }
        }
    }
    
    // MARK: - Styling
    
    private var modernGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var sidebarBackground: some View {
        ZStack {
            Color(NSColor.controlBackgroundColor)
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primary.opacity(0.02),
                    Color.primary.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var contentBackground: some View {
        ZStack {
            Color(NSColor.textBackgroundColor)
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primary.opacity(0.01),
                    Color.primary.opacity(0.03)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
    
    private var windowBackground: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.03),
                    Color.pink.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Modern Settings Components

struct ModernSettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}

struct ModernSliderSetting: View {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .stroke(.quaternary, lineWidth: 1)
                    )
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

struct ModernToggleSetting: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    
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
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModernSettingsView()
}
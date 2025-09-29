import Foundation
import SwiftUI

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    enum Language: String, CaseIterable {
        case system = "system"
        case english = "en"
        case german = "de"
        case italian = "it"
        case spanish = "es"
        case french = "fr"
        case japanese = "ja"
        case chinese = "zh"
        
        var displayName: String {
            switch self {
            case .system: return "System"
            case .english: return "English"
            case .german: return "Deutsch"
            case .italian: return "Italiano"
            case .spanish: return "Español"
            case .french: return "Français"
            case .japanese: return "日本語"
            case .chinese: return "中文"
            }
        }
        
        var flag: String {
            switch self {
            case .system: return "🌐"
            case .english: return "🇺🇸"
            case .german: return "🇩🇪"
            case .italian: return "🇮🇹"
            case .spanish: return "🇪🇸"
            case .french: return "🇫🇷"
            case .japanese: return "🇯🇵"
            case .chinese: return "🇨🇳"
            }
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "system"
        self.currentLanguage = Language(rawValue: savedLanguage) ?? .system
    }
    
    var effectiveLanguage: Language {
        if currentLanguage == .system {
            // Erkenne Systemsprache
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            return Language(rawValue: systemLanguage) ?? .english
        }
        return currentLanguage
    }
}

// MARK: - Localized Strings
enum LocalizedString {
    // App Info
    case appName
    case appDescription
    
    // Tabs
    case tabGeneral
    case tabShots
    case tabShortcuts
    case tabAppearance
    
    // General Settings
    case designSection
    case behaviorSection
    case colorScheme
    case autoShowOnCopy
    case autoShowOnCopyDescription
    case keepOpenOnIOSCopy
    case keepOpenOnIOSCopyDescription
    case autoHide
    case autoHideDescription
    case hideDelay
    case language
    
    // Shot Settings
    case shotManagement
    case maxShots
    case resetAndCleanup
    case deleteAllShots
    case deleteAllShotsDescription
    case deleteButton
    case resetToDefaults
    
    // Appearance Settings
    case livePreview
    case barSettings
    case barHeight
    case transparency
    case cornerRadius
    case shotSpacing
    
    // Shortcuts
    case hotkeys
    case openShotDrop
    case globalHotkey
    case changeButton
    case recordingPrompt
    case hotkeyPlaceholder
    
    // About
    case aboutShotDrop
    case version
    case universalClipboard
    
    // UI Elements
    case settingsTooltip
    case closeTooltip
    case ocrTooltip
    case noClipboardContent
    case copyButton
    case favoriteButton
    case unfavoriteButton
    case saveAsFile
    case deleteItem
    
    // Toast Messages
    case textCopied
    case textCopiedDescription
    case ocrExtracted
    
    // File Types
    case fileTypeImage
    case fileTypeText
    case fileTypePDF
    case fileTypeVideo
    case fileTypeAudio
    case fileTypeDocument
    case fileTypeArchive
    case fileTypeOther
    
    var localized: String {
        let language = LocalizationManager.shared.effectiveLanguage
        return getLocalizedString(for: language)
    }
    
    private func getLocalizedString(for language: LocalizationManager.Language) -> String {
        switch language {
        case .system, .english:
            return englishStrings
        case .german:
            return germanStrings
        case .italian:
            return italianStrings
        case .spanish:
            return spanishStrings
        case .french:
            return frenchStrings
        case .japanese:
            return japaneseStrings
        case .chinese:
            return chineseStrings
        }
    }
    
    // MARK: - English Strings
    private var englishStrings: String {
        switch self {
        case .appName: return "ShotDrop"
        case .appDescription: return "Universal Clipboard for macOS"
        case .tabGeneral: return "General"
        case .tabShots: return "Shots"
        case .tabShortcuts: return "Shortcuts"
        case .tabAppearance: return "Appearance"
        case .designSection: return "Design"
        case .behaviorSection: return "Behavior"
        case .colorScheme: return "Color Scheme"
        case .autoShowOnCopy: return "Auto-show when copying"
        case .autoShowOnCopyDescription: return "Bottom bar appears automatically when something is copied"
        case .keepOpenOnIOSCopy: return "Keep open on iOS copy"
        case .keepOpenOnIOSCopyDescription: return "Bottom bar stays open when copied from iOS device"
        case .autoHide: return "Auto-hide"
        case .autoHideDescription: return "Bottom bar hides automatically after some time"
        case .hideDelay: return "Hide delay"
        case .language: return "Language"
        case .shotManagement: return "Shot Management"
        case .maxShots: return "Maximum shots"
        case .resetAndCleanup: return "Reset & Cleanup"
        case .deleteAllShots: return "Delete all shots"
        case .deleteAllShotsDescription: return "Removes all saved screenshots and texts"
        case .deleteButton: return "Delete"
        case .resetToDefaults: return "Reset to defaults"
        case .livePreview: return "Live Preview"
        case .barSettings: return "Bar Settings"
        case .barHeight: return "Bar height"
        case .transparency: return "Transparency"
        case .cornerRadius: return "Corner radius"
        case .shotSpacing: return "Shot spacing"
        case .hotkeys: return "Hotkeys"
        case .openShotDrop: return "Open ShotDrop"
        case .globalHotkey: return "Global hotkey to open ShotDrop"
        case .changeButton: return "Change"
        case .recordingPrompt: return "Press the desired key combination..."
        case .hotkeyPlaceholder: return "🚧 Hotkey functionality will be implemented"
        case .aboutShotDrop: return "About ShotDrop"
        case .version: return "Version 1.0"
        case .universalClipboard: return "Universal Clipboard Manager for macOS"
        case .settingsTooltip: return "ShotDrop Settings"
        case .closeTooltip: return "Close ShotDrop"
        case .ocrTooltip: return "Extract text via OCR"
        case .noClipboardContent: return "No clipboard content"
        case .copyButton: return "Copy"
        case .favoriteButton: return "Add to favorites"
        case .unfavoriteButton: return "Remove from favorites"
        case .saveAsFile: return "Save as file..."
        case .deleteItem: return "Delete"
        case .textCopied: return "Copied!"
        case .textCopiedDescription: return "Text copied to clipboard and can be pasted into tools"
        case .ocrExtracted: return "Text extracted from image and copied to clipboard"
        case .fileTypeImage: return "Image"
        case .fileTypeText: return "Text"
        case .fileTypePDF: return "PDF"
        case .fileTypeVideo: return "Video"
        case .fileTypeAudio: return "Audio"
        case .fileTypeDocument: return "Document"
        case .fileTypeArchive: return "Archive"
        case .fileTypeOther: return "File"
        }
    }
    
    // MARK: - German Strings
    private var germanStrings: String {
        switch self {
        case .appName: return "ShotDrop"
        case .appDescription: return "Universal Clipboard für macOS"
        case .tabGeneral: return "Allgemein"
        case .tabShots: return "Shots"
        case .tabShortcuts: return "Shortcuts"
        case .tabAppearance: return "Erscheinungsbild"
        case .designSection: return "Design"
        case .behaviorSection: return "Verhalten"
        case .colorScheme: return "Farbschema"
        case .autoShowOnCopy: return "Automatisch anzeigen beim Kopieren"
        case .autoShowOnCopyDescription: return "Bottom Bar wird automatisch angezeigt wenn etwas kopiert wird"
        case .keepOpenOnIOSCopy: return "Bei iOS Copy offen lassen"
        case .keepOpenOnIOSCopyDescription: return "Bottom Bar bleibt offen wenn von iOS-Gerät kopiert wird"
        case .autoHide: return "Automatisch ausblenden"
        case .autoHideDescription: return "Bottom Bar wird nach einiger Zeit automatisch ausgeblendet"
        case .hideDelay: return "Ausblende-Verzögerung"
        case .language: return "Sprache"
        case .shotManagement: return "Shot-Verwaltung"
        case .maxShots: return "Maximale Anzahl Shots"
        case .resetAndCleanup: return "Reset & Bereinigung"
        case .deleteAllShots: return "Alle Shots löschen"
        case .deleteAllShotsDescription: return "Entfernt alle gespeicherten Screenshots und Texte"
        case .deleteButton: return "Löschen"
        case .resetToDefaults: return "Auf Standard zurücksetzen"
        case .livePreview: return "Live-Vorschau"
        case .barSettings: return "Bar-Einstellungen"
        case .barHeight: return "Bar Höhe"
        case .transparency: return "Transparenz"
        case .cornerRadius: return "Ecken Rundung"
        case .shotSpacing: return "Shot Abstand"
        case .hotkeys: return "Tastenkombinationen"
        case .openShotDrop: return "ShotDrop öffnen"
        case .globalHotkey: return "Globale Tastenkombination zum Öffnen von ShotDrop"
        case .changeButton: return "Ändern"
        case .recordingPrompt: return "Drücken Sie die gewünschte Tastenkombination..."
        case .hotkeyPlaceholder: return "🚧 Hotkey-Funktionalität wird implementiert"
        case .aboutShotDrop: return "Über ShotDrop"
        case .version: return "Version 1.0"
        case .universalClipboard: return "Universal Clipboard Manager für macOS"
        case .settingsTooltip: return "ShotDrop Einstellungen"
        case .closeTooltip: return "ShotDrop schließen"
        case .ocrTooltip: return "Text per OCR extrahieren"
        case .noClipboardContent: return "Keine Inhalte im Clipboard"
        case .copyButton: return "Kopieren"
        case .favoriteButton: return "Zu Favoriten"
        case .unfavoriteButton: return "Aus Favoriten"
        case .saveAsFile: return "Als Datei speichern..."
        case .deleteItem: return "Löschen"
        case .textCopied: return "Kopiert!"
        case .textCopiedDescription: return "Text wurde in die Zwischenablage kopiert und kann jetzt in Tools eingefügt werden"
        case .ocrExtracted: return "Text aus Bild extrahiert und in Zwischenablage kopiert"
        case .fileTypeImage: return "Bild"
        case .fileTypeText: return "Text"
        case .fileTypePDF: return "PDF"
        case .fileTypeVideo: return "Video"
        case .fileTypeAudio: return "Audio"
        case .fileTypeDocument: return "Dokument"
        case .fileTypeArchive: return "Archiv"
        case .fileTypeOther: return "Datei"
        }
    }
    
    // MARK: - Italian Strings
    private var italianStrings: String {
        switch self {
        case .appName: return "ShotDrop"
        case .appDescription: return "Clipboard Universale per macOS"
        case .tabGeneral: return "Generale"
        case .tabShots: return "Shots"
        case .tabShortcuts: return "Scorciatoie"
        case .tabAppearance: return "Aspetto"
        case .designSection: return "Design"
        case .behaviorSection: return "Comportamento"
        case .colorScheme: return "Schema colori"
        case .autoShowOnCopy: return "Mostra automaticamente quando si copia"
        case .autoShowOnCopyDescription: return "La barra inferiore appare automaticamente quando si copia qualcosa"
        case .keepOpenOnIOSCopy: return "Mantieni aperto su copia iOS"
        case .keepOpenOnIOSCopyDescription: return "La barra inferiore rimane aperta quando si copia da dispositivo iOS"
        case .autoHide: return "Nascondi automaticamente"
        case .autoHideDescription: return "La barra inferiore si nasconde automaticamente dopo un po'"
        case .hideDelay: return "Ritardo nascondimento"
        case .language: return "Lingua"
        case .shotManagement: return "Gestione Shot"
        case .maxShots: return "Massimo shots"
        case .resetAndCleanup: return "Reset e Pulizia"
        case .deleteAllShots: return "Elimina tutti gli shot"
        case .deleteAllShotsDescription: return "Rimuove tutti gli screenshot e testi salvati"
        case .deleteButton: return "Elimina"
        case .resetToDefaults: return "Ripristina predefiniti"
        case .livePreview: return "Anteprima Live"
        case .barSettings: return "Impostazioni Barra"
        case .barHeight: return "Altezza barra"
        case .transparency: return "Trasparenza"
        case .cornerRadius: return "Raggio angoli"
        case .shotSpacing: return "Spaziatura shot"
        case .hotkeys: return "Tasti rapidi"
        case .openShotDrop: return "Apri ShotDrop"
        case .globalHotkey: return "Tasto rapido globale per aprire ShotDrop"
        case .changeButton: return "Cambia"
        case .recordingPrompt: return "Premi la combinazione di tasti desiderata..."
        case .hotkeyPlaceholder: return "🚧 Funzionalità tasti rapidi sarà implementata"
        case .aboutShotDrop: return "Informazioni su ShotDrop"
        case .version: return "Versione 1.0"
        case .universalClipboard: return "Gestore Clipboard Universale per macOS"
        case .settingsTooltip: return "Impostazioni ShotDrop"
        case .closeTooltip: return "Chiudi ShotDrop"
        case .ocrTooltip: return "Estrai testo tramite OCR"
        case .noClipboardContent: return "Nessun contenuto negli appunti"
        case .copyButton: return "Copia"
        case .favoriteButton: return "Aggiungi ai preferiti"
        case .unfavoriteButton: return "Rimuovi dai preferiti"
        case .saveAsFile: return "Salva come file..."
        case .deleteItem: return "Elimina"
        case .textCopied: return "Copiato!"
        case .textCopiedDescription: return "Testo copiato negli appunti e può essere incollato negli strumenti"
        case .ocrExtracted: return "Testo estratto dall'immagine e copiato negli appunti"
        case .fileTypeImage: return "Immagine"
        case .fileTypeText: return "Testo"
        case .fileTypePDF: return "PDF"
        case .fileTypeVideo: return "Video"
        case .fileTypeAudio: return "Audio"
        case .fileTypeDocument: return "Documento"
        case .fileTypeArchive: return "Archivio"
        case .fileTypeOther: return "File"
        }
    }
    
    // MARK: - Spanish Strings
    private var spanishStrings: String {
        switch self {
        case .appName: return "ShotDrop"
        case .appDescription: return "Portapapeles Universal para macOS"
        case .tabGeneral: return "General"
        case .tabShots: return "Shots"
        case .tabShortcuts: return "Atajos"
        case .tabAppearance: return "Apariencia"
        case .designSection: return "Diseño"
        case .behaviorSection: return "Comportamiento"
        case .colorScheme: return "Esquema de colores"
        case .autoShowOnCopy: return "Mostrar automáticamente al copiar"
        case .autoShowOnCopyDescription: return "La barra inferior aparece automáticamente cuando se copia algo"
        case .keepOpenOnIOSCopy: return "Mantener abierto en copia iOS"
        case .keepOpenOnIOSCopyDescription: return "La barra inferior permanece abierta cuando se copia desde dispositivo iOS"
        case .autoHide: return "Ocultar automáticamente"
        case .autoHideDescription: return "La barra inferior se oculta automáticamente después de un tiempo"
        case .hideDelay: return "Retraso de ocultación"
        case .language: return "Idioma"
        case .shotManagement: return "Gestión de Shots"
        case .maxShots: return "Máximo shots"
        case .resetAndCleanup: return "Reset y Limpieza"
        case .deleteAllShots: return "Eliminar todos los shots"
        case .deleteAllShotsDescription: return "Elimina todas las capturas de pantalla y textos guardados"
        case .deleteButton: return "Eliminar"
        case .resetToDefaults: return "Restaurar predeterminados"
        case .livePreview: return "Vista Previa en Vivo"
        case .barSettings: return "Configuración de Barra"
        case .barHeight: return "Altura de barra"
        case .transparency: return "Transparencia"
        case .cornerRadius: return "Radio de esquinas"
        case .shotSpacing: return "Espaciado de shot"
        case .hotkeys: return "Teclas de acceso rápido"
        case .openShotDrop: return "Abrir ShotDrop"
        case .globalHotkey: return "Tecla de acceso rápido global para abrir ShotDrop"
        case .changeButton: return "Cambiar"
        case .recordingPrompt: return "Presiona la combinación de teclas deseada..."
        case .hotkeyPlaceholder: return "🚧 Funcionalidad de teclas rápidas será implementada"
        case .aboutShotDrop: return "Acerca de ShotDrop"
        case .version: return "Versión 1.0"
        case .universalClipboard: return "Gestor de Portapapeles Universal para macOS"
        case .settingsTooltip: return "Configuración de ShotDrop"
        case .closeTooltip: return "Cerrar ShotDrop"
        case .ocrTooltip: return "Extraer texto via OCR"
        case .noClipboardContent: return "Sin contenido en el portapapeles"
        case .copyButton: return "Copiar"
        case .favoriteButton: return "Añadir a favoritos"
        case .unfavoriteButton: return "Quitar de favoritos"
        case .saveAsFile: return "Guardar como archivo..."
        case .deleteItem: return "Eliminar"
        case .textCopied: return "¡Copiado!"
        case .textCopiedDescription: return "Texto copiado al portapapeles y puede ser pegado en herramientas"
        case .ocrExtracted: return "Texto extraído de la imagen y copiado al portapapeles"
        case .fileTypeImage: return "Imagen"
        case .fileTypeText: return "Texto"
        case .fileTypePDF: return "PDF"
        case .fileTypeVideo: return "Video"
        case .fileTypeAudio: return "Audio"
        case .fileTypeDocument: return "Documento"
        case .fileTypeArchive: return "Archivo"
        case .fileTypeOther: return "Archivo"
        }
    }
    
    // MARK: - French Strings
    private var frenchStrings: String {
        switch self {
        case .appName: return "ShotDrop"
        case .appDescription: return "Presse-papiers Universel pour macOS"
        case .tabGeneral: return "Général"
        case .tabShots: return "Shots"
        case .tabShortcuts: return "Raccourcis"
        case .tabAppearance: return "Apparence"
        case .designSection: return "Design"
        case .behaviorSection: return "Comportement"
        case .colorScheme: return "Schéma de couleurs"
        case .autoShowOnCopy: return "Afficher automatiquement lors de la copie"
        case .autoShowOnCopyDescription: return "La barre inférieure apparaît automatiquement quand quelque chose est copié"
        case .keepOpenOnIOSCopy: return "Garder ouvert sur copie iOS"
        case .keepOpenOnIOSCopyDescription: return "La barre inférieure reste ouverte quand copié depuis appareil iOS"
        case .autoHide: return "Masquer automatiquement"
        case .autoHideDescription: return "La barre inférieure se masque automatiquement après un certain temps"
        case .hideDelay: return "Délai de masquage"
        case .language: return "Langue"
        case .shotManagement: return "Gestion des Shots"
        case .maxShots: return "Maximum shots"
        case .resetAndCleanup: return "Reset et Nettoyage"
        case .deleteAllShots: return "Supprimer tous les shots"
        case .deleteAllShotsDescription: return "Supprime toutes les captures d'écran et textes sauvegardés"
        case .deleteButton: return "Supprimer"
        case .resetToDefaults: return "Restaurer par défaut"
        case .livePreview: return "Aperçu en Direct"
        case .barSettings: return "Paramètres de Barre"
        case .barHeight: return "Hauteur de barre"
        case .transparency: return "Transparence"
        case .cornerRadius: return "Rayon des coins"
        case .shotSpacing: return "Espacement des shots"
        case .hotkeys: return "Raccourcis clavier"
        case .openShotDrop: return "Ouvrir ShotDrop"
        case .globalHotkey: return "Raccourci clavier global pour ouvrir ShotDrop"
        case .changeButton: return "Changer"
        case .recordingPrompt: return "Appuyez sur la combinaison de touches désirée..."
        case .hotkeyPlaceholder: return "🚧 Fonctionnalité raccourcis sera implémentée"
        case .aboutShotDrop: return "À propos de ShotDrop"
        case .version: return "Version 1.0"
        case .universalClipboard: return "Gestionnaire de Presse-papiers Universel pour macOS"
        case .settingsTooltip: return "Paramètres ShotDrop"
        case .closeTooltip: return "Fermer ShotDrop"
        case .ocrTooltip: return "Extraire texte via OCR"
        case .noClipboardContent: return "Aucun contenu dans le presse-papiers"
        case .copyButton: return "Copier"
        case .favoriteButton: return "Ajouter aux favoris"
        case .unfavoriteButton: return "Retirer des favoris"
        case .saveAsFile: return "Sauvegarder comme fichier..."
        case .deleteItem: return "Supprimer"
        case .textCopied: return "Copié !"
        case .textCopiedDescription: return "Texte copié dans le presse-papiers et peut être collé dans les outils"
        case .ocrExtracted: return "Texte extrait de l'image et copié dans le presse-papiers"
        case .fileTypeImage: return "Image"
        case .fileTypeText: return "Texte"
        case .fileTypePDF: return "PDF"
        case .fileTypeVideo: return "Vidéo"
        case .fileTypeAudio: return "Audio"
        case .fileTypeDocument: return "Document"
        case .fileTypeArchive: return "Archive"
        case .fileTypeOther: return "Fichier"
        }
    }
    
    // MARK: - Japanese Strings
    private var japaneseStrings: String {
        switch self {
        case .appName: return "ShotDrop"
        case .appDescription: return "macOS用ユニバーサルクリップボード"
        case .tabGeneral: return "一般"
        case .tabShots: return "ショット"
        case .tabShortcuts: return "ショートカット"
        case .tabAppearance: return "外観"
        case .designSection: return "デザイン"
        case .behaviorSection: return "動作"
        case .colorScheme: return "カラースキーム"
        case .autoShowOnCopy: return "コピー時に自動表示"
        case .autoShowOnCopyDescription: return "何かがコピーされた時にボトムバーが自動的に表示されます"
        case .keepOpenOnIOSCopy: return "iOSコピー時は開いたまま"
        case .keepOpenOnIOSCopyDescription: return "iOSデバイスからコピーされた時にボトムバーが開いたままになります"
        case .autoHide: return "自動非表示"
        case .autoHideDescription: return "しばらくするとボトムバーが自動的に非表示になります"
        case .hideDelay: return "非表示遅延"
        case .language: return "言語"
        case .shotManagement: return "ショット管理"
        case .maxShots: return "最大ショット数"
        case .resetAndCleanup: return "リセットとクリーンアップ"
        case .deleteAllShots: return "すべてのショットを削除"
        case .deleteAllShotsDescription: return "保存されたすべてのスクリーンショットとテキストを削除します"
        case .deleteButton: return "削除"
        case .resetToDefaults: return "デフォルトにリセット"
        case .livePreview: return "ライブプレビュー"
        case .barSettings: return "バー設定"
        case .barHeight: return "バーの高さ"
        case .transparency: return "透明度"
        case .cornerRadius: return "角の丸み"
        case .shotSpacing: return "ショット間隔"
        case .hotkeys: return "ホットキー"
        case .openShotDrop: return "ShotDropを開く"
        case .globalHotkey: return "ShotDropを開くグローバルホットキー"
        case .changeButton: return "変更"
        case .recordingPrompt: return "希望するキーの組み合わせを押してください..."
        case .hotkeyPlaceholder: return "🚧 ホットキー機能は実装予定です"
        case .aboutShotDrop: return "ShotDropについて"
        case .version: return "バージョン 1.0"
        case .universalClipboard: return "macOS用ユニバーサルクリップボードマネージャー"
        case .settingsTooltip: return "ShotDrop設定"
        case .closeTooltip: return "ShotDropを閉じる"
        case .ocrTooltip: return "OCRでテキストを抽出"
        case .noClipboardContent: return "クリップボードにコンテンツがありません"
        case .copyButton: return "コピー"
        case .favoriteButton: return "お気に入りに追加"
        case .unfavoriteButton: return "お気に入りから削除"
        case .saveAsFile: return "ファイルとして保存..."
        case .deleteItem: return "削除"
        case .textCopied: return "コピーしました！"
        case .textCopiedDescription: return "テキストがクリップボードにコピーされ、ツールに貼り付けることができます"
        case .ocrExtracted: return "画像からテキストを抽出してクリップボードにコピーしました"
        case .fileTypeImage: return "画像"
        case .fileTypeText: return "テキスト"
        case .fileTypePDF: return "PDF"
        case .fileTypeVideo: return "動画"
        case .fileTypeAudio: return "音声"
        case .fileTypeDocument: return "文書"
        case .fileTypeArchive: return "アーカイブ"
        case .fileTypeOther: return "ファイル"
        }
    }
    
    // MARK: - Chinese Strings
    private var chineseStrings: String {
        switch self {
        case .appName: return "ShotDrop"
        case .appDescription: return "macOS通用剪贴板"
        case .tabGeneral: return "常规"
        case .tabShots: return "截图"
        case .tabShortcuts: return "快捷键"
        case .tabAppearance: return "外观"
        case .designSection: return "设计"
        case .behaviorSection: return "行为"
        case .colorScheme: return "配色方案"
        case .autoShowOnCopy: return "复制时自动显示"
        case .autoShowOnCopyDescription: return "复制内容时底部栏自动显示"
        case .keepOpenOnIOSCopy: return "iOS复制时保持打开"
        case .keepOpenOnIOSCopyDescription: return "从iOS设备复制时底部栏保持打开"
        case .autoHide: return "自动隐藏"
        case .autoHideDescription: return "一段时间后底部栏自动隐藏"
        case .hideDelay: return "隐藏延迟"
        case .language: return "语言"
        case .shotManagement: return "截图管理"
        case .maxShots: return "最大截图数"
        case .resetAndCleanup: return "重置和清理"
        case .deleteAllShots: return "删除所有截图"
        case .deleteAllShotsDescription: return "删除所有保存的截图和文本"
        case .deleteButton: return "删除"
        case .resetToDefaults: return "重置为默认值"
        case .livePreview: return "实时预览"
        case .barSettings: return "栏设置"
        case .barHeight: return "栏高度"
        case .transparency: return "透明度"
        case .cornerRadius: return "圆角半径"
        case .shotSpacing: return "截图间距"
        case .hotkeys: return "热键"
        case .openShotDrop: return "打开ShotDrop"
        case .globalHotkey: return "打开ShotDrop的全局热键"
        case .changeButton: return "更改"
        case .recordingPrompt: return "请按下所需的按键组合..."
        case .hotkeyPlaceholder: return "🚧 热键功能将被实现"
        case .aboutShotDrop: return "关于ShotDrop"
        case .version: return "版本 1.0"
        case .universalClipboard: return "macOS通用剪贴板管理器"
        case .settingsTooltip: return "ShotDrop设置"
        case .closeTooltip: return "关闭ShotDrop"
        case .ocrTooltip: return "通过OCR提取文本"
        case .noClipboardContent: return "剪贴板中没有内容"
        case .copyButton: return "复制"
        case .favoriteButton: return "添加到收藏"
        case .unfavoriteButton: return "从收藏中移除"
        case .saveAsFile: return "另存为文件..."
        case .deleteItem: return "删除"
        case .textCopied: return "已复制！"
        case .textCopiedDescription: return "文本已复制到剪贴板，可以粘贴到工具中"
        case .ocrExtracted: return "从图像中提取文本并复制到剪贴板"
        case .fileTypeImage: return "图像"
        case .fileTypeText: return "文本"
        case .fileTypePDF: return "PDF"
        case .fileTypeVideo: return "视频"
        case .fileTypeAudio: return "音频"
        case .fileTypeDocument: return "文档"
        case .fileTypeArchive: return "存档"
        case .fileTypeOther: return "文件"
        }
    }
}

// MARK: - View Extension for easy localization
extension Text {
    init(_ localizedString: LocalizedString) {
        self.init(localizedString.localized)
    }
}
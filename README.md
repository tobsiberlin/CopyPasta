# ShotCast - Der automatische Universal Clipboard Manager

<p align="center">
  <img src="assets/logo.png" width="120" height="120" alt="ShotCast Logo">
</p>

ShotCast ist ein nativer macOS Universal Clipboard Manager, der automatisch aktiviert wird, wenn Sie Bilder von Ihrem iPhone kopieren. Inspiriert vom eleganten Design der Paste App, bietet ShotCast eine moderne und intuitive Oberfläche für die Verwaltung Ihrer kopierten Bilder.

## ✨ Hauptfunktionen

### 🚀 Auto-Activation
- **Automatische Fensteröffnung**: ShotCast öffnet sich automatisch, wenn Sie ein Bild auf Ihrem iPhone kopieren
- **Keine Tastenkombination erforderlich**: Das Fenster erscheint magisch von selbst
- **Smart Detection**: Erkennt Universal Clipboard-Inhalte und unterscheidet zwischen lokalen und iPhone-Kopien

### 🎨 Paste-inspiriertes Design
- **Modernes Grid Layout**: Flexible 2-6 Spalten Ansicht
- **Smooth Animations**: Flüssige Übergänge und Hover-Effekte
- **Dark Mode Support**: Perfekte Integration in macOS
- **Preview Mode**: Vollbild-Vorschau mit Zoom und Pan

### 🔧 Leistungsstarke Features
- **Background Monitoring**: Läuft unauffällig im Hintergrund
- **Smart Thumbnails**: Intelligentes Cropping für perfekte Vorschauen
- **Multi-Format Support**: PNG, JPEG, HEIC, WebP und mehr
- **Drag & Drop**: Ziehen Sie Bilder direkt in andere Apps
- **Favoriten-System**: Markieren Sie wichtige Bilder
- **Keyboard Shortcuts**: Schnelle Navigation und Aktionen

## 📋 Voraussetzungen

- macOS 14.0 (Sonoma) oder höher
- Apple ID mit aktiviertem iCloud
- Handoff zwischen Mac und iPhone aktiviert

### Universal Clipboard einrichten:
1. Auf beiden Geräten mit derselben Apple ID angemeldet sein
2. Bluetooth auf beiden Geräten aktiviert
3. WLAN auf beiden Geräten aktiviert
4. Handoff aktiviert:
   - **Mac**: Systemeinstellungen > Allgemein > AirDrop & Handoff
   - **iPhone**: Einstellungen > Allgemein > AirPlay & Handoff

## 🛠 Installation

### Von Source:
```bash
git clone https://github.com/tobsiberlin/ShotCast.git
cd ShotCast
xcodebuild -scheme ShotCast build
```

### Direkt aus Xcode:
1. Projekt in Xcode öffnen
2. Cmd+R zum Bauen und Starten

## ⌨️ Keyboard Shortcuts

| Shortcut | Aktion |
|----------|--------|
| `Cmd+Ctrl+V` | ShotCast öffnen/schließen |
| `Cmd+Return` | Ausgewähltes Bild kopieren |
| `Space` | Vollbild-Vorschau |
| `Delete` | Bild löschen |
| `Cmd+F` | Als Favorit markieren |

## 🎯 Verwendung

1. **Automatischer Start**: ShotCast startet beim Mac-Login und läuft im Hintergrund
2. **iPhone-Copy**: Kopieren Sie ein Bild auf Ihrem iPhone
3. **Auto-Öffnung**: ShotCast öffnet sich automatisch auf Ihrem Mac
4. **Verwaltung**: Durchsuchen, kopieren oder speichern Sie Ihre Bilder

## 🔒 Datenschutz

- Alle Daten bleiben lokal auf Ihrem Mac
- Keine Cloud-Synchronisation (außer über Apple's Universal Clipboard)
- Bilder werden verschlüsselt im lokalen Speicher abgelegt

## 🤝 Mitwirken

Contributions sind willkommen! Bitte:
1. Fork das Repository
2. Erstelle einen Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Committe deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

## 📄 Lizenz

Copyright © 2025 Tobias Mattern. Alle Rechte vorbehalten.

---

# ShotCast - Automatic Universal Clipboard Manager

ShotCast is a native macOS Universal Clipboard manager that automatically activates when you copy images from your iPhone. Inspired by the elegant design of Paste app, ShotCast offers a modern and intuitive interface for managing your copied images.

## ✨ Key Features

### 🚀 Auto-Activation
- **Automatic Window Opening**: ShotCast opens automatically when you copy an image on your iPhone
- **No Keyboard Shortcut Required**: The window appears magically by itself
- **Smart Detection**: Recognizes Universal Clipboard content and distinguishes between local and iPhone copies

### 🎨 Paste-Inspired Design
- **Modern Grid Layout**: Flexible 2-6 column view
- **Smooth Animations**: Fluid transitions and hover effects
- **Dark Mode Support**: Perfect macOS integration
- **Preview Mode**: Full-screen preview with zoom and pan

### 🔧 Powerful Features
- **Background Monitoring**: Runs discreetly in the background
- **Smart Thumbnails**: Intelligent cropping for perfect previews
- **Multi-Format Support**: PNG, JPEG, HEIC, WebP and more
- **Drag & Drop**: Drag images directly into other apps
- **Favorites System**: Mark important images
- **Keyboard Shortcuts**: Quick navigation and actions

## 📋 Requirements

- macOS 14.0 (Sonoma) or later
- Apple ID with iCloud enabled
- Handoff enabled between Mac and iPhone

### Setting up Universal Clipboard:
1. Signed in with the same Apple ID on both devices
2. Bluetooth enabled on both devices
3. Wi-Fi enabled on both devices
4. Handoff enabled:
   - **Mac**: System Settings > General > AirDrop & Handoff
   - **iPhone**: Settings > General > AirPlay & Handoff

## 🛠 Installation

### From Source:
```bash
git clone https://github.com/tobsiberlin/ShotCast.git
cd ShotCast
xcodebuild -scheme ShotCast build
```

### Directly from Xcode:
1. Open project in Xcode
2. Cmd+R to build and run

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Ctrl+V` | Open/close ShotCast |
| `Cmd+Return` | Copy selected image |
| `Space` | Full-screen preview |
| `Delete` | Delete image |
| `Cmd+F` | Mark as favorite |

## 🎯 Usage

1. **Automatic Start**: ShotCast starts at Mac login and runs in background
2. **iPhone Copy**: Copy an image on your iPhone
3. **Auto-Opening**: ShotCast opens automatically on your Mac
4. **Management**: Browse, copy, or save your images

## 🔒 Privacy

- All data remains local on your Mac
- No cloud synchronization (except via Apple's Universal Clipboard)
- Images are stored encrypted locally

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Copyright © 2025 Tobias Mattern. All rights reserved.

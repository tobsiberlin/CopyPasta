import Foundation
import AppKit
import Carbon

class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    @Published var currentHotkeyString: String = "⌘⇧D"
    @Published var isRecording: Bool = false
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    // Standard: Command + Shift + D
    private var modifiers: UInt32 = UInt32(cmdKey | shiftKey)
    private var keyCode: UInt32 = 2 // D
    
    private init() {
        setupHotkey()
    }
    
    deinit {
        unregisterHotkey()
    }
    
    private func setupHotkey() {
        registerHotkey()
    }
    
    func startRecording() {
        isRecording = true
        unregisterHotkey()
        
        // Event Monitor für Tasten
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            self?.handleRecordingEvent(event)
        }
    }
    
    func stopRecording() {
        isRecording = false
        NSEvent.removeMonitor(self)
        registerHotkey()
    }
    
    private func handleRecordingEvent(_ event: NSEvent) {
        guard isRecording else { return }
        
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Mindestens eine Modifier-Taste muss gedrückt sein
        guard !flags.isEmpty else { return }
        
        // Ignoriere einzelne Modifier-Tasten
        guard event.type == .keyDown else { return }
        
        let newKeyCode = UInt32(event.keyCode)
        var newModifiers: UInt32 = 0
        
        if flags.contains(.command) {
            newModifiers |= UInt32(cmdKey)
        }
        if flags.contains(.shift) {
            newModifiers |= UInt32(shiftKey)
        }
        if flags.contains(.option) {
            newModifiers |= UInt32(optionKey)
        }
        if flags.contains(.control) {
            newModifiers |= UInt32(controlKey)
        }
        
        // Mindestens eine Modifier-Taste erforderlich
        guard newModifiers != 0 else { return }
        
        self.modifiers = newModifiers
        self.keyCode = newKeyCode
        
        updateHotkeyString()
        stopRecording()
        
        // Speichere in UserDefaults
        UserDefaults.standard.set(modifiers, forKey: "hotkeyModifiers")
        UserDefaults.standard.set(keyCode, forKey: "hotkeyKeyCode")
    }
    
    private func updateHotkeyString() {
        var string = ""
        
        if modifiers & UInt32(controlKey) != 0 {
            string += "⌃"
        }
        if modifiers & UInt32(optionKey) != 0 {
            string += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            string += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            string += "⌘"
        }
        
        // Key-Namen-Mapping
        let keyChar = keyCodeToString(keyCode)
        string += keyChar
        
        currentHotkeyString = string
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "⏎"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "⇥"
        case 49: return "␣"
        case 51: return "⌫"
        case 53: return "⎋"
        case 36: return "⏎"
        case 76: return "⌤"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "?"
        }
    }
    
    private func registerHotkey() {
        // Lade gespeicherte Werte
        let savedModifiers = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32
        let savedKeyCode = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? UInt32
        
        if let savedMod = savedModifiers, let savedKey = savedKeyCode {
            modifiers = savedMod
            keyCode = savedKey
        }
        
        updateHotkeyString()

        let signature: OSType = 0x53484F54  // 'SHOT' in hex
        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("✅ Hotkey registriert: \(currentHotkeyString)")
            
            // Event Handler für Hotkey
            let eventType = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))]
            
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (nextHandler, event, userData) -> OSStatus in
                    if let manager = userData?.assumingMemoryBound(to: HotkeyManager.self).pointee {
                        manager.hotkeyPressed()
                    }
                    return noErr
                },
                1,
                eventType,
                Unmanaged.passUnretained(self).toOpaque(),
                &eventHandler
            )
        } else {
            print("❌ Fehler beim Registrieren der Tastenkombination: \(status)")
        }
    }
    
    private func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func hotkeyPressed() {
        DispatchQueue.main.async {
            // Toggle ShotCast Window
            let windowManager = WindowManager.shared
            if windowManager.isVisible {
                windowManager.hideWindow()
            } else {
                windowManager.showWindow()
            }
        }
    }
    
    private func fourCharCode(_ string: String) -> UInt32 {
        let chars = Array(string.utf8)
        return UInt32(chars[0]) << 24 | UInt32(chars[1]) << 16 | UInt32(chars[2]) << 8 | UInt32(chars[3])
    }
}
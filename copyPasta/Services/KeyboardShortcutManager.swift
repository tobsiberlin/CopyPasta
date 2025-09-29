import Foundation
import SwiftUI
import Carbon
import Combine

// Verwaltet globale Keyboard Shortcuts für CopyPasta
// Manages global keyboard shortcuts for CopyPasta
class KeyboardShortcutManager: NSObject, ObservableObject {
    static let shared = KeyboardShortcutManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotKeys: [Int32: EventHotKey] = [:]
    private var currentHotKeyID: Int32 = 1
    
    // Standard Shortcuts
    private let defaultShortcuts = [
        "toggleWindow": (key: kVK_ANSI_V, modifiers: cmdKey | controlKey),     // Cmd+Ctrl+V
        "pasteSelected": (key: kVK_Return, modifiers: cmdKey),                 // Cmd+Return
        "deleteSelected": (key: kVK_Delete, modifiers: 0),                     // Delete
        "toggleFavorite": (key: kVK_ANSI_F, modifiers: cmdKey),               // Cmd+F
        "quickLook": (key: kVK_Space, modifiers: 0)                           // Space
    ]
    
    private override init() {
        super.init()
        setupHotKeys()
    }
    
    // Registriert globale Hotkeys
    // Registers global hotkeys
    private func setupHotKeys() {
        // Toggle Window Hotkey (Cmd+Ctrl+V)
        let toggleWindowID = registerHotKey(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: UInt32(cmdKey | controlKey),
            action: {
                WindowManager.shared.toggleWindow()
            }
        )
        
        print("Registered hotkey for toggle window: \(toggleWindowID)")
    }
    
    // Registriert einen einzelnen Hotkey
    // Registers a single hotkey
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) -> Int32 {
        let hotKeyID = EventHotKeyID(signature: OSType("CPST".utf8.reduce(0) { $0 << 8 + OSType($1) }),
                                     id: UInt32(currentHotKeyID))
        
        var eventHotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode,
                                       modifiers,
                                       hotKeyID,
                                       GetApplicationEventTarget(),
                                       0,
                                       &eventHotKey)
        
        if status == noErr, let hotKey = eventHotKey {
            hotKeys[currentHotKeyID] = EventHotKey(ref: hotKey, action: action)
            currentHotKeyID += 1
            return currentHotKeyID - 1
        }
        
        return -1
    }
    
    // Event Handler für Hotkeys
    // Event handler for hotkeys
    private func handleHotKeyEvent(id: Int32) {
        hotKeys[id]?.action()
    }
    
    deinit {
        // Cleanup
        for (_, hotKey) in hotKeys {
            UnregisterEventHotKey(hotKey.ref)
        }
    }
}

// HotKey Wrapper
private struct EventHotKey {
    let ref: EventHotKeyRef
    let action: () -> Void
}

// Simplified keyboard shortcut helper
// No conflict with Carbon EventModifiers

// Notification für Shortcuts
extension Notification.Name {
    static let keyboardShortcut = Notification.Name("keyboardShortcut")
}
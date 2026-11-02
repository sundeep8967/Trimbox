import Cocoa
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()
    
    private let signature = OSType(1414744397) // 'TRIM'
    private var hotKeyRefs: [EventHotKeyRef?] = []
    
    private init() {}
    
    func registerHotKeys() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                if status == noErr {
                    HotKeyManager.shared.handleHotKey(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        
        // 1. Cmd + Option + V -> Instant Paste Previous (item 1)
        register(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | optionKey), id: 1)
        
        // 2. Cmd + Option + Shift + V -> Instant Paste 2nd Previous (item 2)
        register(keyCode: UInt32(kVK_ANSI_V), modifiers: UInt32(cmdKey | optionKey | shiftKey), id: 2)
        
        // 3. Cmd + Option + C -> Cycle Clipboard History
        register(keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(cmdKey | optionKey), id: 3)
        
        // 4. Cmd + Option + Q -> Toggle FIFO Queue Mode
        register(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey | optionKey), id: 4)
        
        // 5. Cmd + H -> Show History Menu directly at cursor
        register(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey), id: 5)
        
        // 6. Cmd + Option + H -> Show History Menu (alternative)
        register(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey | optionKey), id: 6)
        
        // 7. Cmd + Shift + H -> Show History Menu (alternative)
        register(keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(cmdKey | shiftKey), id: 7)
    }
    
    private func register(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: id)
        let err = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        if err == noErr {
            hotKeyRefs.append(ref)
        } else {
            print("Failed to register hotkey #\(id), error: \(err)")
        }
    }
    
    private func handleHotKey(id: UInt32) {
        switch id {
        case 1:
            // Paste Previous (Index 1)
            ClipboardManager.shared.pasteItem(at: 1)
            
        case 2:
            // Paste 2nd Previous (Index 2)
            ClipboardManager.shared.pasteItem(at: 2)
            
        case 3:
            // Cycle Clipboard
            ClipboardManager.shared.cycleClipboard()
            
        case 4:
            // Toggle Queue Mode
            ClipboardManager.shared.isQueueMode.toggle()
            let state = ClipboardManager.shared.isQueueMode ? "Queue Mode: ON (FIFO)" : "Queue Mode: OFF"
            HUDOverlay.shared.show(label: "MODE", text: state)
            
        case 5, 6, 7:
            // Show History Popup Menu at mouse position
            StatusBarManager.shared.showHistoryMenu()
            
        default:
            break
        }
    }
}

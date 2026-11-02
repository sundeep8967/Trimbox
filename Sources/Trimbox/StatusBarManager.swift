import Cocoa

class StatusBarManager {
    static let shared = StatusBarManager()
    
    private init() {}
    
    func setup() {
        // Pure invisible background mode: no menu bar icon is created
    }
    
    // Pops up a history picker menu right at the mouse cursor
    func showHistoryMenu() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let historyMenu = NSMenu(title: "Clipboard History")
            
            let header = NSMenuItem(title: "📋 Clipboard History (Press 1–9 or Click to Paste)", action: nil, keyEquivalent: "")
            header.isEnabled = false
            historyMenu.addItem(header)
            historyMenu.addItem(NSMenuItem.separator())
            
            let history = ClipboardManager.shared.history
            if history.isEmpty {
                let empty = NSMenuItem(title: "No history yet", action: nil, keyEquivalent: "")
                empty.isEnabled = false
                historyMenu.addItem(empty)
            } else {
                let maxCount = min(history.count, 9)
                for i in 0..<maxCount {
                    let item = history[i]
                    let tag = i == 0 ? " [current]" : (i == 1 ? " [previous]" : "")
                    let clean = item.text
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespaces)
                    let preview = clean.count > 50 ? String(clean.prefix(50)) + "…" : clean
                    
                    let keyEq = "\(i + 1)"
                    let menuItem = NSMenuItem(title: "\(i + 1). \(preview)\(tag)", action: #selector(self.historyPopupSelected(_:)), keyEquivalent: keyEq)
                    menuItem.keyEquivalentModifierMask = []
                    menuItem.representedObject = item
                    menuItem.target = self
                    historyMenu.addItem(menuItem)
                }
                
                if history.count > 9 {
                    historyMenu.addItem(NSMenuItem.separator())
                    let moreCount = min(history.count, 20)
                    for i in 9..<moreCount {
                        let item = history[i]
                        let clean = item.text
                            .replacingOccurrences(of: "\n", with: " ")
                            .trimmingCharacters(in: .whitespaces)
                        let preview = clean.count > 50 ? String(clean.prefix(50)) + "…" : clean
                        let menuItem = NSMenuItem(title: "\(i + 1). \(preview)", action: #selector(self.historyPopupSelected(_:)), keyEquivalent: "")
                        menuItem.representedObject = item
                        menuItem.target = self
                        historyMenu.addItem(menuItem)
                    }
                }
            }
            
            historyMenu.addItem(NSMenuItem.separator())
            let clearItem = NSMenuItem(title: "Clear History", action: #selector(self.clearHistoryClicked), keyEquivalent: "")
            clearItem.target = self
            historyMenu.addItem(clearItem)
            
            NSApp.activate(ignoringOtherApps: true)
            historyMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
    }
    
    @objc private func historyPopupSelected(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? ClipboardItem {
            ClipboardManager.shared.pasteItem(item: item)
        }
    }
    
    @objc private func clearHistoryClicked() {
        ClipboardManager.shared.clearHistory()
    }
}

import Cocoa

struct ClipboardItem: Codable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date
    
    init(text: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
    }
}

class ClipboardManager {
    static let shared = ClipboardManager()
    
    private(set) var history: [ClipboardItem] = []
    private var lastChangeCount: Int = 0
    private var isSuppressingNextChange: Bool = false
    private var timer: Timer?
    
    var isPaused: Bool = false
    var isQueueMode: Bool = false
    var showHUD: Bool = false
    
    var onHistoryChanged: (() -> Void)?
    
    private let maxHistoryCount = 50
    private let storageURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dir = home.appendingPathComponent(".trimbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json")
    }()
    
    init() {
        loadHistory()
        lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func startMonitoring() {
        // Read whatever is currently on the clipboard
        if let currentText = NSPasteboard.general.string(forType: .string), !currentText.isEmpty {
            if history.first?.text != currentText {
                history.insert(ClipboardItem(text: currentText), at: 0)
                saveHistory()
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        guard !isPaused else { return }
        
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        if isSuppressingNextChange {
            isSuppressingNextChange = false
            return
        }
        
        guard let text = NSPasteboard.general.string(forType: .string), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Avoid duplicate top entry
        if let first = history.first, first.text == text {
            return
        }
        
        // Remove existing item if it was already in history (move to top)
        history.removeAll { $0.text == text }
        history.insert(ClipboardItem(text: text), at: 0)
        
        if history.count > maxHistoryCount {
            history.removeLast()
        }
        
        saveHistory()
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    // Paste a specific item directly (e.g. from history popup menu)
    func pasteItem(item: ClipboardItem) {
        isSuppressingNextChange = true
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Move to top of history
        history.removeAll { $0.id == item.id }
        history.insert(item, at: 0)
        saveHistory()
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
        
        if showHUD {
            HUDOverlay.shared.show(label: "PASTED", text: item.text)
        }
        
        simulatePasteKeystroke()
    }
    
    // Paste item at specific history index (0 = current, 1 = previous, 2 = 2nd previous)
    func pasteItem(at index: Int) {
        guard !history.isEmpty else { return }
        
        let targetIndex: Int
        if isQueueMode {
            // Queue mode: FIFO (oldest first)
            targetIndex = max(0, history.count - 1)
        } else {
            guard index < history.count else { return }
            targetIndex = index
        }
        
        let item = history[targetIndex]
        
        // Update pasteboard
        isSuppressingNextChange = true
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
        
        if isQueueMode {
            // Remove item from queue
            history.remove(at: targetIndex)
            saveHistory()
            DispatchQueue.main.async { [weak self] in
                self?.onHistoryChanged?()
            }
        }
        
        if showHUD {
            let label = targetIndex == 1 ? "Previous" : (targetIndex == 2 ? "2nd Previous" : "Queue #\(targetIndex + 1)")
            HUDOverlay.shared.show(label: label, text: item.text)
        }
        
        // Simulate paste keystroke (Cmd + V)
        simulatePasteKeystroke()
    }
    
    // Rotate clipboard: moves previous item to top so standard Cmd+V pastes it
    func cycleClipboard() {
        guard history.count > 1 else { return }
        let currentTop = history.removeFirst()
        history.append(currentTop)
        
        let newTop = history[0]
        isSuppressingNextChange = true
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(newTop.text, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
        
        saveHistory()
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
        
        if showHUD {
            HUDOverlay.shared.show(label: "Rotated To", text: newTop.text)
        }
    }
    
    func copyToClipboard(item: ClipboardItem) {
        isSuppressingNextChange = true
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Move item to top of history
        history.removeAll { $0.id == item.id }
        history.insert(item, at: 0)
        saveHistory()
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    func clearHistory() {
        history.removeAll()
        saveHistory()
        DispatchQueue.main.async { [weak self] in
            self?.onHistoryChanged?()
        }
    }
    
    private func simulatePasteKeystroke() {
        // Small delay to let physical modifier keys (Option/Shift) release
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            let source = CGEventSource(stateID: .combinedSessionState)
            
            // Release modifier keys
            let optUp = CGEvent(keyboardEventSource: source, virtualKey: 0x3A, keyDown: false)
            optUp?.flags = []
            optUp?.post(tap: .cghidEventTap)
            
            let shiftUp = CGEvent(keyboardEventSource: source, virtualKey: 0x38, keyDown: false)
            shiftUp?.flags = []
            shiftUp?.post(tap: .cghidEventTap)
            
            // Cmd + V key down
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            vDown?.flags = .maskCommand
            vDown?.post(tap: .cghidEventTap)
            
            // Cmd + V key up
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand
            vUp?.post(tap: .cghidEventTap)
        }
    }
    
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save clipboard history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            history = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard history: \(error)")
        }
    }
}

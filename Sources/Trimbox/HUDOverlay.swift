import Cocoa

class HUDOverlay {
    static let shared = HUDOverlay()
    
    private var window: NSPanel?
    private var badgeLabel: NSTextField?
    private var textLabel: NSTextField?
    private var fadeTimer: Timer?
    
    private init() {}
    
    func show(label: String, text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.display(label: label, text: text)
        }
    }
    
    private func display(label: String, text: String) {
        fadeTimer?.invalidate()
        
        let panelWidth: CGFloat = 360
        let panelHeight: CGFloat = 46
        
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .statusBar
            panel.backgroundColor = NSColor(white: 0.12, alpha: 0.92)
            panel.isOpaque = false
            panel.hasShadow = true
            panel.isMovable = false
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            if let contentView = panel.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = 12
                contentView.layer?.borderWidth = 1
                contentView.layer?.borderColor = NSColor(white: 1.0, alpha: 0.15).cgColor
                
                let badge = NSTextField(frame: NSRect(x: 12, y: 13, width: 90, height: 20))
                badge.isEditable = false
                badge.isSelectable = false
                badge.isBordered = false
                badge.backgroundColor = NSColor(white: 1.0, alpha: 0.15)
                badge.textColor = .white
                badge.alignment = .center
                badge.wantsLayer = true
                badge.layer?.cornerRadius = 6
                badge.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
                contentView.addSubview(badge)
                self.badgeLabel = badge
                
                let snippet = NSTextField(frame: NSRect(x: 108, y: 11, width: 240, height: 24))
                snippet.isEditable = false
                snippet.isSelectable = false
                snippet.isBordered = false
                snippet.backgroundColor = .clear
                snippet.textColor = .white
                snippet.font = NSFont.systemFont(ofSize: 13, weight: .medium)
                snippet.lineBreakMode = .byTruncatingTail
                contentView.addSubview(snippet)
                self.textLabel = snippet
            }
            
            self.window = panel
        }
        
        badgeLabel?.stringValue = label.uppercased()
        let cleanText = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        textLabel?.stringValue = cleanText
        
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (panelWidth / 2)
            let y = screenFrame.minY + 60
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window?.alphaValue = 1.0
        window?.orderFrontRegardless()
        
        // Auto-fade out after 1.2 seconds
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            guard let panel = self?.window else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                panel.animator().alphaValue = 0.0
            }, completionHandler: {
                panel.orderOut(nil)
            })
        }
    }
}

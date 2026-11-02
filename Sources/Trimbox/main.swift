import Cocoa

func printUsage() {
    print("""
    Trimbox - Native Clipboard History & Manager

    Usage:
      trimbox                     Launch GUI daemon / Menu Bar app
      trimbox daemon              Run as background service
      trimbox prev                Print previous copied text (1 step back)
      trimbox get <index>         Print copied text at index (0 = current, 1 = prev)
      trimbox restore <index>     Restore item at index to macOS clipboard
      trimbox list                List recent clipboard history
      trimbox clear               Clear clipboard history
    """)
}

func handleCLI() -> Bool {
    let args = CommandLine.arguments
    guard args.count > 1 else { return false }
    
    let command = args[1].lowercased()
    let manager = ClipboardManager.shared
    
    switch command {
    case "daemon":
        return false // continue to AppKit launch
        
    case "prev":
        if manager.history.count > 1 {
            print(manager.history[1].text, terminator: "")
        } else {
            fputs("Trimbox: No previous clipboard item found.\n", stderr)
            exit(1)
        }
        return true
        
    case "get":
        let idx = args.count > 2 ? (Int(args[2]) ?? 1) : 1
        if idx >= 0 && idx < manager.history.count {
            print(manager.history[idx].text, terminator: "")
        } else {
            fputs("Trimbox: Index \(idx) out of range (history count: \(manager.history.count)).\n", stderr)
            exit(1)
        }
        return true
        
    case "restore":
        let idx = args.count > 2 ? (Int(args[2]) ?? 1) : 1
        if idx >= 0 && idx < manager.history.count {
            let item = manager.history[idx]
            manager.copyToClipboard(item: item)
            print("Restored to clipboard: \(item.text.prefix(50))")
        } else {
            fputs("Trimbox: Index \(idx) out of range.\n", stderr)
            exit(1)
        }
        return true
        
    case "list":
        if manager.history.isEmpty {
            print("Clipboard history is empty.")
        } else {
            for (idx, item) in manager.history.enumerated() {
                let tag = idx == 0 ? "(current)" : (idx == 1 ? "(previous)" : "")
                let clean = item.text.replacingOccurrences(of: "\n", with: " ")
                let preview = clean.count > 60 ? String(clean.prefix(60)) + "..." : clean
                print(String(format: "%2d: [%@] %@", idx, tag.padding(toLength: 10, withPad: " ", startingAt: 0), preview))
            }
        }
        return true
        
    case "clear":
        manager.clearHistory()
        print("Trimbox: Clipboard history cleared.")
        return true
        
    case "-h", "--help", "help":
        printUsage()
        return true
        
    default:
        fputs("Unknown command: \(command)\n\n", stderr)
        printUsage()
        exit(1)
    }
}

// 1. Check if running as a CLI command
if handleCLI() {
    exit(0)
}

// 2. Otherwise run as native AppKit background daemon
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ClipboardManager.shared.startMonitoring()
        HotKeyManager.shared.registerHotKeys()
        StatusBarManager.shared.setup()
        print("Trimbox is active in the background. Press ⌥⌘V to paste previous item.")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()


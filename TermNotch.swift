import Cocoa
import SwiftUI

struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r: CGFloat = 14
        let ir: CGFloat = 12 // Rayon inversé
        
        // Top-Left corner
        path.move(to: CGPoint(x: 0, y: 0))
        // inversed corner top-left
        path.addArc(center: CGPoint(x: 0, y: ir), radius: ir, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // vertical line - left 
        path.addLine(to: CGPoint(x: ir, y: h - r))
        // inversed Bottom-Left corner 
        path.addArc(center: CGPoint(x: ir + r, y: h - r), radius: r, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        // Bottom horizontal line
        path.addLine(to: CGPoint(x: w - ir - r, y: h))
        // Reversed Bottom-Right corner
        path.addArc(center: CGPoint(x: w - ir - r, y: h - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        // Right vertical line
        path.addLine(to: CGPoint(x: w - ir, y: ir))
        // Reversed corner top-right
        path.addArc(center: CGPoint(x: w, y: ir), radius: ir, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        return path
    }
}

struct PillView: View {
    let message: String
    @State private var pillWidth: CGFloat = 210 // width macbook notch 
    @State private var pillHeight: CGFloat = 32 // height macbook notch 
    @State private var contentOpacity: Double = 0.0

    var body: some View {
        VStack {
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 15)
                .opacity(contentOpacity)
        }

        .frame(width: pillWidth, height: pillHeight) 
        .background(
            NotchShape()
                .fill(Color.black)
        )

        .frame(width: 274, height: 60, alignment: .top)
        .onAppear {
            // expansion animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pillWidth = 274
                pillHeight = 60
            }
            withAnimation(.easeIn(duration: 0.2).delay(0.1)) {
                contentOpacity = 1.0
            }
            
            // retraction animation 
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    contentOpacity = 0.0
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                    pillWidth = 195
                    pillHeight = 32
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var settingsWindow: NSWindow?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let args = CommandLine.arguments
        let showMenuBar = UserDefaults.standard.bool(forKey: "showMenuBarIcon")
        
        // Settings
        if args.contains("-s") || args.contains("--settings") {
            if showMenuBar { setupMenuBar() }
            openSettings()
            return 
        }
        
        // install process
        if args.count <= 1 {
            installCLIIfNeeded()
            
            // menu bar
            if showMenuBar {
                setupMenuBar()
                return
            }
        }
        
        // Main screen only
        guard let primaryScreen = NSScreen.screens.first else { exit(0) }
        let screenRect = primaryScreen.frame
        
        let width: CGFloat = 274 
        let height: CGFloat = 60
        
        // Position
        let x = screenRect.minX + (screenRect.width - width) / 2
        let targetY = screenRect.maxY - height
        
        // Empty window
        window = NSWindow(contentRect: NSRect(x: x, y: targetY, width: width, height: height),
                          styleMask: [.borderless],
                          backing: .buffered,
                          defer: false)
        
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false 
        window.ignoresMouseEvents = true 
        
        let message = args.count > 1 ? args[1] : "Task completed!"
        
        let hostingView = NSHostingView(rootView: PillView(message: message))
        window.contentView = hostingView
        window.orderFront(nil)
    }
    
    // opening via MenuBar
    @objc func openSettingsMenu() {
        openSettings()
    }
    
    // opening settings window
    func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 280),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "TermNotch Settings"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            
            // closing app
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: nil) { _ in
                if !UserDefaults.standard.bool(forKey: "showMenuBarIcon") {
                    NSApplication.shared.terminate(nil)
                }
            }
            
            self.settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // Status Item
    func setupMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = statusItem?.button {
                if let image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "TermNotch") {
                    button.image = image
                } else {
                    button.title = "TN"
                }
            }
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsMenu), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit TermNotch", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.menu = menu
        }
    }
    
    func removeMenuBar() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // auto install in /usr/local/bin
    func installCLIIfNeeded() {
        let destPath = "/usr/local/bin/termnotch"
        let fm = FileManager.default
        
        let exePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
        
        if fm.fileExists(atPath: destPath) {
            do {
                let currentTarget = try fm.destinationOfSymbolicLink(atPath: destPath)
                if currentTarget == exePath { return } // Already installed and up to date
            } catch {
            }
        }
        
        // native alert
        let alert = NSAlert()
        alert.messageText = "Install TermNotch CLI?"
        alert.informativeText = "To use TermNotch directly from your terminal, the application must create a shortcut in /usr/local/bin.\n\nYour password will be requested."
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Later")
        
        NSApp.activate(ignoringOtherApps: true)
        
        if alert.runModal() == .alertFirstButtonReturn {
            // AppleScript used to execute a bash command with administrator privileges
            let script = "do shell script \"mkdir -p /usr/local/bin && ln -sf '\(exePath)' '\(destPath)'\" with administrator privileges"
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
            
            if error == nil {
                let successAlert = NSAlert()
                successAlert.messageText = "Install successful!"
                successAlert.informativeText = "You can now open your terminal and type: termnotch \"Your message\""
                successAlert.runModal()
            }
        }
    }
}
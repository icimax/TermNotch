import Cocoa
import SwiftUI

struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let r: CGFloat = 14
        let ir: CGFloat = 12 // Rayon inversé
        
        // Haut-gauche
        path.move(to: CGPoint(x: 0, y: 0))
        // Courbe inversée haut-gauche
        path.addArc(center: CGPoint(x: 0, y: ir), radius: ir, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        
        // Ligne verticale gauche
        path.addLine(to: CGPoint(x: ir, y: h - r))
        
        // Courbe bas-gauche
        path.addArc(center: CGPoint(x: ir + r, y: h - r), radius: r, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        
        // Ligne horizontale bas
        path.addLine(to: CGPoint(x: w - ir - r, y: h))
        
        // Courbe bas-droite
        path.addArc(center: CGPoint(x: w - ir - r, y: h - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        
        // Ligne verticale droite
        path.addLine(to: CGPoint(x: w - ir, y: ir))
        
        // Courbe inversée haut-droite
        path.addArc(center: CGPoint(x: w, y: ir), radius: ir, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        path.addLine(to: CGPoint(x: 0, y: 0))
        return path
    }
}

struct PillView: View {
    let message: String
    @State private var pillWidth: CGFloat = 210 // Largeur exacte de la notch des MacBook
    @State private var pillHeight: CGFloat = 32 // Hauteur exacte de la notch des MacBook
    @State private var contentOpacity: Double = 0.0

    var body: some View {
        VStack {
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 15)
                .opacity(contentOpacity)
        }
        // Le bloc s'anime en largeur et en hauteur
        .frame(width: pillWidth, height: pillHeight) 
        .background(
            NotchShape()
                .fill(Color.black)
        )
        // La vue globale (de la taille de la fenêtre) qui garde tout aligné collé en haut
        .frame(width: 274, height: 60, alignment: .top)
        .onAppear {
            // Animation d'agrandissement (façon Dynamic Island)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pillWidth = 274
                pillHeight = 60
            }
            withAnimation(.easeIn(duration: 0.2).delay(0.1)) {
                contentOpacity = 1.0
            }
            
            // Rétractation après 3 secondes  
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    contentOpacity = 0.0
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                    pillWidth = 195
                    pillHeight = 32
                }
                
                // Quitter l'app après l'animation (laisser plus de temps pour ne pas couper la fin)
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
        
        // 0. VÉRIFIER L'OUVERTURE DES PARAMÈTRES
        if args.contains("-s") || args.contains("--settings") {
            if showMenuBar { setupMenuBar() }
            openSettings()
            return // On arrête ici, on n'affiche pas la notification
        }
        
        // Si lancé sans argument (ex: double-clic depuis le Finder), on lance le processus d'installation
        if args.count <= 1 {
            installCLIIfNeeded()
            
            // Si on a activé l'option de rester dans la barre de menu
            if showMenuBar {
                setupMenuBar()
                return // On s'arrête là : on ne lance pas la notification textuelle qui se ferme toute seule
            }
            // Sinon on affiche quand même la notification par défaut pour montrer que ça marche
        }
        
        // 1. FORCER L'ÉCRAN PRINCIPAL
        guard let primaryScreen = NSScreen.screens.first else { exit(0) }
        let screenRect = primaryScreen.frame
        
        let width: CGFloat = 274 // 250 + 24 (2 * 12 pour les rayons inversés)
        let height: CGFloat = 60
        
        // 2. CALCULER LA POSITION EXACTE
        let x = screenRect.minX + (screenRect.width - width) / 2
        let targetY = screenRect.maxY - height
        
        // La fenêtre est FIXE
        window = NSWindow(contentRect: NSRect(x: x, y: targetY, width: width, height: height),
                          styleMask: [.borderless],
                          backing: .buffered,
                          defer: false)
        
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false 
        window.ignoresMouseEvents = true 
        
        let message = args.count > 1 ? args[1] : "Tâche terminée !"
        
        // 3. INTÉGRER LA VUE SWIFTUI
        // NSHostingView masque le contenu qui déborde grâce à la Vue et la Fenêtre
        let hostingView = NSHostingView(rootView: PillView(message: message))
        window.contentView = hostingView
        window.orderFront(nil)
    }
    
    // Fonction d'ouverture de la fenêtre des paramètres via MenuBar
    @objc func openSettingsMenu() {
        openSettings()
    }
    
    // Fonction d'ouverture de la fenêtre des paramètres
    func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 280),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Paramètres TermNotch"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            
            // Fermer l'application quand la fenêtre des paramètres se ferme (uniquement si le mode menubar est désactivé)
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
    
    // Gestion du menu en haut de l'écran (Status Item)
    func setupMenuBar() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = statusItem?.button {
                // Utilise une icône de terminal par défaut de SF Symbols (si disponible sur l'OS)
                if let image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "TermNotch") {
                    button.image = image
                } else {
                    button.title = "TN"
                }
            }
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Paramètres...", action: #selector(openSettingsMenu), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quitter TermNotch", action: #selector(quitApp), keyEquivalent: "q"))
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
    
    // Fonction d'installation automatique dans /usr/local/bin
    func installCLIIfNeeded() {
        let destPath = "/usr/local/bin/termnotch"
        let fm = FileManager.default
        
        // On récupère le chemin de l'exécutable (à l'intérieur de l'App)
        let exePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
        
        // Si le lien existe déjà et pointe vers le bon endroit, on ne fait rien
        if fm.fileExists(atPath: destPath) {
            do {
                let currentTarget = try fm.destinationOfSymbolicLink(atPath: destPath)
                if currentTarget == exePath { return } // Déjà installé et à jour
            } catch {
                // Pas un symlink ou erreur, on continue pour l'écraser
            }
        }
        
        // Création d'une alerte native MacOS
        let alert = NSAlert()
        alert.messageText = "Installer la commande TermNotch ?"
        alert.informativeText = "Pour utiliser TermNotch directement depuis votre terminal, l'application doit créer un raccourci dans /usr/local/bin.\n\nVotre mot de passe vous sera demandé."
        alert.addButton(withTitle: "Installer")
        alert.addButton(withTitle: "Plus tard")
        
        NSApp.activate(ignoringOtherApps: true)
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Utilisation d'AppleScript pour exécuter une commande bash avec privilèges administrateur
            let script = "do shell script \"mkdir -p /usr/local/bin && ln -sf '\(exePath)' '\(destPath)'\" with administrator privileges"
            
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
            
            if error == nil {
                let successAlert = NSAlert()
                successAlert.messageText = "Installation réussie !"
                successAlert.informativeText = "Vous pouvez maintenant ouvrir votre terminal et taper : termnotch \"Votre message\""
                successAlert.runModal()
            }
        }
    }
}
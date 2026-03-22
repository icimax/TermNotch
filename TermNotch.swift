import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // 1. FORCER L'ÉCRAN PRINCIPAL (Celui avec l'encoche, toujours le premier de la liste)
        guard let primaryScreen = NSScreen.screens.first else { exit(0) }
        let screenRect = primaryScreen.frame
        
        let width: CGFloat = 250
        let height: CGFloat = 60
        
        // 2. CALCULER LA POSITION EXACTE
        let x = screenRect.minX + (screenRect.width - width) / 2
        let targetY = screenRect.maxY - height // Position finale (collée en haut de l'écran principal)
        
        // La fenêtre est maintenant FIXE. Elle ne bougera plus.
        window = NSWindow(contentRect: NSRect(x: x, y: targetY, width: width, height: height),
                          styleMask: [.borderless],
                          backing: .buffered,
                          defer: false)
        
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false 
        window.ignoresMouseEvents = true 
        
        // 3. VUE CONTENEUR (Invisible, sert de "masque" pour cacher la pilule quand elle remonte)
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        containerView.wantsLayer = true
        containerView.layer?.masksToBounds = true // MAGIE : Coupe tout ce qui sort de la zone !
        
        // 4. LA PILULE NOIRE (Commence cachée en haut, hors du conteneur)
        // On la place à y = height, donc elle est "au-dessus" du plafond de la fenêtre
        let pillView = NSView(frame: NSRect(x: 0, y: height, width: width, height: height))
        pillView.wantsLayer = true
        pillView.layer?.backgroundColor = NSColor.black.cgColor
        pillView.layer?.cornerRadius = 14.0
        pillView.layer?.cornerCurve = .continuous
        pillView.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        pillView.layer?.borderWidth = 0
        
        let args = CommandLine.arguments
        let message = args.count > 1 ? args[1] : "Tâche terminée !"
        
        let label = NSTextField(labelWithString: message)
        label.textColor = .white
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.alignment = .center
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.translatesAutoresizingMaskIntoConstraints = false

        pillView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: pillView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: pillView.centerYAnchor, constant: 10)
        ])
        
        containerView.addSubview(pillView)
        window.contentView = containerView
        window.orderFront(nil)
        
        // 5. ANIMATION DE LA PILULE (À l'intérieur de la fenêtre fixe)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            // On garde l'effet de rebond sympa !
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.175, 0.885, 0.32, 1.275)
            
            // La pilule descend à Y=0 (elle devient visible dans la fenêtre)
            pillView.animator().frame = NSRect(x: 0, y: 0, width: width, height: height)
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    
                    // La pilule remonte à Y=height (elle sort de la fenêtre et devient invisible)
                    pillView.animator().frame = NSRect(x: 0, y: height, width: width, height: height)
                }) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
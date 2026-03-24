import SwiftUI

struct SettingsView: View {
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gear")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Paramètres TermNotch")
                .font(.title)
                .fontWeight(.bold)
            
            Toggle("Afficher dans la barre des menus", isOn: $showMenuBarIcon)
                .toggleStyle(.switch)
                .onChange(of: showMenuBarIcon) { _, newValue in
                    if newValue {
                        (NSApp.delegate as? AppDelegate)?.setupMenuBar()
                    } else {
                        (NSApp.delegate as? AppDelegate)?.removeMenuBar()
                    }
                }
            
            Text("Si activé, l'application restera ouverte en arrière-plan\net le menu restera accessible à tout moment.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Fermer") {
                NSApp.keyWindow?.close() // Ferme uniquement la fenêtre
            }
            .padding(.top, 10)
        }
        .padding(40)
        .frame(width: 450, height: 280)
    }
}

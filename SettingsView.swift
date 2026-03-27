import SwiftUI

struct SettingsView: View {
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gear")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            
            Toggle("show in the menu bar", isOn: $showMenuBarIcon)
                .toggleStyle(.switch)
                .onChange(of: showMenuBarIcon) { newValue in
                if newValue {
                    (NSApp.delegate as? AppDelegate)?.setupMenuBar()
                } else {
                        (NSApp.delegate as? AppDelegate)?.removeMenuBar()
                    }
                }
            
            Text("If enabled, the application will remain open in the background\nand the menu will be accessible at all times.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Close") {
                NSApp.keyWindow?.close()
            }
            .padding(.top, 10)
        }
        .padding(40)
        .frame(width: 450, height: 280)
    }
}

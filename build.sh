#!/bin/bash

echo "🔨 Compilation de TermNotch..."

# 1. Compilation des fichiers Swift
swiftc *.swift -o TermNotch

# Vérifier si la compilation a réussi
if [ $? -ne 0 ]; then
    echo "❌ Erreur de compilation."
    exit 1
fi

# 2. Création de la structure de l'application
mkdir -p TermNotch.app/Contents/MacOS
mkdir -p TermNotch.app/Contents/Resources

# 3. Déplacement de l'exécutable
mv TermNotch TermNotch.app/Contents/MacOS/

# 4. Création du fichier Info.plist
cat > TermNotch.app/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TermNotch</string>
    <key>CFBundleIdentifier</key>
    <string>com.tonnom.TermNotch</string>
    <key>CFBundleName</key>
    <string>TermNotch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# 5. Installation dans le dossier Applications
rm -rf ~/Applications/TermNotch.app
mv TermNotch.app ~/Applications/

# 6. Création du lien symbolique dans le dossier utilisateur local pour accès direct
echo "🔗 Création du lien symbolique pour la commande 'termnotch'..."
# On utilise ~/bin s'il existe ou ~/.local/bin qui ne nécessitent pas de sudo,
# ou on crée le dossier s'il n'existe pas et on l'ajoute provisoirement aux indications
mkdir -p ~/.local/bin
ln -sf ~/Applications/TermNotch.app/Contents/MacOS/TermNotch ~/.local/bin/termnotch

# On demande aussi l'autorisation sudo pour l'installer globalement si désiré,
# mais ce n'est pas bloquant si l'utilisateur annule.
echo "⚠️ Pour que la commande soit disponible partout immédiatement,"
echo "nous essayons de l'ajouter à /usr/local/bin (peut nécessiter votre mot de passe) :"
sudo ln -sf ~/Applications/TermNotch.app/Contents/MacOS/TermNotch /usr/local/bin/termnotch || true

echo "✅ TermNotch mis à jour avec succès !"

# 7. Lancement d'un test automatique
echo "🚀 Lancement du test..."
open -a ~/Applications/TermNotch.app --args "Test d'affichage !"
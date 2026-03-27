#!/bin/bash

echo "🔨 Compilation..."

# 1. Compilation
swiftc *.swift -o TermNotch

# check compilation
if [ $? -ne 0 ]; then
    echo "❌ error during compilation."
    exit 1
fi

# 2. Création of the structure 
mkdir -p TermNotch.app/Contents/MacOS
mkdir -p TermNotch.app/Contents/Resources

# 3. moving the executable
mv TermNotch TermNotch.app/Contents/MacOS/

# 4. info.plist creation
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

# 5. Installation 
rm -rf ~/Applications/TermNotch.app
mv TermNotch.app ~/Applications/

# 6. creating the link for the command
echo "🔗 Creating symbolic link for the 'termnotch' command..."

mkdir -p ~/.local/bin
ln -sf ~/Applications/TermNotch.app/Contents/MacOS/TermNotch ~/.local/bin/termnotch

echo "⚠️ For the command to be available everywhere immediately,"
echo "we are trying to add it to /usr/local/bin (may require your password) :"
sudo ln -sf ~/Applications/TermNotch.app/Contents/MacOS/TermNotch /usr/local/bin/termnotch || true

echo "✅ TermNotch was updated successfully!"

# 7. Starting test
echo "🚀 Starting test..."
open -a ~/Applications/TermNotch.app --args "Display test!"
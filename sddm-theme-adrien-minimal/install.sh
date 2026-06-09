#!/usr/bin/env bash
set -e

THEME_SRC="$(cd "$(dirname "$0")" && pwd)"
THEME_DEST="/usr/share/sddm/themes/adrien-minimal"
WALLPAPER="/home/adrien/.config/hypr/wallpapers/ToriPixel.png"
SDDM_CONF="/etc/sddm.conf.d/theme.conf"

echo "→ Fix du binaire sddm-greeter (Qt5 absent, Qt6 présent)..."
if [ ! -L /usr/bin/sddm-greeter ]; then
    sudo mv /usr/bin/sddm-greeter /usr/bin/sddm-greeter.qt5.bak
    sudo ln -s /usr/bin/sddm-greeter-qt6 /usr/bin/sddm-greeter
    echo "  ✓ /usr/bin/sddm-greeter → sddm-greeter-qt6"
else
    echo "  (symlink déjà en place)"
fi

echo "→ Installation du thème SDDM adrien-minimal..."
sudo mkdir -p "$THEME_DEST"
sudo cp "$THEME_SRC/metadata.desktop" "$THEME_DEST/"
sudo cp "$THEME_SRC/theme.conf" "$THEME_DEST/"
sudo cp "$THEME_SRC/Main.qml" "$THEME_DEST/"

echo "→ Conversion et copie du wallpaper (WebP → JPEG)..."
ffmpeg -i "$WALLPAPER" -update 1 -q:v 2 /tmp/sddm_background.jpg -y 2>/dev/null
sudo cp /tmp/sddm_background.jpg "$THEME_DEST/background.jpg"
sudo rm -f "$THEME_DEST/background.png"

echo "→ Configuration de SDDM..."
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=adrien-minimal\n' | sudo tee "$SDDM_CONF" > /dev/null

echo "✓ Installation terminée."
echo ""
echo "Prévisualisation :"
echo "  sddm-greeter --test-mode --theme $THEME_DEST"
echo ""
echo "Pour activer :"
echo "  sudo systemctl restart sddm"

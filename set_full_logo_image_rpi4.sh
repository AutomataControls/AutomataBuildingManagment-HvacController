#!/bin/bash

# Explicitly set the path to the splash image in the Automata home directory
IMAGE_PATH="/home/Automata/splash.png"

# Ensure the image file exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: $IMAGE_PATH not found. Please place splash.png in /home/Automata."
    exit 1
fi

# Install necessary package if missing
if ! command -v pcmanfm &> /dev/null; then
    echo "pcmanfm not found, installing..."
    sudo apt-get install -y pcmanfm
fi

# Set splash.png as desktop wallpaper (for Raspberry Pi OS with LXDE)
sudo -u Automata DISPLAY=:0 pcmanfm --set-wallpaper="$IMAGE_PATH"

# Set splash.png as the splash screen
SPLASH_SCREEN_PATH="/usr/share/plymouth/themes/pix/splash.png"
sudo cp "$IMAGE_PATH" "$SPLASH_SCREEN_PATH"

echo "splash.png has been set as the desktop wallpaper and splash screen on your Raspberry Pi."

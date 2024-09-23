#!/bin/bash

# Path to FullLogo.png (update if necessary)
IMAGE_PATH="$HOME/FullLogo.png"

# Ensure the image file exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: $IMAGE_PATH not found. Please place FullLogo.png in your home directory."
    exit 1
fi

# Install necessary package if missing
if ! command -v pcmanfm &> /dev/null; then
    echo "pcmanfm not found, installing..."
    sudo apt-get install -y pcmanfm
fi

# Set FullLogo.png as desktop wallpaper (for Raspberry Pi OS with LXDE)
pcmanfm --set-wallpaper="$IMAGE_PATH"

# Set FullLogo.png as the splash screen
SPLASH_SCREEN_PATH="/usr/share/plymouth/themes/pix/splash.png"
sudo cp "$IMAGE_PATH" "$SPLASH_SCREEN_PATH"

echo "FullLogo.png has been set as the desktop wallpaper and splash screen on your Raspberry Pi 4."


#!/bin/bash

# Explicitly set the path to the splash image in the Automata home directory
IMAGE_PATH="/home/Automata/splash.png"

# Ensure the image file exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: $IMAGE_PATH not found. Please place splash.png in /home/Automata."
    exit 1
fi

# Try finding the correct wallpaper config path
WALLPAPER_CONFIG=$(find /home/Automata/.config -name "desktop-items-0.conf" | head -n 1)

if [ -f "$WALLPAPER_CONFIG" ]; then
    echo "Setting wallpaper..."
    # Modify wallpaper settings in the LXDE config file
    sed -i "s|wallpaper=.*|wallpaper=$IMAGE_PATH|g" "$WALLPAPER_CONFIG"
    sed -i "s|wallpaper_mode=.*|wallpaper_mode=fit|g" "$WALLPAPER_CONFIG"
    # Restart pcmanfm to apply changes
    pcmanfm --reconfigure
else
    echo "Warning: desktop-items-0.conf not found. Could not set wallpaper."
fi

# Set splash.png as the splash screen
SPLASH_SCREEN_PATH="/usr/share/plymouth/themes/pix/splash.png"
sudo cp "$IMAGE_PATH" "$SPLASH_SCREEN_PATH"

echo "splash.png has been set as the desktop wallpaper and splash screen on your Raspberry Pi."

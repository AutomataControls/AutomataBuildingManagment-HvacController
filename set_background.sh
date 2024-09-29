#!/bin/bash

# Path to the image
IMAGE_PATH="/home/Automata/splash.png"

# Function to create configuration directories if they don't exist
create_config_directories() {
    CONFIG_DIR="$HOME/.config/pcmanfm/LXDE-pi"
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        echo "Created configuration directory: $CONFIG_DIR"
    fi
}

# Function to set the wallpaper
set_wallpaper() {
    # Set the wallpaper using pcmanfm command and check for errors
    DISPLAY=:0 pcmanfm --set-wallpaper="$IMAGE_PATH" --wallpaper-mode=crop &>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set wallpaper using pcmanfm."
        return 1
    fi

    # Update the desktop configuration file
    CONFIG_FILE="$HOME/.config/pcmanfm/LXDE-pi/desktop-items-0.conf"
    echo "[*]" > "$CONFIG_FILE"
    echo "wallpaper=$IMAGE_PATH" >> "$CONFIG_FILE"
    echo "wallpaper_mode=stretch" >> "$CONFIG_FILE"

    if grep -q "wallpaper=$IMAGE_PATH" "$CONFIG_FILE"; then
        echo "Wallpaper path correctly set in configuration file."
    else
        echo "Failed to update wallpaper path in configuration file."
    fi
}

# Ensure configuration directories are present
create_config_directories

# Wait for the desktop environment to fully load (adjust the sleep time if needed)
sleep 10

# Run the function to set the wallpaper and log the result
set_wallpaper
if [ $? -eq 0 ]; then
    echo "Wallpaper successfully set to $IMAGE_PATH at $(date)" >> "$HOME/wallpaper_set.log"
else
    echo "Failed to set wallpaper. Check logs for details." >> "$HOME/wallpaper_set.log"
fi

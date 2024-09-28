#!/bin/bash

# Path to the image
IMAGE_PATH="/home/Automata/AutomataControls-AutomataBuildingManagment-HvacController/splash.png"

# Function to set the wallpaper
set_wallpaper() {
    # Set the wallpaper
    DISPLAY=:0 pcmanfm --set-wallpaper="$IMAGE_PATH" --wallpaper-mode=crop

    # Update the desktop configuration file
    CONFIG_FILE="$HOME/.config/pcmanfm/LXDE-pi/desktop-items-0.conf"
    sed -i "s|wallpaper=.*|wallpaper=$IMAGE_PATH|g" "$CONFIG_FILE"
    sed -i "s|wallpaper_mode=.*|wallpaper_mode=crop|g" "$CONFIG_FILE"
}

# Wait for the desktop environment to fully load (adjust the sleep time if needed)
sleep 10

# Run the function to set the wallpaper
set_wallpaper

# Optional: Add a log entry
echo "Wallpaper set to $IMAGE_PATH at $(date)" >> "$HOME/wallpaper_set.log"

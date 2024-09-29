#!/bin/bash

# Path to the image
IMAGE_PATH="/home/Automata/AutomataControls-AutomataBuildingManagment-HvacController/splash.png"

# Function to set the wallpaper
set_wallpaper() {
    # Ensure that pcmanfm is active by checking for desktop manager status
    if pgrep -x "pcmanfm" > /dev/null; then
        # Set the wallpaper using pcmanfm
        DISPLAY=:0 pcmanfm --set-wallpaper="$IMAGE_PATH" --wallpaper-mode=crop

        # Update the desktop configuration file
        CONFIG_FILE="$HOME/.config/pcmanfm/LXDE-pi/desktop-items-0.conf"
        sed -i "s|wallpaper=.*|wallpaper=$IMAGE_PATH|g" "$CONFIG_FILE"
        sed -i "s|wallpaper_mode=.*|wallpaper_mode=crop|g" "$CONFIG_FILE"

        echo "Wallpaper set to $IMAGE_PATH successfully." | tee -a "$HOME/wallpaper_set.log"
    else
        echo "Error: Desktop manager is not active or pcmanfm is not running." | tee -a "$HOME/wallpaper_set.log"
        exit 1
    fi
}

# Wait for the desktop environment to fully load (adjust the sleep time if needed)
sleep 10

# Run the function to set the wallpaper
set_wallpaper

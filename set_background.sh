#!/bin/bash

# Path to the image
IMAGE_PATH="/home/Automata/AutomataControls-AutomataBuildingManagment-HvacController/splash.png"

# Function to set the wallpaper
set_wallpaper() {
    # Ensure the DISPLAY variable is set
    export DISPLAY=:0

    # Check if pcmanfm is running
    if pgrep -x "pcmanfm" > /dev/null; then
        echo "pcmanfm is running. Setting wallpaper using pcmanfm."

        # Set the wallpaper using pcmanfm for both LXDE and LXDE-pi profiles
        DISPLAY=:0 pcmanfm --set-wallpaper="$IMAGE_PATH" --wallpaper-mode=crop

        # Update the desktop configuration files
        for CONFIG_DIR in "$HOME/.config/pcmanfm/LXDE" "$HOME/.config/pcmanfm/LXDE-pi"; do
            CONFIG_FILE="$CONFIG_DIR/desktop-items-0.conf"
            if [ -f "$CONFIG_FILE" ]; then
                sed -i "s|wallpaper=.*|wallpaper=$IMAGE_PATH|g" "$CONFIG_FILE"
                sed -i "s|wallpaper_mode=.*|wallpaper_mode=crop|g" "$CONFIG_FILE"
                echo "Updated wallpaper configuration in $CONFIG_FILE"
            else
                echo "Configuration file $CONFIG_FILE not found, skipping..."
            fi
        done

    else
        echo "pcmanfm is not running. Trying to start pcmanfm as desktop manager."
        # Try to start pcmanfm as the desktop manager
        DISPLAY=:0 pcmanfm --desktop &
        sleep 5

        # Set the wallpaper again after starting pcmanfm
        DISPLAY=:0 pcmanfm --set-wallpaper="$IMAGE_PATH" --wallpaper-mode=crop
    fi

    # Log the result
    echo "Wallpaper set to $IMAGE_PATH at $(date)" | tee -a "$HOME/wallpaper_set.log"
}

# Wait for the desktop environment to fully load (adjust the sleep time if needed)
sleep 10

# Run the function to set the wallpaper
set_wallpaper

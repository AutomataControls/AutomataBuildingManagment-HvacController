#!/bin/bash

# Path to the image
IMAGE_PATH="/home/Automata/AutomataControls-AutomataBuildingManagment-HvacController/splash.png"

# Create configuration directories if they don't exist
create_config_directories() {
    # Define the directories to be created
    CONFIG_DIRS=("$HOME/.config/pcmanfm/LXDE" "$HOME/.config/pcmanfm/LXDE-pi")

    for CONFIG_DIR in "${CONFIG_DIRS[@]}"; do
        if [ ! -d "$CONFIG_DIR" ]; then
            mkdir -p "$CONFIG_DIR"
            echo "Created directory: $CONFIG_DIR."
        fi
    done
}

# Function to set the wallpaper
set_wallpaper() {
    # Ensure the DISPLAY variable is set for graphical operations
    export DISPLAY=:0

    # Check if pcmanfm is running as the desktop manager
    if ! pgrep -x "pcmanfm" > /dev/null; then
        echo "pcmanfm is not running. Starting pcmanfm as the desktop manager..."
        DISPLAY=:0 pcmanfm --desktop &
        sleep 5  # Give pcmanfm time to start
    else
        echo "pcmanfm is already running."
    fi

    # Set the wallpaper using pcmanfm for both LXDE and LXDE-pi profiles
    DISPLAY=:0 pcmanfm --set-wallpaper="$IMAGE_PATH" --wallpaper-mode=crop
    echo "Wallpaper set using pcmanfm."

    # Update the desktop configuration files
    for CONFIG_DIR in "$HOME/.config/pcmanfm/LXDE" "$HOME/.config/pcmanfm/LXDE-pi"; do
        CONFIG_FILE="$CONFIG_DIR/desktop-items-0.conf"
        
        # Create a default configuration file if it doesn't exist
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "[*]" > "$CONFIG_FILE"
            echo "wallpaper=$IMAGE_PATH" >> "$CONFIG_FILE"
            echo "wallpaper_mode=crop" >> "$CONFIG_FILE"
            echo "Created default configuration file $CONFIG_FILE."
        else
            # Update existing configuration file
            sed -i "s|wallpaper=.*|wallpaper=$IMAGE_PATH|g" "$CONFIG_FILE"
            sed -i "s|wallpaper_mode=.*|wallpaper_mode=crop|g" "$CONFIG_FILE"
            echo "Updated wallpaper configuration in $CONFIG_FILE."
        fi
    done

    # Log the result
    echo "Wallpaper set to $IMAGE_PATH at $(date)" | tee -a "$HOME/wallpaper_set.log"
}

# Function to restart pcmanfm if not active
restart_pcmanfm() {
    echo "Restarting pcmanfm to ensure it's active and managing the desktop..."
    pkill -x "pcmanfm"
    sleep 2  # Wait for pcmanfm to fully terminate
    DISPLAY=:0 pcmanfm --desktop &
    sleep 5  # Give pcmanfm time to start
}

# Wait for the desktop environment to fully load (adjust the sleep time if needed)
sleep 10

# Create configuration directories before setting the wallpaper
create_config_directories

# Restart pcmanfm and set the wallpaper
restart_pcmanfm
set_wallpaper

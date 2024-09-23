#!/bin/bash

# Step 0: Stop Node-RED system service and Node-RED runtime if running

# Check if Node-RED service is running and stop it
if systemctl is-active --quiet nodered; then
    echo "Stopping Node-RED service..."
    sudo systemctl stop nodered
fi

# Run node-red-stop to ensure Node-RED stops completely
if command -v node-red-stop &> /dev/null; then
    echo "Stopping Node-RED runtime..."
    node-red-stop
else
    echo "node-red-stop command not found, skipping..."
fi

# Define paths for each Sequent board update folder
BOARDS=(
    "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update"
)

# Update all boards
echo "Starting Sequent Microsystems board updates..."

for BOARD_PATH in "${BOARDS[@]}"; do
    if [ -d "$BOARD_PATH" ]; then
        echo "Updating board in: $BOARD_PATH"
        cd "$BOARD_PATH" && sudo ./update 0
        if [ $? -eq 0 ]; then
            echo "Successfully updated board in: $BOARD_PATH"
        else
            echo "Failed to update board in: $BOARD_PATH"
        fi
    else
        echo "Error: Update folder not found at $BOARD_PATH"
    fi
done

# Prompt for reboot using a Zenity dialog box (removed custom color schemes to avoid issues)
DIALOG_TITLE="Sequent Microsystems Update"
DIALOG_TEXT="All Sequent Microsystems boards have been updated successfully. Do you want to reboot now?"

# Display the dialog box
zenity --question --title="$DIALOG_TITLE" --text="$DIALOG_TEXT" --width=400 --height=300 --ok-label="Reboot Now" --cancel-label="Later"

# Check user's choice
if [ $? -eq 0 ]; then
    echo "Rebooting the system..."
    sudo reboot
else
    echo "Reboot canceled."
fi

#!/bin/bash

# Function to run a script and handle errors
run_script() {
    sudo bash "$1" || { echo "Error: $1 failed, continuing..."; }
}

# Step 1: Set system clock to local internet time
run_script "set_internet_time_rpi4.sh"

# Step 2: Set FullLogo.png as desktop and splash screen
run_script "set_full_logo_image_rpi4.sh"

# Step 3: Install Mosquitto and configure user authentication
run_script "setup_mosquitto.sh"

# Step 4: Increase the swap size to 2048 MB
run_script "increase_swap_size.sh"

# Step 5: Install/update Node-RED and enable the service
run_script "install_node_red.sh"

# Step 6: Run SequentMSInstall.sh to install Sequent Microsystems drivers
run_script "SequentMSInstall.sh"

# Step 7: Create a desktop icon to launch Chromium to Node-RED and UI
DESKTOP_FILE="/home/Automata/Desktop/NodeRed.desktop"
echo "[Desktop Entry]" > "$DESKTOP_FILE"
echo "Version=1.0" >> "$DESKTOP_FILE"
echo "Name=Node-RED Dashboard" >> "$DESKTOP_FILE"
echo "Comment=Open Node-RED in Chromium" >> "$DESKTOP_FILE"
echo "Exec=chromium-browser --new-window http://127.0.0.1:1880/ http://127.0.0.1:1880/ui" >> "$DESKTOP_FILE"
echo "Icon=chromium" >> "$DESKTOP_FILE"
echo "Terminal=false" >> "$DESKTOP_FILE"
echo "Type=Application" >> "$DESKTOP_FILE"
echo "Categories=Utility;Application;" >> "$DESKTOP_FILE"

# Make the desktop file executable
chmod +x "$DESKTOP_FILE"
echo "Desktop icon created at $DESKTOP_FILE."

# Step 8: Reboot the system to apply all changes
echo "Rebooting the system now..."
sudo reboot

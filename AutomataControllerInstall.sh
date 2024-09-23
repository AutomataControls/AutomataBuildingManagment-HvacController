#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

# Step 0: Cleanup previous installation attempts and stop services
echo "Stopping and disabling conflicting services..."
sudo systemctl stop ntp || echo "NTP service was not running"
sudo systemctl disable ntp || echo "NTP service was not enabled"
sudo systemctl stop mosquitto || echo "Mosquitto service was not running"
sudo systemctl disable mosquitto || echo "Mosquitto service was not enabled"
sudo rm -f /etc/mosquitto/passwd || echo "No previous Mosquitto password file to remove"

# Remove the installation step file if it exists
INSTALLATION_STEP_FILE="/home/Automata/installation_step.txt"
if [ -f "$INSTALLATION_STEP_FILE" ]; then
    sudo rm "$INSTALLATION_STEP_FILE"
    echo "Previous installation step file removed."
fi

# Remove any existing logs if they exist
if [ -f "$LOGFILE" ]; then
    sudo rm "$LOGFILE"
    echo "Previous installation log file removed."
fi

# Function to save the installation step
save_step() {
    echo "$1" > "$INSTALLATION_STEP_FILE"
}

# Function to run a script and handle errors
run_script() {
    sudo bash "$1" || { echo "Error: $1 failed, continuing..."; }
}

# Step 1: Set executable permissions for all files in the cloned repository
echo "Setting executable permissions for all scripts in the repository..."
sudo chmod -R +x /home/Automata/AutomataBuildingManagment-HvacController/*.sh
echo "Permissions set for all .sh files."

# Step 2: Set system clock to local internet time and correct timezone (disabled NTP for now)
echo "Skipping NTP setup due to conflicts, manually set the timezone..."
sudo timedatectl set-timezone America/New_York  # Set timezone to EST
echo "System timezone set to Eastern Standard Time (EST)."

# Step 3: Set FullLogo.png as desktop wallpaper and splash screen as the 'Automata' user
LOGO_PATH="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"
if [ -f "$LOGO_PATH" ]; then
    echo "Setting logo as wallpaper and splash screen..."
    sudo -u Automata feh --bg-scale "$LOGO_PATH" || echo "Warning: Could not set wallpaper."
    sudo cp "$LOGO_PATH" /usr/share/plymouth/themes/pix/splash.png
    echo "Logo set successfully."
else
    echo "Error: $LOGO_PATH not found. Please place FullLogo.png in the correct directory."
fi

# Step 4: Install Mosquitto but do not start the service until after reboot
echo "Installing Mosquitto..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y mosquitto mosquitto-clients
sudo touch /etc/mosquitto/passwd
echo "Setting up Mosquitto password for user Automata..."
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2
echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf
echo "Mosquitto installed but service will not be started until after reboot."

# Step 5: Increase the swap size to 2048 MB
echo "Increasing swap size..."
run_script "increase_swap_size.sh"

# Step 6: Install Node-RED non-interactively and prevent prompts
echo "Running install_node_red.sh to install Node-RED non-interactively..."
sudo -u Automata bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh --confirm-install --node20

# Step 7: Run SequentMSInstall.sh to install Sequent Microsystems drivers
if [ -f "/home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh" ]; then
    echo "Running SequentMSInstall.sh to install Sequent Microsystems drivers..."
    run_script "/home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh"
else
    echo "Error: SequentMSInstall.sh not found."
fi

# Step 8: Create a desktop icon to launch Chromium to Node-RED and UI
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

chmod +x "$DESKTOP_FILE"
echo "Desktop icon created at $DESKTOP_FILE."

# Final message
echo "Installation completed. Please reboot the system to finalize the process."

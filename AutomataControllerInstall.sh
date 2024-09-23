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

# Step 4: Change the desktop background to FullLogo.png
echo "Changing the desktop background to FullLogo.png..."
if [ -f "$LOGO_PATH" ]; then
    sudo pcmanfm --set-wallpaper="$LOGO_PATH"
    echo "Desktop background set to FullLogo.png."
else
    echo "Error: $LOGO_PATH not found for setting desktop background."
fi

# Step 5: Enable I2C, SPI, RealVNC, 1-Wire, Remote GPIO, and disable serial port
echo "Enabling I2C, SPI, RealVNC, 1-Wire, Remote GPIO, and disabling serial port..."

# Enable I2C
sudo raspi-config nonint do_i2c 0
echo "I2C enabled."

# Enable SPI
sudo raspi-config nonint do_spi 0
echo "SPI enabled."

# Enable VNC
sudo raspi-config nonint do_vnc 0
echo "RealVNC enabled."

# Enable 1-Wire
sudo raspi-config nonint do_onewire 0
echo "1-Wire enabled."

# Enable Remote GPIO
sudo raspi-config nonint do_rgpio 0
echo "Remote GPIO enabled."

# Disable Serial Port
sudo raspi-config nonint do_serial 1
echo "Serial port disabled."

# Step 6: Install Mosquitto but do not start the service until after reboot
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

# Step 7: Increase the swap size to 2048 MB
echo "Increasing swap size..."
run_script "increase_swap_size.sh"

# Step 8: Install Node-RED non-interactively and prevent prompts
echo "Running install_node_red.sh to install Node-RED non-interactively..."
sudo -u Automata bash << 'EOF'
#!/bin/bash

# Install or update Node.js and Node-RED non-interactively
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-install --confirm-pi --node20

# Enable Node-RED service to start on boot
sudo systemctl enable nodered.service

# Start Node-RED service immediately
sudo systemctl start nodered.service || echo "Warning: Node-RED service failed to start. Check logs."

echo "Node-RED has been installed or updated, and the service is now enabled to start on boot."
EOF

# Step 9: Run SequentMSInstall.sh to install Sequent Microsystems drivers
if [ -f "/home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh" ]; then
    echo "Running SequentMSInstall.sh to install Sequent Microsystems drivers..."
    run_script "/home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh"
else
    echo "Error: SequentMSInstall.sh not found."
fi

# Step 10: Add post-reboot process for killing services and updating Sequent boards
echo "Adding post-reboot process to stop services and update Sequent boards..."
sudo tee /etc/rc.local > /dev/null << 'EOF'
#!/bin/bash
# Post-reboot script to stop services, update boards, and reboot again

# Stop Node-RED and Mosquitto services
sudo systemctl stop nodered
sudo systemctl stop mosquitto
node-red-stop

# Update Sequent Microsystems boards
cd /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update
sudo ./update 0
cd /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update
sudo ./update 0
cd /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update
sudo ./update 0
cd /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update
sudo ./update 0
cd /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update
sudo ./update 0

# Reboot again with services enabled
sudo systemctl enable nodered
sudo systemctl enable mosquitto
sudo reboot
EOF
sudo chmod +x /etc/rc.local

# Final message
echo "Installation completed. The system will reboot in 10 seconds to finalize the process."
sleep 10
sudo reboot

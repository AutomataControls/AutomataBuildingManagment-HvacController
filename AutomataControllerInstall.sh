#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

# Step 1: Set executable permissions for all files in the cloned repository
echo "Setting executable permissions for all scripts in the repository..."
sudo chmod -R +x /home/Automata/AutomataBuildingManagment-HvacController/*.sh
echo "Permissions set for all .sh files."

# Function to run a script and handle errors
run_script() {
    sudo bash "$1" || { echo "Error: $1 failed, continuing..."; }
}

# Step 2: Set system clock to local internet time and correct timezone
echo "Setting system clock and adjusting for Eastern Standard Time (EST)..."
sudo timedatectl set-timezone America/New_York  # Eastern Standard Time
run_script "set_internet_time_rpi4.sh"

# Step 3: Set FullLogo.png as desktop wallpaper and splash screen as the 'Automata' user
LOGO_PATH="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"

if [ -f "$LOGO_PATH" ]; then
    echo "Setting logo as wallpaper and splash screen..."

    # Set the wallpaper and splash screen as the logged-in user (Automata)
    sudo -u Automata pcmanfm --set-wallpaper "$LOGO_PATH" || echo "Warning: Could not set wallpaper. Desktop manager may not be active."
    
    # Set the logo as the splash screen
    sudo cp "$LOGO_PATH" /usr/share/plymouth/themes/pix/splash.png
    echo "Logo set successfully."
else
    echo "Error: $LOGO_PATH not found. Please place FullLogo.png in the correct directory."
fi

# Step 4: Install Mosquitto and configure user authentication
echo "Installing Mosquitto and setting up user authentication..."

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# Install Mosquitto and clients without prompting for confirmation
sudo apt-get install -y mosquitto mosquitto-clients

# Add Mosquitto user and password in non-interactive mode
echo "Setting up Mosquitto password for user Automata..."
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2

# Create Mosquitto configuration
echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf

# Enable and restart Mosquitto service
sudo systemctl enable mosquitto
sudo systemctl restart mosquitto

# Step 5: Increase the swap size to 2048 MB
run_script "increase_swap_size.sh"

# Step 6: Install/update Node-RED and enable the service
echo "Installing Node-RED..."
sudo apt-get install -y nodered  # Automatic 'y' for confirmation
sudo systemctl enable nodered
sudo systemctl start nodered

# Step 7: Run SequentMSInstall.sh to install Sequent Microsystems drivers
if [ -f "SequentMSInstall.sh" ]; then
    run_script "SequentMSInstall.sh"
else
    echo "SequentMSInstall.sh not found, skipping..."
fi

# Step 8: Enable I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH; disable serial port
echo "Enabling I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH; disabling serial port..."

# Enable I2C
sudo raspi-config nonint do_i2c 0
echo "I2C enabled."

# Enable SPI
sudo raspi-config nonint do_spi 0
echo "SPI enabled."

# Enable VNC
sudo raspi-config nonint do_vnc 0
echo "VNC enabled."

# Enable 1-Wire
sudo raspi-config nonint do_onewire 0
echo "1-Wire enabled."

# Enable Remote GPIO
sudo raspi-config nonint do_rgpio 0
echo "Remote GPIO enabled."

# Enable SSH
sudo raspi-config nonint do_ssh 0
echo "SSH enabled."

# Disable Serial Port
sudo raspi-config nonint do_serial 1
echo "Serial port disabled."

# Step 9: Create a desktop icon to launch Chromium to Node-RED and UI
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

# Step 10: Reboot the system to apply all changes
echo "Rebooting the system now..."
sudo reboot

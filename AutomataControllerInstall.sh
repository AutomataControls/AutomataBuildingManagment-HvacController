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

# Step 2: Install Zenity for dialog boxes
echo "Installing Zenity..."
sudo apt-get install -y zenity

# Step 3: Set system clock to local internet time and correct timezone
echo "Setting system clock and adjusting for Eastern Standard Time (EST)..."
sudo timedatectl set-timezone America/New_York  # Eastern Standard Time
run_script "set_internet_time_rpi4.sh"

# Step 4: Set FullLogo.png as desktop wallpaper and splash screen as the 'Automata' user
LOGO_PATH="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"

if [ -f "$LOGO_PATH" ]; then
    echo "Setting logo as wallpaper and splash screen..."

    # Set the wallpaper using 'feh'
    sudo -u Automata feh --bg-scale "$LOGO_PATH" || echo "Warning: Could not set wallpaper."

    # Set the logo as the splash screen
    sudo cp "$LOGO_PATH" /usr/share/plymouth/themes/pix/splash.png
    echo "Logo set successfully."
else
    echo "Error: $LOGO_PATH not found. Please place FullLogo.png in the correct directory."
fi

# Step 5: Install Mosquitto and configure user authentication
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
sudo systemctl restart mosquitto || echo "Warning: Mosquitto service failed to start. Check logs."

# Step 6: Increase the swap size to 2048 MB
run_script "increase_swap_size.sh"

# Step 7: Install/update Node-RED and enable the service
echo "Installing Node-RED..."
sudo apt-get install -y nodered  # Automatic 'y' for confirmation
sudo systemctl enable nodered
sudo systemctl start nodered || echo "Warning: Node-RED service failed to start. Check logs."

# Step 8: Run SequentMSInstall.sh to install Sequent Microsystems drivers
if [ -f "/home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh" ]; then
    echo "Running SequentMSInstall.sh..."

    # Install repositories in the AutomataBuildingManagment-HvacController directory
    git clone https://github.com/SequentMicrosystems/megabas-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/megaind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/16univin-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/16relind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/8relind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi && sudo make install
else
    echo "SequentMSInstall.sh not found, skipping..."
fi

# Step 9: Enable I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH; disable serial port
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

# Step 10: Create a desktop icon to launch Chromium to Node-RED and UI
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

# Step 11: Show success dialog box
zenity --info --width=400 --height=300 --text="You have successfully Installed Automata Control System Components: A Realm of Automation Awaits!" --title="Installation Complete" --window-icon="$LOGO_PATH" --ok-label="Reboot Now" --cancel-label="Later"

# Ask the user if they want to reboot now
if [ $? = 0 ]; then
    echo "Rebooting the system now..."
    sudo reboot
else
    echo "Reboot canceled."
fi

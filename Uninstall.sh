#!/bin/bash

# Function to run a command and handle errors
run_command() {
    sudo bash -c "$1" || { echo "Error: $1 failed, continuing..."; }
}

echo "Starting uninstallation process..."

# Step 1: Disable and remove Mosquitto service and user credentials
echo "Disabling and removing Mosquitto..."
sudo systemctl stop mosquitto
sudo systemctl disable mosquitto
sudo apt-get remove --purge -y mosquitto mosquitto-clients
sudo rm -f /etc/mosquitto/passwd
sudo rm -f /etc/mosquitto/mosquitto.conf

# Step 2: Restore the default swap size (typically 100 MB)
echo "Restoring default swap size..."
sudo dphys-swapfile swapoff
sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=100/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Step 3: Remove Node-RED and related services
echo "Removing Node-RED..."
sudo systemctl stop nodered
sudo systemctl disable nodered
sudo apt-get remove --purge -y nodered

# Step 4: Remove Sequent Microsystems drivers (Skip errors)
echo "Removing Sequent Microsystems drivers..."
if [ -f "SequentMSUninstall.sh" ]; then
    run_command "./SequentMSUninstall.sh"
else
    echo "SequentMSUninstall.sh not found, skipping..."
fi

# Step 5: Disable I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH; re-enable serial port
echo "Disabling I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH, and enabling serial port..."

# Disable I2C
sudo raspi-config nonint do_i2c 1
echo "I2C disabled."

# Disable SPI
sudo raspi-config nonint do_spi 1
echo "SPI disabled."

# Disable VNC
sudo raspi-config nonint do_vnc 1
echo "VNC disabled."

# Disable 1-Wire
sudo raspi-config nonint do_onewire 1
echo "1-Wire disabled."

# Disable Remote GPIO
sudo raspi-config nonint do_rgpio 1
echo "Remote GPIO disabled."

# Disable SSH
sudo raspi-config nonint do_ssh 1
echo "SSH disabled."

# Enable Serial Port
sudo raspi-config nonint do_serial 0
echo "Serial port enabled."

# Step 6: Remove desktop icon for Node-RED
DESKTOP_FILE="/home/Automata/Desktop/NodeRed.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    echo "Removing Node-RED desktop icon..."
    rm "$DESKTOP_FILE"
else
    echo "Node-RED desktop icon not found, skipping..."
fi

# Step 7: Remove the cloned repository directory
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
if [ -d "$REPO_DIR" ]; then
    echo "Removing cloned repository directory..."
    sudo rm -rf "$REPO_DIR"
else
    echo "Repository directory not found, skipping..."
fi

# Step 8: Remove the install step file from /home/Automata
INSTALL_STEP_FILE="/home/Automata/install_step_file"  # Update with actual step file name
if [ -f "$INSTALL_STEP_FILE" ]; then
    echo "Removing install step file..."
    rm "$INSTALL_STEP_FILE"
else
    echo "Install step file not found, skipping..."
fi

# Step 9: Reboot the system to finalize uninstallation
echo "Rebooting the system now..."
sudo reboot


#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/uninstall_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Uninstallation started at: $(date)"

# Function to run a command and handle errors
run_command() {
    sudo bash -c "$1" || { echo "Error: $1 failed, continuing..."; }
}

# Step 1: Stop and remove Mosquitto service and user credentials
echo "Stopping and removing Mosquitto..."
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
if systemctl list-units --full -all | grep -q "nodered.service"; then
    sudo systemctl stop nodered
    sudo systemctl disable nodered
else
    echo "Node-RED service not found, skipping stop and disable."
fi
sudo apt-get remove --purge -y nodered

# Step 4: Remove Sequent Microsystems drivers (Skip errors)
echo "Removing Sequent Microsystems drivers..."
if [ -d "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi" ]; then
    cd /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
    sudo make uninstall || echo "Error: Uninstall failed for megabas-rpi"
fi

if [ -d "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi" ]; then
    cd /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
    sudo make uninstall || echo "Error: Uninstall failed for megaind-rpi"
fi

if [ -d "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi" ]; then
    cd /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi
    sudo make uninstall || echo "Error: Uninstall failed for 16univin-rpi"
fi

if [ -d "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi" ]; then
    cd /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi
    sudo make uninstall || echo "Error: Uninstall failed for 16relind-rpi"
fi

if [ -d "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi" ]; then
    cd /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi
    sudo make uninstall || echo "Error: Uninstall failed for 8relind-rpi"
fi

# Step 5: Disable I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH; re-enable the serial port
echo "Disabling I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH, and enabling the serial port..."
sudo raspi-config nonint do_i2c 1
sudo raspi-config nonint do_spi 1
sudo raspi-config nonint do_vnc 1
sudo raspi-config nonint do_onewire 1
sudo raspi-config nonint do_rgpio 1
sudo raspi-config nonint do_ssh 1
sudo raspi-config nonint do_serial 0

# Step 6: Remove the desktop icon for Node-RED
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

# Step 8: Start the Tkinter GUI for uninstallation
echo "Starting uninstallation GUI..."
python3 /home/Automata/AutomataBuildingManagment-HvacController/uninstall_progress_gui.py

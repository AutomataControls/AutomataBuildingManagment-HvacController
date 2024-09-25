#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/uninstall_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Uninstallation started at: $(date)"

# Step 1: Stop Node-RED and other related services
echo "Stopping Node-RED and related services..."

# Stop Node-RED service if running
if systemctl list-units --full -all | grep -q 'nodered.service'; then
    sudo systemctl stop nodered.service
    sudo systemctl disable nodered.service
    echo "Node-RED service stopped and disabled."
fi

# Run node-red-stop if available to ensure Node-RED is fully stopped
if command -v node-red-stop &> /dev/null; then
    node-red-stop
    echo "Node-RED runtime fully stopped."
fi

# Stop Mosquitto service if running
if systemctl list-units --full -all | grep -q 'mosquitto.service'; then
    sudo systemctl stop mosquitto
    sudo systemctl disable mosquitto
    echo "Mosquitto service stopped and disabled."
fi

# Step 2: Restore the default swap size (typically 100 MB)
echo "Restoring default swap size..."
sudo dphys-swapfile swapoff
sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=100/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
echo "Swap size restored."

# Step 3: Remove Node-RED and related components
echo "Removing Node-RED..."
sudo apt-get remove --purge -y nodered
sudo rm -rf /home/Automata/.node-red
echo "Node-RED removed."

# Step 4: Remove Mosquitto and its configuration files
echo "Removing Mosquitto..."
sudo apt-get remove --purge -y mosquitto mosquitto-clients
sudo rm -f /etc/mosquitto/passwd
sudo rm -f /etc/mosquitto/mosquitto.conf
echo "Mosquitto removed."

# Step 5: Remove Sequent Microsystems drivers
echo "Removing Sequent Microsystems drivers..."

DRIVER_PATHS=(
    "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi"
)

for driver in "${DRIVER_PATHS[@]}"; do
    if [ -d "$driver" ]; then
        cd "$driver" || { echo "Directory $driver not found, skipping..."; continue; }
        sudo make uninstall
        echo "Driver in $driver uninstalled."
    else
        echo "Driver path $driver not found, skipping..."
    fi
done

# Step 6: Disable I2C, SPI, VNC, 1-Wire, and SSH; re-enable the serial port
echo "Disabling I2C, SPI, VNC, 1-Wire, and SSH; enabling serial port..."

sudo raspi-config nonint do_i2c 1
sudo raspi-config nonint do_spi 1
sudo raspi-config nonint do_vnc 1
sudo raspi-config nonint do_onewire 1
sudo raspi-config nonint do_ssh 1
sudo raspi-config nonint do_serial 0

echo "I2C, SPI, VNC, 1-Wire, and SSH disabled, serial port enabled."

# Step 7: Remove desktop entries and auto-start files
echo "Removing desktop and auto-start entries..."

AUTOSTART_FILE="/home/Automata/.config/lxsession/LXDE-pi/autostart"
if [ -f "$AUTOSTART_FILE" ]; then
    sudo sed -i '/update_sequent_boards.sh/d' "$AUTOSTART_FILE"
    sudo sed -i '/launch_chromium_permanent.sh/d' "$AUTOSTART_FILE"
    echo "Auto-start entries removed."
else
    echo "Auto-start file not found, skipping..."
fi

DESKTOP_FILE="/home/Automata/Desktop/NodeRed.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    rm "$DESKTOP_FILE"
    echo "Node-RED desktop entry removed."
else
    echo "Node-RED desktop entry not found, skipping..."
fi

# Step 8: Remove repository and other installed files
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
if [ -d "$REPO_DIR" ]; then
    sudo rm -rf "$REPO_DIR"
    echo "Repository directory removed."
else
    echo "Repository directory not found, skipping..."
fi

# Step 9: Display uninstallation success dialog and reboot prompt
echo "Displaying uninstallation success dialog..."

whiptail --title "Uninstallation Complete" --msgbox "Uninstallation of Automata BMS is complete." 8 50

# Step 10: Ask the user if they want to reboot now
if whiptail --title "Reboot Confirmation" --yesno "Would you like to reboot the system now?" 8 50; then
    echo "Rebooting the system now..."
    sudo reboot
else
    echo "Reboot canceled."
fi



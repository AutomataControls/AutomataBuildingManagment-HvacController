#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Function to handle errors
handle_error() {
    log "Error occurred in line $1"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Step 1: Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Re-running with sudo..."
    sudo bash "$0" "$@"
    exit
fi

# Step 2: Log file setup
LOGFILE="/home/Automata/uninstall_log.txt"
log "Uninstallation started"

# Step 3: Run the uninstall progress GUI script from the repo
log "Running uninstall progress GUI..."
sudo -u Automata DISPLAY=:0 python3 /home/Automata/AutomataBuildingManagment-HvacController/uninstall_progress_gui.py &

# Step 4: Uninstallation steps while the GUI runs
log "Starting uninstallation process..."

# Stop Mosquitto
log "Stopping and removing Mosquitto services..."
sudo systemctl stop mosquitto
sudo systemctl disable mosquitto
sudo apt-get remove --purge -y mosquitto mosquitto-clients
sudo rm -f /etc/mosquitto/passwd
sudo rm -f /etc/mosquitto/mosquitto.conf

# Restore default swap size
log "Restoring default swap size..."
sudo dphys-swapfile swapoff
sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=100/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Remove Node-RED
log "Stopping and removing Node-RED services..."
sudo systemctl stop nodered
sudo systemctl disable nodered
sudo apt-get remove --purge -y nodered

# Remove Sequent Microsystems drivers
log "Removing Sequent Microsystems drivers..."
drivers=(
    "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi"
    "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi"
)
for driver in "${drivers[@]}"; do
    if [ -d "$driver" ]; then
        log "Removing driver at $driver..."
        cd "$driver" && sudo make uninstall
    else
        log "Driver $driver not found, skipping..."
    fi
done

# Disable interfaces: I2C, SPI, VNC, etc.
log "Disabling I2C, SPI, VNC, 1-Wire, Serial..."
sudo raspi-config nonint do_i2c 1
sudo raspi-config nonint do_spi 1
sudo raspi-config nonint do_vnc 1
sudo raspi-config nonint do_onewire 1
sudo raspi-config nonint do_serial 0

# Remove repository directory
log "Removing repository directory..."
sudo rm -rf /home/Automata/AutomataBuildingManagment-HvacController

# Step 5: Permissions cleanup and file removal
log "Removing permissions for repository files..."
find /home/Automata -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod -x {} \;
find /home/Automata -type f -name "*.png" -exec chmod -r {} \;

log "Uninstallation completed."


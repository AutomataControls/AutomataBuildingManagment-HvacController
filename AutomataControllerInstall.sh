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
LOGFILE="/home/Automata/install_log.txt"
log "Installation started"

# Step 3: Install only dependencies needed for GUI creation
log "Installing minimal dependencies for GUI creation..."
apt-get update
apt-get install -y python3-tk python3-pil python3-pil.imagetk gnome-terminal

# Step 4: Create the installation progress GUI and run it
log "Running installation GUI..."
sudo -u Automata DISPLAY=:0 python3 /home/Automata/AutomataBuildingManagment-HvacController/install_progress_gui.py &

# Step 5: Install Sequent MS Drivers, Node-RED, and other required steps (same as before)
# Modify accordingly to reflect individual Sequent MS boards installation and Node-RED setup as discussed before.

# ...

# Step 6: Set up Chromium Auto-launch
log "Setting up Chromium auto-launch..."
AUTO_LAUNCH_SCRIPT="/home/Automata/launch_chromium.py"

cat << 'EOF' > $AUTO_LAUNCH_SCRIPT
import time
import subprocess

# Wait for the network to connect
while True:
    try:
        subprocess.check_call(['ping', '-c', '1', '127.0.0.1'])
        break
    except subprocess.CalledProcessError:
        time.sleep(1)

# Wait additional time for services to load
time.sleep(15)

# Launch Chromium in windowed mode
subprocess.Popen(['chromium-browser', '--disable-features=KioskMode', '--new-window', 'http://127.0.0.1:1880/', 'http://127.0.0.1:1880/ui'])
EOF

# Create systemd service for Chromium auto-launch
cat << 'EOF' > /etc/systemd/system/chromium-launch.service
[Unit]
Description=Auto-launch Chromium at boot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/Automata/launch_chromium.py
User=Automata
Environment=DISPLAY=:0
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable chromium-launch.service

# Step 7: Set up systemd service to trigger update_progress_gui.py on reboot
log "Setting up board update service for the next reboot..."

cat << 'EOF' > /etc/systemd/system/update-boards.service
[Unit]
Description=Run Update Progress GUI on Reboot
After=multi-user.target

[Service]
ExecStart=/usr/bin/python3 /home/Automata/AutomataBuildingManagment-HvacController/update_progress_gui.py
User=Automata
Environment=DISPLAY=:0
Restart=no

[Install]
WantedBy=multi-user.target
EOF

# Enable the board update service to run once on the next reboot
systemctl enable update-boards.service

# Step 8: Permissions for the repo files after reboot
log "Setting permissions for files in repository after reboot..."
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
if [ -d "$REPO_DIR" ]; then
    log "Setting permissions for files in repository directory..."
    find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
    find "$REPO_DIR" -type f -name "*.png" -exec chmod +r {} \;
    find "/home/Automata" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
    find "/home/Automata" -type f -name "*.png" -exec chmod +r {} \;
fi

log "Installation completed. You may reboot to update boards."

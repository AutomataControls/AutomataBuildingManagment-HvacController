#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to handle errors
handle_error() {
    log "Error occurred in line $1"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Function to run shell commands and log their execution
run_shell_command() {
    local command="$1"
    eval "$command"
}

# Step 1: Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Re-running with sudo..."
    sudo bash "$0" "$@"
    exit
fi

# Step 2: Check if we're in the correct directory
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
if [ "$(pwd)" != "$REPO_DIR" ]; then
    echo "Please run this script from $REPO_DIR"
    exit 1
fi

# Step 3: Log file setup
LOGFILE="$REPO_DIR/install_log.txt"
log "Installation started"

# Step 4: Install minimal dependencies for GUI creation
log "Installing minimal dependencies for GUI creation..."
apt-get update
apt-get install -y python3-tk python3-pil python3-pil.imagetk gnome-terminal dos2unix

# Step 5: Set permissions for repository files
log "Setting permissions for files in repository..."
chown -R Automata:Automata "$REPO_DIR"
find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>> "$LOGFILE"
find "$REPO_DIR" -type f -name "*.png" -exec chmod +r {} \; 2>> "$LOGFILE"

# Step 6: Convert line endings to Unix format
log "Converting line endings for all .sh and .py files to Unix format..."
find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec dos2unix {} \;
find /home/Automata -type f \( -name "*.sh" -o -name "*.py" \) -exec dos2unix {} \;
log "Line endings converted successfully!"

# Step 7: Copy the installation progress GUI script and set permissions
log "Copying installation progress GUI script and setting permissions..."
cp "$REPO_DIR/install_progress_gui.py" /home/Automata/install_progress_gui.py
chmod +x /home/Automata/install_progress_gui.py
chown Automata:Automata /home/Automata/install_progress_gui.py

# Step 8: Kill lingering services before continuing
log "Killing lingering services (Node-RED, Mosquitto)..."
services=('nodered' 'mosquitto')
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log "Stopping $service service..."
        systemctl stop "$service"
    fi
done

# Step 9: Set permissions for Automata home directory files
log "Setting permissions for Automata home directory files..."
find "/home/Automata" -path "/home/Automata/.cache" -prune -o -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>> "$LOGFILE"
find "/home/Automata" -path "/home/Automata/.cache" -prune -o -type f -name "*.png" -exec chmod +r {} \; 2>> "$LOGFILE"
chown -R Automata:Automata /home/Automata

# Step 10: Configure PCManFM (file manager)
log "Configuring PCManFM..."
PCMANFM_CONFIG_DIR="/home/Automata/.config/pcmanfm/LXDE-pi"
mkdir -p "$PCMANFM_CONFIG_DIR"

cat <<EOL > "$PCMANFM_CONFIG_DIR/pcmanfm.conf"
[ui]
show_hidden=1
single_click=0
EOL

chmod +r "$PCMANFM_CONFIG_DIR/pcmanfm.conf"
chown Automata:Automata "$PCMANFM_CONFIG_DIR/pcmanfm.conf"

log "PCManFM configuration completed."

# Step 11: Run the installation progress GUI
log "Running installation GUI..."
sudo -u Automata DISPLAY=:0 python3 /home/Automata/install_progress_gui.py &

log "AutomataControls installation script completed. GUI should now be running."

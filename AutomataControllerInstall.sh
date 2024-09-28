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

# Step 2: Log file setup
LOGFILE="/home/Automata/install_log.txt"
log "Installation started"

# Step 5: Install minimal dependencies for GUI creation
log "Installing minimal dependencies for GUI creation..."
apt-get install -y python3-tk python3-pil python3-pil.imagetk gnome-terminal dos2unix

# Step 6: Clone the repository and set permissions
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
log "Cloning AutomataControls repository..."
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/AutomataControls/AutomataBuildingManagment-HvacController.git "$REPO_DIR"
    log "Repository cloned successfully!"
else
    log "Repository already exists, skipping clone."
fi

# Immediately set permissions after cloning for redundancy
log "Setting permissions for files in repository..."
chown -R Automata:Automata "$REPO_DIR"
find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>> "$LOGFILE"
find "$REPO_DIR" -type f -name "*.png" -exec chmod +r {} \; 2>> "$LOGFILE"
chown -R Automata:Automata "$REPO_DIR"

# Step 7: Convert line endings to Unix format
log "Converting line endings for all .sh and .py files to Unix format..."
find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec dos2unix {} \;
find /home/Automata -type f \( -name "*.sh" -o -name "*.py" \) -exec dos2unix {} \;
log "Line endings converted successfully!"

# Step 8: Copy the installation progress GUI script from the repo and set permissions
log "Copying installation progress GUI script and setting permissions..."
cp "$REPO_DIR/install_progress_gui.py" /home/Automata/install_progress_gui.py
chmod +x /home/Automata/install_progress_gui.py
chown Automata:Automata /home/Automata/install_progress_gui.py

# Step 9: Kill lingering services before continuing
log "Killing lingering services (Node-RED, Mosquitto)..."
services=('nodered' 'mosquitto')
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log "Stopping $service service..."
        systemctl stop "$service"
    fi
done

# Step 10: Set permissions for repository and Automata files after reboot
log "Setting permissions for files in repository (redundant step after cloning)..."
if [ -d "$REPO_DIR" ]; then
    log "Re-setting permissions for files in repository directory..."
    
    # Ensure executable permissions for .sh, .py files
    find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>> "$LOGFILE"
    
    # Ensure read permissions for .png files
    find "$REPO_DIR" -type f -name "*.png" -exec chmod +r {} \; 2>> "$LOGFILE"
    
    # Set ownership to Automata for the entire directory
    chown -R Automata:Automata "$REPO_DIR"
    
    # Exclude .cache directory and set permissions for home directory files
    find "/home/Automata" -path "/home/Automata/.cache" -prune -o -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \; 2>> "$LOGFILE"
    find "/home/Automata" -path "/home/Automata/.cache" -prune -o -type f -name "*.png" -exec chmod +r {} \; 2>> "$LOGFILE"
    chown -R Automata:Automata /home/Automata
fi

# Step 11: Enable single-click execution in PCManFM (file manager)
log "Enabling single-click execution for desktop icons..."
PCMANFM_CONFIG_DIR="/home/Automata/.config/pcmanfm/LXDE-pi"
mkdir -p "$PCMANFM_CONFIG_DIR"

cat <<EOL > "$PCMANFM_CONFIG_DIR/pcmanfm.conf"
[ui]
show_hidden=1
single_click=0
EOL

# Ensure proper permissions for the config file
chmod +r "$PCMANFM_CONFIG_DIR/pcmanfm.conf"
chown Automata:Automata "$PCMANFM_CONFIG_DIR/pcmanfm.conf"

log "Single-click execution enabled for desktop icons."

# Step 12: Run the installation progress GUI
log "Running installation GUI..."
sudo -u Automata DISPLAY=:0 python3 /home/Automata/install_progress_gui.py &

# Keep the script running until the Python process ends
while pgrep -f "python3 /home/Automata/install_progress_gui.py" > /dev/null; do
    sleep 1
done

log "AutomataControls Repo Clone Success! Installation process completed."

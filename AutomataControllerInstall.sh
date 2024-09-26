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

# Step 3: Install minimal dependencies for GUI creation
log "Installing minimal dependencies for GUI creation..."
apt-get update
apt-get install -y python3-tk python3-pil python3-pil.imagetk gnome-terminal

# Step 4: Copy the installation progress GUI script from the repo and set permissions
log "Copying installation progress GUI script and setting permissions..."
cp /home/Automata/AutomataBuildingManagment-HvacController/install_progress_gui.py /home/Automata/install_progress_gui.py
chmod +x /home/Automata/install_progress_gui.py

# Step 5: Run the installation progress GUI
log "Running installation GUI..."
sudo -u Automata DISPLAY=:0 python3 /home/Automata/install_progress_gui.py &

# Step 6: Kill lingering services before continuing
log "Killing lingering services (Node-RED, Mosquitto)..."
services=('nodered' 'mosquitto')
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log "Stopping $service service..."
        systemctl stop "$service"
    fi
done

# Step 7: Set permissions for repository and Automata files after reboot
log "Setting permissions for files in repository..."
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
if [ -d "$REPO_DIR" ]; then
    log "Setting permissions for files in repository directory..."
    find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
    find "$REPO_DIR" -type f -name "*.png" -exec chmod +r {} \;
    
    # Exclude .cache directory to avoid permission issues
    find "/home/Automata" -path "/home/Automata/.cache" -prune -o -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
    find "/home/Automata" -path "/home/Automata/.cache" -prune -o -type f -name "*.png" -exec chmod +r {} \;
fi

log "AutomataControls Repo Clone Success! Initializing Install."


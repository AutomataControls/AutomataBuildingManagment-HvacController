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
apt-get install -y python3-tk python3-pil python3-pil.imagetk gnome-terminal dos2unix git

# Step 4: Clone the AutomataControls repository and set permissions
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
log "Cloning AutomataControls repository..."
if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/AutomataControls/AutomataBuildingManagment-HvacController.git "$REPO_DIR"
    log "Repository cloned successfully!"
else
    log "Repository already exists, skipping clone."
fi

# Set permissions for repository files
log "Setting permissions for files in repository..."
chown -R Automata:Automata "$REPO_DIR"
find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
find "$REPO_DIR" -type f -name "*.png" -exec chmod +r {} \;

# Step 5: Convert line endings to Unix format
log "Converting line endings for all .sh and .py files to Unix format..."
find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec dos2unix {} \;

# Step 6: Clone Sequent Microsystems board repositories
BOARDS=("megabas-rpi" "megaind-rpi" "16relind-rpi" "8relind-rpi" "16univin-rpi")
REPO_BASE_URL="https://github.com/SequentMicrosystems"

log "Cloning Sequent Microsystems board repositories..."
for board in "${BOARDS[@]}"; do
    BOARD_DIR="/home/Automata/${board}"
    if [ ! -d "$BOARD_DIR" ]; then
        log "Cloning $board repository..."
        run_shell_command "git clone ${REPO_BASE_URL}/${board}.git $BOARD_DIR"
        sleep 3
    else
        log "$board repository already exists, skipping clone."
    fi
done

# Step 7: Run the installation progress GUI
log "Running installation GUI..."
sudo -u Automata DISPLAY=:0 python3 /home/Automata/AutomataBuildingManagment-HvacController/install_progress_gui.py &

# Keep the script running until the Python process ends
while pgrep -f "python3 /home/Automata/AutomataBuildingManagment-HvacController/install_progress_gui.py" > /dev/null; do
    sleep 1
done

log "AutomataControls Repo Clone Success! Installation process completed."

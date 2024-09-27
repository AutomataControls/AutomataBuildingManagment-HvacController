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

# Step 3: Copy and set up the uninstall GUI Python script
UNINSTALL_GUI="/home/Automata/uninstall_progress_gui.py"

# Make sure the uninstall_progress_gui.py file exists
if [ ! -f "$UNINSTALL_GUI" ]; then
    echo "Error: $UNINSTALL_GUI not found. Exiting uninstallation process."
    exit 1
fi

# Set permissions
chmod +x $UNINSTALL_GUI
chown Automata:Automata $UNINSTALL_GUI
log "Permissions set for $UNINSTALL_GUI"

# Step 4: Launch the GUI
log "Launching Uninstall Progress GUI..."
python3 $UNINSTALL_GUI &
log "Uninstall Progress GUI launched successfully."

# Continue with any additional uninstallation steps needed...

log "Uninstallation process completed successfully."



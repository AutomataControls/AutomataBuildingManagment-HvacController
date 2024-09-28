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

# Step 3: Stop and disable related services (Mosquitto, Node-RED, Chromium-launch)
log "Stopping and disabling related services (Mosquitto, Node-RED, Chromium-launch)..."
services=('mosquitto' 'nodered' 'chromium-launch')
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log "Stopping $service service..."
        systemctl stop "$service"
    fi
    if systemctl is-enabled --quiet "$service"; then
        log "Disabling $service service..."
        systemctl disable "$service"
    fi
done

# Step 4: Remove systemd service files for Chromium auto-launch
log "Removing Chromium auto-launch service..."
if [ -f "/etc/systemd/system/chromium-launch.service" ]; then
    rm /etc/systemd/system/chromium-launch.service
    log "Chromium auto-launch service removed"
fi

# Step 5: Remove desktop icons
log "Removing Node-RED desktop icons..."
if [ -f "/home/Automata/Desktop/OpenNodeRedUI.desktop" ]; then
    rm /home/Automata/Desktop/OpenNodeRedUI.desktop
    log "Node-RED desktop icon removed"
fi

# Step 6: Remove Node-RED themes and palettes
log "Removing Node-RED palettes and themes..."
rm -rf /home/Automata/.node-red/node_modules/@node-red-contrib-themes/theme-collection
log "Node-RED themes removed"

# Step 7: Revert file permissions
log "Reverting file permissions..."
find "/home/Automata/AutomataBuildingManagment-HvacController" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod -x {} \;
find "/home/Automata/AutomataBuildingManagment-HvacController" -type f -name "*.png" -exec chmod -r {} \;

# Step 8: Remove the copied splash screen and restore the original
log "Restoring original splash screen..."
if [ -f "/usr/share/plymouth/themes/pix/splash.png.bk" ]; then
    mv /usr/share/plymouth/themes/pix/splash.png.bk /usr/share/plymouth/themes/pix/splash.png
    log "Original splash screen restored"
fi

# Step 9: Revert LXDE wallpaper configuration
log "Reverting LXDE wallpaper configuration..."
if [ -f "/home/Automata/.config/pcmanfm/LXDE-pi/desktop-items-0.conf" ]; then
    rm /home/Automata/.config/pcmanfm/LXDE-pi/desktop-items-0.conf
    log "LXDE wallpaper configuration reverted"
fi

# Step 10: Remove GUI progress scripts
log "Removing installation progress GUI scripts..."
if [ -f "/home/Automata/install_progress_gui.py" ]; then
    rm /home/Automata/install_progress_gui.py
    log "Installation progress GUI script removed"
fi

# Step 11: Prepare and execute the Uninstall Progress GUI
log "Preparing and executing the Uninstall Progress GUI..."

# Check if uninstall_progress_gui.py exists in the repository directory
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
UNINSTALL_GUI_SCRIPT="$REPO_DIR/uninstall_progress_gui.py"

if [ -f "$UNINSTALL_GUI_SCRIPT" ]; then
    # Copy it to /home/Automata if not already there
    if [ ! -f "/home/Automata/uninstall_progress_gui.py" ]; then
        cp "$UNINSTALL_GUI_SCRIPT" /home/Automata/
        log "Uninstall Progress GUI script copied to /home/Automata"
    fi
else
    log "Uninstall Progress GUI script not found in repository directory."
    echo "Error: $UNINSTALL_GUI_SCRIPT not found. Uninstallation will proceed without GUI."
fi

# Make uninstall_progress_gui.py executable and run it
if [ -f "/home/Automata/uninstall_progress_gui.py" ]; then
    chmod +x /home/Automata/uninstall_progress_gui.py
    log "Uninstall Progress GUI script is now executable"
    
    # Execute the Uninstall Progress GUI script
    log "Launching the Uninstall Progress GUI..."
    sudo -u Automata DISPLAY=:0 python3 /home/Automata/uninstall_progress_gui.py &
else
    log "Uninstall Progress GUI script not found in /home/Automata."
    echo "Error: /home/Automata/uninstall_progress_gui.py not found. Uninstallation will proceed without GUI."
fi

log "Uninstallation process completed."

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
    local step="$2"
    local total_steps="$3"
    local message="$4"

    log "[$step/$total_steps] $message"
    eval "$command"

    if [ $? -ne 0 ]; then
        log "Error occurred while running: $command"
        exit 1
    fi
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

# Step 3: Install only dependencies needed for GUI creation
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

# Step 7: Slightly overclock the Raspberry Pi (optional)
log "Overclocking CPU... Turning up to 11 Meow!"
cat << 'EOF' >> /boot/config.txt
# Slight overclocking for better performance
over_voltage=2
arm_freq=1750
EOF

# Step 8: Install Sequent MS Drivers, Node-RED, and other required steps (interactive Node-RED without closing)
log "Installing Sequent Microsystems drivers and Node-RED..."

# Install Sequent MS Drivers (Modify for each board)
boards=("megabas-rpi" "megaind-rpi" "16univin-rpi" "16relind-rpi" "8relind-rpi")
total_steps=12
step=1
for board in "${boards[@]}"; do
    if [ -d "/home/Automata/AutomataBuildingManagment-HvacController/$board" ]; then
        log "Installing Sequent MS driver for $board..."
        run_shell_command "cd /home/Automata/AutomataBuildingManagment-HvacController/$board && sudo make install" "$step" "$total_steps" "Installing $board driver..."
        sleep 2
    else
        log "Board $board not found, skipping..."
    fi
    step=$((step + 1))
done

# Install Node-RED interactively (without closing the terminal)
run_shell_command "bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh" "$step" "$total_steps" "Installing Node-RED interactively..."
sleep 2

# Install Node-RED palettes
run_shell_command "bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh" "$step" "$total_steps" "Installing Node-RED palettes..."
sleep 2

# Move splash screen
run_shell_command "sudo mv /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/splash.png" "$step" "$total_steps" "Moving splash.png..."
sleep 2

# Set boot splash screen (wallpaper removed per your request)
run_shell_command "bash /home/Automata/AutomataBuildingManagment-HvacController/set_boot_splash_screen.sh" "$step" "$total_steps" "Setting boot splash screen..."
sleep 2

# Configure interfaces (i2c, spi, vnc, etc.)
run_shell_command "sudo raspi-config nonint do_i2c 0 && sudo raspi-config nonint do_spi 0 && sudo raspi-config nonint do_vnc 0 && sudo raspi-config nonint do_onewire 0 && sudo raspi-config nonint do_serial 1" "$step" "$total_steps" "Configuring interfaces..."
sleep 2

# Install Mosquitto and set password
run_shell_command "sudo apt-get install -y mosquitto mosquitto-clients" "$step" "$total_steps" "Installing Mosquitto..."
run_shell_command "sudo touch /etc/mosquitto/passwd && sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2" "$step" "$total_steps" "Setting Mosquitto password file..."
sleep 2

# Increase swap size
run_shell_command "bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh" "$step" "$total_steps" "Increasing swap size..."
sleep 2

# Final step: installation complete
update_progress "$total_steps" "$total_steps" "Installation complete. Please reboot."
show_reboot_prompt

# Step 9: Set up Chromium Auto-launch
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
subprocess.Popen(['chromium-browser', '--new-window', 'http://127.0.0.1:1880/', 'http://127.0.0.1:1880/ui'])
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

# Step 10: Set up systemd service to trigger update_progress_gui.py on reboot
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

# Step 11: Permissions for the repo files after reboot
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


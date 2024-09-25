
#!/bin/bash

# Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Re-running with sudo..."
    sudo bash "$0" "$@"
    exit
fi

# Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

# Step 1: Check if LXTerminal or Gnome-Terminal is installed
echo "Checking for a fully-featured terminal..."
if command -v lxterminal &> /dev/null; then
    TERMINAL="lxterminal"
    echo "LXTerminal detected. Running the rest of the script in LXTerminal."
elif command -v gnome-terminal &> /dev/null; then
    TERMINAL="gnome-terminal"
    echo "Gnome-Terminal detected. Running the rest of the script in Gnome-Terminal."
else
    echo "Error: Neither LXTerminal nor Gnome-Terminal is installed."
    echo "Please install one of these terminals and run this script again."
    exit 1
fi

# Relaunch the script in the detected terminal and wait for it to finish
if [ -z "$LXTERMINAL_STARTED" ]; then
    LXTERMINAL_STARTED=1 $TERMINAL -e "bash -c 'LXTERMINAL_STARTED=1 bash $0'" &
    wait
    exit 0
fi

# Step 2: Stop services if running
echo "Stopping and disabling conflicting services..."
if systemctl is-active --quiet nodered; then
    sudo systemctl stop nodered
fi
if systemctl is-active --quiet mosquitto; then
    sudo systemctl stop mosquitto
fi
if systemctl is-enabled --quiet nodered; then
    sudo systemctl disable nodered
fi
if systemctl is-enabled --quiet mosquitto; then
    sudo systemctl disable mosquitto
fi
sudo rm -f /etc/mosquitto/passwd || echo "No previous Mosquitto password file to remove"

# Remove previous installation logs if they exist
if [ -f "$LOGFILE" ]; then
    sudo rm "$LOGFILE"
    echo "Previous installation log file removed."
fi

# Step 3: Install Zenity for dialog boxes
echo "Installing Zenity..."
sudo apt-get install -y zenity

# Step 4: Install required dependencies
echo "Installing required dependencies..."
sudo apt-get update
sudo apt-get install -y feh

# Step 5: Set executable permissions for all scripts in the repository
echo "Setting executable permissions for all scripts..."
sudo chmod -R +x /home/Automata/AutomataBuildingManagment-HvacController/*.sh

# Step 6: Move FullLogo.png from the repository to the home directory
LOGO_SRC="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"
LOGO_DEST="/home/Automata/FullLogo.png"

if [ -f "$LOGO_SRC" ]; then
    echo "Moving FullLogo.png to home directory..."
    sudo mv "$LOGO_SRC" "$LOGO_DEST"
else
    echo "Error: $LOGO_SRC not found."
fi

# Step 7: Set FullLogo.png as desktop wallpaper and splash screen
if [ -f "$LOGO_DEST" ]; then
    echo "Setting logo as wallpaper and splash screen..."
    sudo -u Automata DISPLAY=:0 pcmanfm --set-wallpaper="$LOGO_DEST" || echo "Warning: Could not set wallpaper."
    sudo cp "$LOGO_DEST" /usr/share/plymouth/themes/pix/splash.png
else
    echo "Error: $LOGO_DEST not found."
fi

# Step 8: Enable I2C, SPI, RealVNC, 1-Wire, Remote GPIO, and disable serial port
echo "Enabling I2C, SPI, RealVNC, 1-Wire, Remote GPIO, and disabling serial port..."
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_vnc 0
sudo raspi-config nonint do_onewire 0
sudo raspi-config nonint do_rgpio 0
sudo raspi-config nonint do_serial 1

# Step 9: Install Mosquitto but do not start the service until after reboot
echo "Installing Mosquitto..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y mosquitto mosquitto-clients
sudo touch /etc/mosquitto/passwd
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2
echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf

# Step 10: Increase swap size
echo "Increasing swap size..."
run_script "increase_swap_size.sh"

# Step 11: Traditional Node-RED installation with prompts
echo "Installing Node-RED using traditional method with prompts..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

# Enable Node-RED service to start on boot
sudo systemctl enable nodered.service

# Start Node-RED service immediately
sudo systemctl start nodered.service || echo "Warning: Node-RED service failed to start. Check logs."

# Step 12: Run InstallNodeRedPallete.sh to install Node-RED nodes and themes
echo "Running InstallNodeRedPallete.sh to install Node-RED nodes and themes..."
bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh

# Step 13: Add Chromium auto-start script from repository
echo "Adding Chromium auto-start script..."
sudo chmod +x /home/Automata/AutomataBuildingManagment-HvacController/InstallChromiumAutoStart.sh

# Create the Chromium launch script to ensure it's not running in kiosk mode
cat << 'EOF' > /home/Automata/AutomataBuildingManagment-HvacController/InstallChromiumAutoStart.sh
#!/bin/bash

# Wait for the network to be connected
while ! ping -c 1 127.0.0.1 &>/dev/null; do
    sleep 1
done

# Wait for an additional 10 seconds after network connection
sleep 10

# Launch Chromium in windowed mode (not full-screen or kiosk mode)
chromium-browser --no-sandbox --new-window http://127.0.0.1:1880/ http://127.0.0.1:1880/ui &
EOF

# Make the Chromium launch script executable
chmod +x /home/Automata/AutomataBuildingManagment-HvacController/InstallChromiumAutoStart.sh

# Run the Chromium auto-start script
/home/Automata/AutomataBuildingManagment-HvacController/InstallChromiumAutoStart.sh

# Step 14: Create one-time autostart entry for board updates

# Define the autostart file path
AUTOSTART_FILE="/home/Automata/.config/lxsession/LXDE-pi/autostart"

# Ensure the .config/lxsession/LXDE-pi directory exists
if [ ! -d "/home/Automata/.config/lxsession/LXDE-pi" ]; then
    echo "Creating autostart directory..."
    mkdir -p "/home/Automata/.config/lxsession/LXDE-pi"
fi

# Remove any existing entry for update_sequent_boards.sh from autostart
if grep -q 'update_sequent_boards.sh' "$AUTOSTART_FILE"; then
    echo "Removing old update_sequent_boards.sh entry from autostart..."
    sed -i '/update_sequent_boards.sh/d' "$AUTOSTART_FILE"
fi

# Define the script to update Sequent boards
cat << 'EOF' > /home/Automata/update_sequent_boards.sh
#!/bin/bash

# Define paths for each Sequent board update folder
BOARDS=(
    "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update"
)

# Iterate over each board directory and run the update script
for board in "${BOARDS[@]}"; do
    if [ -d "$board" ]; then
        echo "Updating board in $board"
        (cd "$board" && ./update 0) || echo "Warning: Update failed in $board"
    else
        echo "Error: Board directory $board not found."
    fi
done

# Remove this script from autostart to prevent it from running again
sed -i '/update_sequent_boards.sh/d' "$AUTOSTART_FILE"

EOF

# Make the update script executable
chmod +x /home/Automata/update_sequent_boards.sh

# Add the update script to autostart if not already added
if ! grep -q 'update_sequent_boards.sh' "$AUTOSTART_FILE"; then
    echo "@/home/Automata/update_sequent_boards.sh" >> "$AUTOSTART_FILE"
    echo "Added update_sequent_boards.sh to autostart."
else
    echo "update_sequent_boards.sh is already in autostart."
fi

# Step 15: Display teal dialog box with final message using Zenity
echo "Displaying final message before reboot..."

zenity --question \
--title="Automata BMS Installation Complete" \
--width=400 --height=300 \
--text="<span font='16' foreground='black'><b>Congratulations,</b> Automata BMS Has Successfully Installed.\n\nA New Realm of Automation Awaits!\nPlease Reboot to Finalize Settings.\n\n<b>Reboot Now?</b></span>" \
--ok-label="Yes" \
--cancel-label="No" \
--icon-name="$LOGO_DEST" --window-icon="$LOGO_DEST" --timeout=30 --no-wrap --background="#00b3b3"

if [ $? = 0 ]; then
    echo "Rebooting system..."
    sudo reboot
else
    echo "Installation completed without reboot. Please reboot manually."
fi

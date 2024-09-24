
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

# ----------------------- Remaining Script Logic Starts Here -----------------------

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

# Step 6: Set system clock to local internet time and correct timezone
echo "Skipping NTP setup, manually setting the timezone..."
sudo timedatectl set-timezone America/New_York

# Step 7: Set FullLogo.png as desktop wallpaper and splash screen
LOGO_PATH="/home/Automata/FullLogo.png"
if [ -f "$LOGO_PATH" ]; then
    echo "Setting logo as wallpaper and splash screen..."
    sudo -u Automata DISPLAY=:0 pcmanfm --set-wallpaper="$LOGO_PATH" || echo "Warning: Could not set wallpaper."
    sudo cp "$LOGO_PATH" /usr/share/plymouth/themes/pix/splash.png
else
    echo "Error: $LOGO_PATH not found."
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

# Run the Chromium auto-start script
/home/Automata/AutomataBuildingManagment-HvacController/InstallChromiumAutoStart.sh

# Step 14: Create one-time autostart entry for update_sequent_boards.sh
echo "Creating one-time autostart entry for update_sequent_boards.sh..."
cat << 'EOF' > /home/Automata/update_sequent_boards.sh
#!/bin/bash

# Run the update script
/home/Automata/AutomataBuildingManagment-HvacController/update_sequent_boards.sh

# Remove this script from autostart to only run once
AUTOSTART_FILE="/home/Automata/.config/lxsession/LXDE-pi/autostart"
sed -i '/update_sequent_boards.sh/d' "$AUTOSTART_FILE"
EOF

# Make it executable
chmod +x /home/Automata/update_sequent_boards.sh

# Add to autostart
if ! grep -q 'update_sequent_boards.sh' "/home/Automata/.config/lxsession/LXDE-pi/autostart"; then
    echo "@/home/Automata/update_sequent_boards.sh" >> "/home/Automata/.config/lxsession/LXDE-pi/autostart"
fi

# Final message before reboot
echo "Installation completed. The system will reboot in 10 seconds."
sleep 10
sudo reboot

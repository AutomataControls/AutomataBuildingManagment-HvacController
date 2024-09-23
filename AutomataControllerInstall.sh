#!/bin/bash

# Function to run a script and handle errors
run_script() {
    sudo bash "$1" || { echo "Error: $1 failed, continuing..."; }
}

# Step 1: Set system clock to local internet time and correct timezone
echo "Setting system clock and adjusting for Eastern Standard Time (EST)..."
sudo timedatectl set-timezone America/New_York  # Eastern Standard Time
run_script "set_internet_time_rpi4.sh"

# Step 2: Set FullLogo.png as desktop and splash screen
LOGO_PATH="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"
if [ -f "$LOGO_PATH" ]; then
    echo "Setting logo image..."
    sudo cp "$LOGO_PATH" /root/FullLogo.png
else
    echo "Error: $LOGO_PATH not found. Please place FullLogo.png in the correct directory."
fi

# Step 3: Install Mosquitto and configure user authentication
echo "Installing Mosquitto and setting up user authentication..."
sudo apt-get install -y mosquitto mosquitto-clients
sudo mosquitto_passwd -c /etc/mosquitto/passwd Automata
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2

echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf

# Enable and restart Mosquitto service
sudo systemctl enable mosquitto
sudo systemctl restart mosquitto

# Step 4: Increase the swap size to 2048 MB
run_script "increase_swap_size.sh"

# Step 5: Install/update Node-RED and enable the service
run_script "install_node_red.sh"

# Step 6: Run SequentMSInstall.sh to install Sequent Microsystems drivers
run_script "SequentMSInstall.sh"

# Step 7: Enable I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH; disable serial port
echo "Enabling I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH; disabling serial port..."

# Enable I2C
sudo raspi-config nonint do_i2c 0
echo "I2C enabled."

# Enable SPI
sudo raspi-config nonint do_spi 0
echo "SPI enabled."

# Enable VNC
sudo raspi-config nonint do_vnc 0
echo "VNC enabled."

# Enable 1-Wire
sudo raspi-config nonint do_onewire 0
echo "1-Wire enabled."

# Enable Remote GPIO
sudo raspi-config nonint do_rgpio 0
echo "Remote GPIO enabled."

# Enable SSH
sudo raspi-config nonint do_ssh 0
echo "SSH enabled."

# Disable Serial Port
sudo raspi-config nonint do_serial 1
echo "Serial port disabled."

# Step 8: Create a desktop icon to launch Chromium to Node-RED and UI
DESKTOP_FILE="/home/Automata/Desktop/NodeRed.desktop"
echo "[Desktop Entry]" > "$DESKTOP_FILE"
echo "Version=1.0" >> "$DESKTOP_FILE"
echo "Name=Node-RED Dashboard" >> "$DESKTOP_FILE"
echo "Comment=Open Node-RED in Chromium" >> "$DESKTOP_FILE"
echo "Exec=chromium-browser --new-window http://127.0.0.1:1880/ http://127.0.0.1:1880/ui" >> "$DESKTOP_FILE"
echo "Icon=chromium" >> "$DESKTOP_FILE"
echo "Terminal=false" >> "$DESKTOP_FILE"
echo "Type=Application" >> "$DESKTOP_FILE"
echo "Categories=Utility;Application;" >> "$DESKTOP_FILE"

# Make the desktop file executable
chmod +x "$DESKTOP_FILE"
echo "Desktop icon created at $DESKTOP_FILE."

# Step 9: Reboot the system to apply all changes
echo "Rebooting the system now..."
sudo reboot

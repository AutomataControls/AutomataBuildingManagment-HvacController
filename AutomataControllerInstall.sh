#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

# Step 0: Cleanup previous installation attempts and stop services
echo "Stopping and disabling conflicting services..."

# Stop services only if they exist and are running
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

 Commenting out some steps to prevent potential issues
 echo "Skipping enabling hardware interfaces for now to avoid conflicts..."
 sudo raspi-config nonint do_i2c 0
 sudo raspi-config nonint do_spi 0
 sudo raspi-config nonint do_vnc 0
 sudo raspi-config nonint do_onewire 0
 sudo raspi-config nonint do_rgpio 0
 sudo raspi-config nonint do_serial 1

# Step 1: Set executable permissions for all files in the cloned repository
echo "Setting executable permissions for all scripts in the repository..."
sudo chmod -R +x /home/Automata/AutomataBuildingManagment-HvacController/*.sh
echo "Permissions set for all .sh files."

# Step 2: Set system clock to local internet time and correct timezone
echo "Skipping NTP setup, manually setting the timezone..."
sudo timedatectl set-timezone America/New_York  # Set timezone to EST
echo "System timezone set to Eastern Standard Time (EST)."

# Step 3: Install Mosquitto but do not start the service until after reboot
echo "Installing Mosquitto..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y mosquitto mosquitto-clients
sudo touch /etc/mosquitto/passwd
echo "Setting up Mosquitto password for user Automata..."
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2
echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf
echo "Mosquitto installed but service will not be started until after reboot."

# Step 4: Increase the swap size to 2048 MB
# Commenting this out to prevent any swap-related issues
# echo "Increasing swap size..."
# run_script "increase_swap_size.sh"
# echo "Swap size increased."

# Step 5: Install Node-RED non-interactively and prevent prompts
echo "Running install_node_red.sh to install Node-RED non-interactively..."
sudo -u Automata bash << 'EOF'
#!/bin/bash

# Install or update Node.js and Node-RED non-interactively
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-install --confirm-pi --node20

# Enable Node-RED service to start on boot
sudo systemctl enable nodered.service

# Start Node-RED service immediately
sudo systemctl start nodered.service || echo "Warning: Node-RED service failed to start. Check logs."

echo "Node-RED has been installed or updated, and the service is now enabled to start on boot."
EOF

# Step 6: Adding post-reboot process (can disable for debugging)
echo "Skipping post-reboot updates temporarily to test boot process..."

# Comment out the /etc/rc.local updates to prevent issues
# sudo tee /etc/rc.local > /dev/null << 'EOF'
# Post-reboot script to stop services, update boards, and reboot again
# EOF
# sudo chmod +x /etc/rc.local

# Final message
echo "Installation completed. The system will reboot in 10 seconds to finalize the process."
sleep 10
sudo reboot

#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

# Step 1: Set executable permissions for all files in the cloned repository
echo "Setting executable permissions for all scripts in the repository..."
sudo chmod -R +x /home/Automata/AutomataBuildingManagment-HvacController/*.sh
echo "Permissions set for all .sh files."

# Function to run a script and handle errors
run_script() {
    sudo bash "$1" || { echo "Error: $1 failed, continuing..."; }
}

# Step 2: Install Zenity for dialog boxes
echo "Installing Zenity..."
sudo apt-get install -y zenity

# Step 3: Set system clock to local internet time and correct timezone
echo "Setting system clock and adjusting for Eastern Standard Time (EST)..."
sudo timedatectl set-timezone America/New_York  # Eastern Standard Time
run_script "set_internet_time_rpi4.sh"

# Step 4: Install feh and set FullLogo.png as desktop wallpaper and splash screen as the 'Automata' user
echo "Installing feh..."
sudo apt-get install -y feh

LOGO_PATH="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"

if [ -f "$LOGO_PATH" ]; then
    echo "Setting logo as wallpaper and splash screen..."
    sudo -u Automata feh --bg-scale "$LOGO_PATH" || echo "Warning: Could not set wallpaper."
    sudo cp "$LOGO_PATH" /usr/share/plymouth/themes/pix/splash.png
    echo "Logo set successfully."
else
    echo "Error: $LOGO_PATH not found. Please place FullLogo.png in the correct directory."
fi

# Step 5: Install Mosquitto and configure user authentication
echo "Installing Mosquitto and setting up user authentication..."

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation
export DEBIAN_FRONTEND=noninteractive

# Install Mosquitto and clients without prompting for confirmation
sudo apt-get install -y mosquitto mosquitto-clients

# Add Mosquitto user and password in non-interactive mode
sudo touch /etc/mosquitto/passwd
echo "Setting up Mosquitto password for user Automata..."
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2

# Create Mosquitto configuration
echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf

# Enable and restart Mosquitto service
sudo systemctl enable mosquitto
sudo systemctl restart mosquitto || echo "Warning: Mosquitto service failed to start. Check logs."

# Step 6: Increase the swap size to 2048 MB
run_script "increase_swap_size.sh"

# Step 7: Run install_node_red.sh to install or update Node-RED as Automata user
if [ -f "/home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh" ]; then
    echo "Running install_node_red.sh to install or update Node-RED as Automata user..."
    sudo -u Automata bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh
else
    echo "Error: install_node_red.sh not found. Please place the script in the correct directory."
fi

# Step 8: Run SequentMSInstall.sh to install Sequent Microsystems drivers
if [ -f "/home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh" ]; then
    echo "Running SequentMSInstall.sh..."

    # Install multiple Sequent Microsystems repositories
    git clone https://github.com/SequentMicrosystems/megabas-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/megaind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/16univin-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/16relind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi && sudo make install

    git clone https://github.com/SequentMicrosystems/8relind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi
    cd /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi && sudo make install
else
    echo "SequentMSInstall.sh not found, skipping..."
fi

# Step 9: Update Sequent Microsystems boards with ./update 0 after installation
echo "Updating Sequent Microsystems boards with ./update 0..."

# Update each board
cd /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
sudo ./update 0 || { echo "Board update for megabas failed. Check logs."; exit 1; }

cd /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
sudo ./update 0 || { echo "Board update for megaind failed. Check logs."; exit 1; }

cd /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi
sudo ./update 0 || { echo "Board update for 16univin failed. Check logs."; exit 1; }

cd /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi
sudo ./update 0 || { echo "Board update for 16relind failed. Check logs."; exit 1; }

cd /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi
sudo ./update 0 || { echo "Board update for 8relind failed. Check logs."; exit 1; }

# Step 10: Show success dialog box after updates
zenity --info --width=400 --height=300 --text="You have successfully installed and updated Automata Control System Components, including Sequent Microsystems boards. A realm of automation awaits!" --title="Installation Complete" --window-icon="$LOGO_PATH" --ok-label="Finish"

echo "Installation and board updates completed successfully."

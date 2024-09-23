#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

INSTALLATION_STEP_FILE="/home/Automata/installation_step.txt"

# Function to save the installation step
save_step() {
    echo "$1" > "$INSTALLATION_STEP_FILE"
}

# Function to run a script and handle errors
run_script() {
    sudo bash "$1" || { echo "Error: $1 failed, continuing..."; }
}

# Check the installation step
if [ -f "$INSTALLATION_STEP_FILE" ]; then
    INSTALLATION_STEP=$(cat "$INSTALLATION_STEP_FILE")
else
    INSTALLATION_STEP="start"
fi

# Step 1: Set executable permissions for all files in the cloned repository
if [ "$INSTALLATION_STEP" == "start" ]; then
    echo "Setting executable permissions for all scripts in the repository..."
    sudo chmod -R +x /home/Automata/AutomataBuildingManagment-HvacController/*.sh
    echo "Permissions set for all .sh files."
    save_step "set_clock"
fi

# Step 2: Set system clock to local internet time and correct timezone
if [ "$INSTALLATION_STEP" == "set_clock" ]; then
    echo "Setting system clock and adjusting for Eastern Standard Time (EST)..."
    sudo timedatectl set-timezone America/New_York  # Eastern Standard Time
    run_script "set_internet_time_rpi4.sh"
    save_step "setup_logo"
fi

# Step 3: Set FullLogo.png as desktop wallpaper and splash screen as the 'Automata' user
if [ "$INSTALLATION_STEP" == "setup_logo" ]; then
    LOGO_PATH="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"

    if [ -f "$LOGO_PATH" ]; then
        echo "Setting logo as wallpaper and splash screen..."
        sudo -u Automata feh --bg-scale "$LOGO_PATH" || echo "Warning: Could not set wallpaper."
        sudo cp "$LOGO_PATH" /usr/share/plymouth/themes/pix/splash.png
        echo "Logo set successfully."
    else
        echo "Error: $LOGO_PATH not found. Please place FullLogo.png in the correct directory."
    fi
    save_step "install_mosquitto"
fi

# Step 4: Install Mosquitto but do not start the service
if [ "$INSTALLATION_STEP" == "install_mosquitto" ]; then
    echo "Installing Mosquitto and configuring user authentication..."
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get install -y mosquitto mosquitto-clients
    sudo touch /etc/mosquitto/passwd
    echo "Setting up Mosquitto password for user Automata..."
    sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2
    echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf
    # Do not enable or start the service now
    save_step "increase_swap"
fi

# Step 5: Increase the swap size to 2048 MB
if [ "$INSTALLATION_STEP" == "increase_swap" ]; then
    run_script "increase_swap_size.sh"
    save_step "install_node_red"
fi

# Step 6: Install Node-RED non-interactively and prevent prompts
if [ "$INSTALLATION_STEP" == "install_node_red" ]; then
    if [ -f "/home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh" ]; then
        echo "Running install_node_red.sh to install Node-RED non-interactively..."
        sudo -u Automata bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh --confirm-install --node20
    else
        echo "Error: install_node_red.sh not found."
    fi
    save_step "install_sequent_ms"
fi

# Step 7: Run SequentMSInstall.sh to install Sequent Microsystems drivers
if [ "$INSTALLATION_STEP" == "install_sequent_ms" ]; then
    run_script "/home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh"
    save_step "create_cron_resume"
fi

# Step 8: Setup a cron job to resume the installation after reboot
if [ "$INSTALLATION_STEP" == "create_cron_resume" ]; then
    echo "Creating cron job to resume installation after reboot..."
    (crontab -l 2>/dev/null; echo "@reboot /home/Automata/AutomataBuildingManagment-HvacController/AutomataControllerInstall.sh") | crontab -
    echo "Cron job created. Rebooting system to resume..."
    save_step "after_reboot"
    sudo reboot
fi

# Step 9: After reboot, continue with the remaining steps
if [ "$INSTALLATION_STEP" == "after_reboot" ]; then
    echo "Resuming installation after reboot..."
    # Start Mosquitto service
    sudo systemctl enable mosquitto
    sudo systemctl start mosquitto || echo "Warning: Mosquitto service failed to start. Check logs."

    # Remove cron job after completion
    crontab -l | grep -v '@reboot /home/Automata/AutomataBuildingManagment-HvacController/AutomataControllerInstall.sh' | crontab -
    echo "Installation completed. Mosquitto service started, and cron job removed."
    save_step "complete"
fi

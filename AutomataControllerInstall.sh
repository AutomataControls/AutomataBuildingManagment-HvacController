#!/bin/bash

# Run the script to set the clock to local internet time
sudo bash set_internet_time_rpi4.sh

# Run the script to set FullLogo.png as desktop and splash screen
sudo bash set_full_logo_image_rpi4.sh

# Run the script to install mosquitto, configure user and password
sudo bash setup_mosquitto.sh

# Run the script to increase the swap size to 2048 MB
sudo bash increase_swap_size.sh

# Run the script to install/update Node-RED and enable the service
sudo bash install_node_red.sh

# Reboot the system to apply all changes
echo "Rebooting the system now..."
sudo reboot

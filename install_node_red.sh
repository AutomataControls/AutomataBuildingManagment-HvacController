#!/bin/bash

# Install or update Node-RED by downloading and running the official Node-RED installer script
echo "Running the Node-RED installation script..."

# Download and execute the Node-RED installation script directly
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

# Enable Node-RED service to start on boot (system-wide)
echo "Enabling Node-RED to start on boot..."
sudo systemctl enable nodered.service

# Start Node-RED service immediately (system-wide)
echo "Starting Node-RED service..."
sudo systemctl start nodered.service

echo "Node-RED installation completed."

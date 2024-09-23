#!/bin/bash

# Install or update Node.js and Node-RED non-interactively
echo "Installing or updating Node-RED..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-install --confirm-pi --node20

# Enable Node-RED service to start on boot
echo "Enabling Node-RED to start on boot..."
sudo systemctl enable nodered.service

# Start Node-RED service immediately
echo "Starting Node-RED service..."
sudo systemctl start nodered.service

echo "Node-RED has been installed or updated, and the service is now enabled to start on boot."

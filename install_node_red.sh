#!/bin/bash

# Install or update Node.js and Node-RED
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

# Enable Node-RED service to start on boot
sudo systemctl enable nodered.service

# Start Node-RED service immediately
sudo systemctl start nodered.service

echo "Node-RED has been installed or updated, and the service is now enabled to start on boot."

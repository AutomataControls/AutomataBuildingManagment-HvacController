#!/bin/bash

# Switch to user Automata for the installation
sudo -u Automata bash << EOF

# Install or update Node.js and Node-RED
echo "Installing or updating Node-RED..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

EOF

# Enable Node-RED service to start on boot (system-wide)
echo "Enabling Node-RED to start on boot..."
sudo systemctl enable nodered.service

# Start Node-RED service immediately (system-wide)
echo "Starting Node-RED service..."
sudo systemctl start nodered.service

echo "Node-RED installation completed."

#!/bin/bash

# Switch to user Automata for the installation
sudo -u Automata bash << EOF

# Install or update Node.js and Node-RED with interactive prompts
echo "Installing or updating Node-RED..."
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

# Enable Node-RED service to start on boot
echo "Enabling Node-RED to start on boot..."
systemctl --user enable nodered.service

# Start Node-RED service immediately
echo "Starting Node-RED service..."
systemctl --user start nodered.service

echo "Node-RED installation completed."

EOF

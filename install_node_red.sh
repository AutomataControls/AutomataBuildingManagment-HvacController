#!/bin/bash

# Install or update Node.js and Node-RED as the Automata user
echo "Installing or updating Node-RED as the 'Automata' user..."

# Run the Node-RED installation script
bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered)

echo "Node-RED installation completed."

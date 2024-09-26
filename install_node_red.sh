#!/bin/bash

# Install or update Node.js and Node-RED in a new lxterminal window
echo "Installing or updating Node-RED in a new terminal window..."

# Open a new terminal window and run the Node-RED installation script
lxterminal --command="bash -c 'bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered); exec bash'"

echo "Node-RED installation process initiated."

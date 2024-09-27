#!/bin/bash

# Install or update Node.js and Node-RED in a new lxterminal window
echo "Installing or updating Node-RED in a new terminal window..."

# Open a new terminal window and run the Node-RED installation script
lxterminal --command="bash -c 'bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered); exec bash'"

echo "Node-RED installation process initiated."

# Wait for Node-RED to install before continuing
sleep 3

# Set up Node-RED security
echo "Setting up Node-RED security..."

# Define the username and password
USERNAME="Automata"
PASSWORD="Invertedskynet2"

# Generate hashed password
HASHED_PASSWORD=$(node-red admin hash-pw <<< "$PASSWORD")

# Update the Node-RED settings to include adminAuth with the user credentials
SETTINGS_FILE="/home/Automata/.node-red/settings.js"

if [ -f "$SETTINGS_FILE" ]; then
    sed -i '/^\/\/ adminAuth: {/,/^\/\/ },/ s/^\/\///' "$SETTINGS_FILE"
    sed -i "s/username: \"admin\"/username: \"$USERNAME\"/" "$SETTINGS_FILE"
    sed -i "s/password: \".*\"/password: \"$HASHED_PASSWORD\"/" "$SETTINGS_FILE"
    sed -i "s/permissions: \"\*\"/permissions: \"*\"/" "$SETTINGS_FILE"
    echo "Node-RED security setup completed."
else
    echo "Error: Node-RED settings.js file not found!"
fi

# Restart Node-RED service to apply security changes
sudo systemctl restart nodered.service

echo "Node-RED installation and security setup completed."

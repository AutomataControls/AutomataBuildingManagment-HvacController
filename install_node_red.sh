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

# Wait for Node-RED installation to complete before setting up security
sleep 10

# Install node-red-admin tool for password hashing
echo "Installing node-red-admin for password hashing..."
sudo npm install -g node-red-admin

# Hash the password 'Invertedskynet2'
HASHED_PASSWORD=$(node-red-admin hash-pw <<EOF
Invertedskynet2
EOF
)

# Modify the settings.js file to enable user security
echo "Enabling user security for Node-RED with username 'Automata'..."

SETTINGS_JS="/home/Automata/.node-red/settings.js"

if [ -f "$SETTINGS_JS" ]; then
    # Backup the original settings.js file
    sudo cp "$SETTINGS_JS" "${SETTINGS_JS}.bak"

    # Insert adminAuth section for username and hashed password
    sudo sed -i "/^module.exports = {/a \
    adminAuth: {\
        type: 'credentials',\
        users: [{\
            username: 'Automata',\
            password: '$HASHED_PASSWORD',\
            permissions: '*'\
        }]\
    }," $SETTINGS_JS

    echo "User security has been set up with username 'Automata' and password 'Invertedskynet2'."
else
    echo "Error: settings.js file not found. Node-RED security setup failed."
    exit 1
fi

# Restart Node-RED to apply the changes
echo "Restarting Node-RED to apply security settings..."
sudo systemctl restart nodered.service

echo "Node-RED has been installed or updated, and user security is enabled with username 'Automata'."

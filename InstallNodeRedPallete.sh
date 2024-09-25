#!/bin/bash

# Function to install npm packages and skip if there's an error
install_npm_package() {
    PACKAGE=$1
    echo "Installing $PACKAGE..."
    npm install -g "$PACKAGE" || { 
        echo "Failed to install $PACKAGE. Skipping."; 
        return 1; 
    }
    return 0
}

# Install all the required Node-RED nodes
NODE_PACKAGES=(
    "node-red-contrib-ui-led"
    "node-red-dashboard"
    "node-red-contrib-sm-16inpind"
    "node-red-contrib-sm-16relind"
    "node-red-contrib-sm-8inputs"
    "node-red-contrib-sm-8relind"
    "node-red-contrib-sm-bas"
    "node-red-contrib-sm-ind"
    "node-red-node-openweathermap"
    "node-red-contrib-influxdb"
    "node-red-node-email"
    "node-red-contrib-boolean-logic-ultimate"
    "node-red-contrib-cpu"
    "node-red-contrib-bme280-rpi"
    "node-red-contrib-bme280"
    "node-red-node-aws"
    "node-red-contrib-themes/theme-collection"
)

# Loop through each package and attempt to install it
for package in "${NODE_PACKAGES[@]}"; do
    install_npm_package "$package"
done

# Install Node-RED themes
THEME_PACKAGES=(
    "@node-red-contrib-themes/dark"
    "@node-red-contrib-themes/oled"
)

for theme in "${THEME_PACKAGES[@]}"; do
    install_npm_package "$theme"
done

# Restart Node-RED
echo "Restarting Node-RED..."
sudo systemctl restart nodered

echo "Node-RED nodes and themes installed successfully."

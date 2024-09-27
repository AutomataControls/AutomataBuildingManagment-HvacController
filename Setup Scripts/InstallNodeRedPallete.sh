#!/bin/bash

# Function to install a Node-RED palette and check if the installation was successful
install_palette() {
    local palette_name="$1"
    echo "Installing $palette_name..."
    
    cd ~/.node-red || exit
    npm install "$palette_name"
    
    if [ $? -eq 0 ]; then
        echo "$palette_name installed successfully!"
    else
        echo "Failed to install $palette_name. Please check for errors."
        exit 1
    fi
}

# List of palette nodes to install
palettes=(
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

# Loop through each palette and install it
for palette in "${palettes[@]}"; do
    install_palette "$palette"
done


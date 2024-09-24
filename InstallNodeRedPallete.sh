#!/bin/bash

# Install all the required Node-RED nodes
npm install -g node-red-contrib-ui-led \
               node-red-dashboard \
               node-red-contrib-sm-16inpind \
               node-red-contrib-sm-16relind \
               node-red-contrib-sm-8inputs \
               node-red-contrib-sm-8relind \
               node-red-contrib-sm-bas \
               node-red-contrib-sm-ind \
               node-red-node-openweathermap \
               node-red-contrib-influxdb \
               node-red-node-email \
               node-red-contrib-boolean-logic-ultimate \
               node-red-contrib-cpu \
               node-red-contrib-bme280-rpi \
               node-red-contrib-bme280 \
               node-red-node-aws

# Restart Node-RED
echo "Restarting Node-RED..."
sudo systemctl restart nodered

echo "Node-RED nodes installed successfully."

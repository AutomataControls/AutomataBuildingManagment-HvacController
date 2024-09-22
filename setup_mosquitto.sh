#!/bin/bash

# Update package lists
sudo apt-get update

# Install mosquitto and mosquitto clients
sudo apt-get install -y mosquitto mosquitto-clients

# Create user Automata with password Inverted2
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2

# Backup the original mosquitto config file
sudo cp /etc/mosquitto/mosquitto.conf /etc/mosquitto/mosquitto.conf.bak

# Add listener and authentication settings to the configuration file
echo "listener 1883" | sudo tee -a /etc/mosquitto/mosquitto.conf
echo "allow_anonymous false" | sudo tee -a /etc/mosquitto/mosquitto.conf
echo "password_file /etc/mosquitto/passwd" | sudo tee -a /etc/mosquitto/mosquitto.conf

# Configure per-listener settings
echo "per_listener_settings true" | sudo tee -a /etc/mosquitto/mosquitto.conf

# Enable Mosquitto as a service and restart it
sudo systemctl enable mosquitto
sudo systemctl restart mosquitto

# Output status to verify Mosquitto is running
sudo systemctl status mosquitto

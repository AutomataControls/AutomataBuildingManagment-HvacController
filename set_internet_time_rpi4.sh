#!/bin/bash

# Update package lists
sudo apt-get update

# Install NTP if not installed
sudo apt-get install -y ntp

# Sync time with NTP servers
sudo systemctl enable ntp
sudo systemctl start ntp

# Force an immediate sync with the internet time server
sudo ntpd -gq

# Display the updated date and time
echo "The system time has been synchronized to the local internet time:"
date

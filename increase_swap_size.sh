#!/bin/bash

# Check current swap size
echo "Current swap size:"
sudo swapon --show

# Disable current swap
sudo swapoff -a

# Modify the swap file size to 2048 MB
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile

# Restart swap service
sudo systemctl restart dphys-swapfile

# Re-enable swap and check the new swap size
sudo swapon -a
echo "New swap size:"
sudo swapon --show

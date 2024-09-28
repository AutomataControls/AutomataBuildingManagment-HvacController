#!/bin/bash

# Check current swap size
echo "Current swap size:"
sudo swapon --show

# Disable current swap
echo "Disabling current swap..."
sudo swapoff -a

# Modify the swap file size to 2048 MB
echo "Setting swap file size to 2048 MB..."
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile

# Restart swap service
echo "Restarting swap service..."
if sudo systemctl restart dphys-swapfile; then
    echo "Swap service restarted successfully."
else
    echo "Failed to restart swap service."
    exit 1
fi

# Re-enable swap and check the new swap size
echo "Re-enabling swap..."
sudo swapon -a
echo "New swap size:"
sudo swapon --show

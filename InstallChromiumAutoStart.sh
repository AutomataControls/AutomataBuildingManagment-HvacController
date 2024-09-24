#!/bin/bash

# Update and install necessary packages
sudo apt update
sudo apt install -y chromium-browser

# Create the script to launch Chromium after network connection
cat << 'EOF' > /home/Automata/launch_chromium.sh
#!/bin/bash

# Wait for the network to be connected
while ! ping -c 1 127.0.0.1 &>/dev/null; do
    sleep 1
done

# Wait for an additional 10 seconds after network connection
sleep 10

# Launch Chromium with two tabs
chromium-browser http://127.0.0.1:1880/ http://127.0.0.1:1880/ui
EOF

# Make the script executable
chmod +x /home/Automata/launch_chromium.sh

# Add the script to autostart for the current user
AUTOSTART_FILE="/home/Automata/.config/lxsession/LXDE-pi/autostart"

# Ensure the autostart directory exists
mkdir -p $(dirname "$AUTOSTART_FILE")

# Add the launch script to autostart
if ! grep -q 'launch_chromium.sh' "$AUTOSTART_FILE"; then
    echo "@/home/Automata/launch_chromium.sh" >> "$AUTOSTART_FILE"
fi

echo "Chromium launch script has been added to autostart."

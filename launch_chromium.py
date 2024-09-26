#!/bin/bash

# Create launch_chromium.py script
cat << 'EOF' > /home/Automata/AutomataBuildingManagment-HvacController/launch_chromium.py
import time
import subprocess
import os

# Function to launch Chromium
def launch_chromium():
    # Check for network availability
    while True:
        try:
            subprocess.check_call(['ping', '-c', '1', '127.0.0.1'])
            break
        except subprocess.CalledProcessError:
            time.sleep(1)

    # Wait for services to fully load
    time.sleep(15)

    # Launch Chromium in normal windowed mode, opening the two Node-RED pages
    subprocess.Popen([
        'chromium-browser', 
        '--new-window', 
        'http://127.0.0.1:1880', 
        'http://127.0.0.1:1880/ui'
    ])

# Execute the function
if __name__ == '__main__':
    launch_chromium()
EOF

# Make sure to move the script and set permissions after it's created
mv /home/Automata/AutomataBuildingManagment-HvacController/launch_chromium.py /home/Automata/launch_chromium.py
chmod +x /home/Automata/launch_chromium.py

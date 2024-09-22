#!/bin/bash

# Function to run updates and handle errors
run_update() {
    cd "$1/update" || { echo "Update folder not found for $1, skipping..."; return; }
    sudo ./update 0 || { echo "Update failed for $1, continuing..."; }
    cd /home/Automata || cd /Automata/pi
}

# Clone and install megabas-rpi
git clone https://github.com/SequentMicrosystems/megabas-rpi.git
cd /home/Automata/megabas-rpi
sudo make install
run_update "/home/Automata/megabas-rpi"

# Clone and install megaind-rpi
git clone https://github.com/SequentMicrosystems/megaind-rpi.git
cd /home/Automata/megaind-rpi
sudo make install
run_update "/home/Automata/megaind-rpi"

# Clone and install 16univin-rpi
git clone https://github.com/SequentMicrosystems/16univin-rpi.git
cd /Automata/pi/16univin-rpi
sudo make install
run_update "/Automata/pi/16univin-rpi"

# Clone and install 16relind-rpi
git clone https://github.com/SequentMicrosystems/16relind-rpi.git
cd /home/Automata/16relind-rpi
sudo make install
run_update "/home/Automata/16relind-rpi"

# Clone and install 8relind-rpi
git clone https://github.com/SequentMicrosystems/8relind-rpi.git
cd /home/Automata/8relind-rpi
sudo make install
run_update "/home/Automata/8relind-rpi"

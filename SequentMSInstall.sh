#!/bin/bash

# Step 1: Install Sequent Microsystems repositories and compile them
echo "Installing Sequent Microsystems drivers..."

# Clone and install megabas-rpi
git clone https://github.com/SequentMicrosystems/megabas-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
cd /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
sudo make install || { echo "megabas-rpi installation failed"; exit 1; }

# Clone and install megaind-rpi
git clone https://github.com/SequentMicrosystems/megaind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
cd /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
sudo make install || { echo "megaind-rpi installation failed"; exit 1; }

# Clone and install 16univin-rpi
git clone https://github.com/SequentMicrosystems/16univin-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi
cd /home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi
sudo make install || { echo "16univin-rpi installation failed"; exit 1; }

# Clone and install 16relind-rpi
git clone https://github.com/SequentMicrosystems/16relind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi
cd /home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi
sudo make install || { echo "16relind-rpi installation failed"; exit 1; }

# Clone and install 8relind-rpi
git clone https://github.com/SequentMicrosystems/8relind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi
cd /home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi
sudo make install || { echo "8relind-rpi installation failed"; exit 1; }

echo "Sequent Microsystems drivers installation completed."

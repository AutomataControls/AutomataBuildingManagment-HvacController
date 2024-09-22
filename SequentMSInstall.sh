#!/bin/bash

# Clone and install megabas-rpi
git clone https://github.com/SequentMicrosystems/megabas-rpi.git
cd /home/Automata/megabas-rpi
sudo make install

# Clone and install megaind-rpi
git clone https://github.com/SequentMicrosystems/megaind-rpi.git
cd /home/Automata/megaind-rpi
sudo make install

# Clone and install 16univin-rpi
git clone https://github.com/SequentMicrosystems/16univin-rpi.git
cd /Automata/pi/16univin-rpi
sudo make install

# Clone and install 16relind-rpi
git clone https://github.com/SequentMicrosystems/16relind-rpi.git
cd /home/Automata/16relind-rpi
sudo make install

# Clone and install 8relind-rpi
git clone https://github.com/SequentMicrosystems/8relind-rpi.git
cd /home/Automata/8relind-rpi
sudo make install

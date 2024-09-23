#!/bin/bash

# Path to store the current step
STEP_FILE="/home/Automata/install_step"

# Function to run updates and handle errors
run_update() {
    cd "$1/update" || { echo "Update folder not found for $1, skipping..."; return; }
    sudo ./update 0 || { echo "Update failed for $1, continuing..."; }
    cd /home/Automata || cd /Automata/pi
}

# Function to save the current step
save_step() {
    echo "$1" > "$STEP_FILE"
}

# Function to read the current step
read_step() {
    if [ -f "$STEP_FILE" ]; then
        cat "$STEP_FILE"
    else
        echo 0
    fi
}

# Main installation and update process
install_packages() {
    local step=$(read_step)

    if [ "$step" -le 1 ]; then
        # Phase 1: Make Install Steps

        # Step 1: Clone and install megabas-rpi
        git clone https://github.com/SequentMicrosystems/megabas-rpi.git
        cd /home/Automata/megabas-rpi
        sudo make install
        save_step 2

        # Step 2: Clone and install megaind-rpi
        git clone https://github.com/SequentMicrosystems/megaind-rpi.git
        cd /home/Automata/megaind-rpi
        sudo make install
        save_step 3

        # Step 3: Clone and install 16univin-rpi
        git clone https://github.com/SequentMicrosystems/16univin-rpi.git
        cd /Automata/pi/16univin-rpi
        sudo make install
        save_step 4

        # Step 4: Clone and install 16relind-rpi
        git clone https://github.com/SequentMicrosystems/16relind-rpi.git
        cd /home/Automata/16relind-rpi
        sudo make install
        save_step 5

        # Step 5: Clone and install 8relind-rpi
        git clone https://github.com/SequentMicrosystems/8relind-rpi.git
        cd /home/Automata/8relind-rpi
        sudo make install
        save_step 6

        # Reboot after all installations are complete
        sudo reboot
    fi

    if [ "$step" -le 6 ]; then
        # Phase 2: Update Steps

        # Step 6: Run updates after reboot
        run_update "/home/Automata/megabas-rpi"
        save_step 7

        # Step 7: Run update for megaind-rpi
        run_update "/home/Automata/megaind-rpi"
        save_step 8

        # Step 8: Run update for 16univin-rpi
        run_update "/Automata/pi/16univin-rpi"
        save_step 9

        # Step 9: Run update for 16relind-rpi
        run_update "/home/Automata/16relind-rpi"
        save_step 10

        # Step 10: Run update for 8relind-rpi
        run_update "/home/Automata/8relind-rpi"
        save_step 11

        # Final Reboot after all updates are complete
        sudo reboot
    fi

    # All steps completed, remove step file
    if [ "$step" -ge 11 ]; then
        rm -f "$STEP_FILE"
        echo "All installations and updates completed!"
    fi
}

install_packages

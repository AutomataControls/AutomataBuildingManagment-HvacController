#!/bin/bash

# Step 1: Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Re-running with sudo..."
    sudo bash "$0" "$@"
    exit
fi

# Step 2: Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

# Step 3: Install required dependencies for Tkinter and Pillow
echo "Installing Tkinter and Pillow..."
sudo apt-get update
sudo apt-get install -y python3-tk python3-pil python3-pil.imagetk

# Step 4: Create a Python script for the Tkinter GUI welcome dialog
WELCOME_SCRIPT="/home/Automata/welcome_install_gui.py"

cat << 'EOF' > $WELCOME_SCRIPT
import tkinter as tk
from tkinter import messagebox

# Create the main window
root = tk.Tk()
root.title("Automata Installation")

# Set window size and position
root.geometry("500x300")
root.configure(bg='#2e2e2e')  # Dark grey background

# Welcome message
label = tk.Label(root, text="Welcome to Automata Installation", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Instructions message
instructions = tk.Label(root, text="This process will take approximately 5-15 minutes.\nHuman interaction will be necessary to complete.\n\nDo you want to continue?", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
instructions.pack(pady=10)

# User response handling
def on_continue():
    root.destroy()
    exit(0)

def on_exit():
    messagebox.showinfo("Installation Aborted", "The installation has been aborted.")
    root.destroy()
    exit(1)

# Continue and Exit buttons
button_frame = tk.Frame(root, bg='#2e2e2e')
button_frame.pack(pady=20)

continue_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=on_continue, bg='#00b3b3', fg="black", width=10)
continue_button.grid(row=0, column=0, padx=10)

exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=on_exit, bg='orange', fg="black", width=10)
exit_button.grid(row=0, column=1, padx=10)

# Start the Tkinter main loop
root.mainloop()
EOF

# Step 5: Run the Tkinter GUI welcome dialog
python3 $WELCOME_SCRIPT

# If the user chose to exit, the script will stop here
if [ $? -ne 0 ]; then
    echo "Installation aborted by the user."
    exit 1
fi

# Step 6: Ensure the DISPLAY environment variable is set
export DISPLAY=:0

# Step 7: Stop services if running
echo "Stopping and disabling conflicting services..."
if systemctl is-active --quiet nodered; then
    sudo systemctl stop nodered
fi
if systemctl is-active --quiet mosquitto; then
    sudo systemctl stop mosquitto
fi
if systemctl is-enabled --quiet nodered; then
    sudo systemctl disable nodered
fi
if systemctl is-enabled --quiet mosquitto; then
    sudo systemctl disable mosquitto
fi
sudo rm -f /etc/mosquitto/passwd || echo "No previous Mosquitto password file to remove"

# Step 8: Set executable permissions for all scripts in the repository
echo "Setting executable permissions for all scripts..."
sudo chmod -R +x /home/Automata/AutomataBuildingManagment-HvacController/*.sh

# Step 9: Move FullLogo.png from the repository to the home directory
LOGO_SRC="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"
LOGO_DEST="/home/Automata/FullLogo.png"

if [ -f "$LOGO_SRC" ]; then
    echo "Moving FullLogo.png to home directory..."
    sudo mv "$LOGO_SRC" "$LOGO_DEST"
else
    echo "Error: $LOGO_SRC not found."
fi

# Step 10: Set FullLogo.png as desktop wallpaper and splash screen
if [ -f "$LOGO_DEST" ]; then
    echo "Setting logo as wallpaper and splash screen..."
    sudo -u Automata DISPLAY=:0 pcmanfm --set-wallpaper="$LOGO_DEST" || echo "Warning: Could not set wallpaper."
    sudo cp "$LOGO_DEST" /usr/share/plymouth/themes/pix/splash.png
else
    echo "Error: $LOGO_DEST not found."
fi

# Step 11: Enable I2C, SPI, RealVNC, 1-Wire, Remote GPIO, and disable serial port
echo "Enabling I2C, SPI, RealVNC, 1-Wire, Remote GPIO, and disabling serial port..."
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_vnc 0
sudo raspi-config nonint do_onewire 0
sudo raspi-config nonint do_rgpio 0
sudo raspi-config nonint do_serial 1

# Step 12: Install Mosquitto but do not start the service until after reboot
echo "Installing Mosquitto..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y mosquitto mosquitto-clients
sudo touch /etc/mosquitto/passwd
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2
echo "listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
per_listener_settings true" | sudo tee /etc/mosquitto/mosquitto.conf

# Step 13: Node-RED installation using your custom script
echo "Installing Node-RED..."
bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh

# Step 14: Install Sequent Boards (Moved before auto-start script)
echo "Installing Sequent Boards..."
BOARDS=(
    "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update"
)

for board in "${BOARDS[@]}"; do
    if [ -d "$board" ]; then
        echo "Updating board in $board"
        (cd "$board" && ./update 0)
    else
        echo "Board directory $board not found."
    fi
done

# Step 15: Run InstallNodeRedPallete.sh to install Node-RED nodes and themes
echo "Running InstallNodeRedPallete.sh to install Node-RED nodes and themes..."
bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh

# Step 16: Add Chromium auto-start using InstallChromiumAutoStart.sh (no loop)
echo "Running InstallChromiumAutoStart.sh to add Chromium auto-start..."
bash /home/Automata/AutomataBuildingManagment-HvacController/InstallChromiumAutoStart.sh

# Step 17: Increase swap size (Moved to just before reboot)
echo "Increasing swap size..."
run_script "increase_swap_size.sh"

# Step 18: Create one-time autostart entry for board updates
AUTOSTART_FILE="/home/Automata/.config/lxsession/LXDE-pi/autostart"
if [ ! -d "/home/Automata/.config/lxsession/LXDE-pi" ]; then
    echo "Creating autostart directory..."
    mkdir -p "/home/Automata/.config/lxsession/LXDE-pi"
fi

# Remove old entries and add the new one
if grep -q 'update_sequent_boards.sh' "$AUTOSTART_FILE"; then
    sed -i '/update_sequent_boards.sh/d' "$AUTOSTART_FILE"
fi

cat << 'EOF' > /home/Automata/update_sequent_boards.sh
#!/bin/bash
BOARDS=(
    "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update"
)

for board in "${BOARDS[@]}"; do
    if [ -d "$board" ]; then
        echo "Updating board in $board"
        (cd "$board" && ./update 0)
    else
        echo "Board directory $board not found."
    fi
done
EOF

chmod +x /home/Automata/update_sequent_boards.sh
echo "@/home/Automata/update_sequent_boards.sh" >> "$AUTOSTART_FILE"

# Step 19: Create another Tkinter GUI for final message and reboot confirmation
FINAL_MESSAGE_SCRIPT="/home/Automata/final_message_gui.py"

cat << 'EOF' > $FINAL_MESSAGE_SCRIPT
import tkinter as tk
from tkinter import messagebox

# Create the main window
root = tk.Tk()
root.title("Installation Complete")

# Set window size and position
root.geometry("500x300")
root.configure(bg='#2e2e2e')  # Dark grey background

# Final message
label = tk.Label(root, text="Automata Building Management & Hvac Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

instructions = tk.Label(root, text="A New Realm of Automation Awaits!\nPlease Reboot to Finalize Settings and Config Files.\n\nReboot Now?", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
instructions.pack(pady=10)

# User response handling
def on_reboot():
    root.destroy()
    exit(0)

def on_later():
    messagebox.showinfo("Reboot Later", "You can reboot the system manually later.")
    root.destroy()
    exit(1)

# Reboot and Later buttons
button_frame = tk.Frame(root, bg='#2e2e2e')
button_frame.pack(pady=20)

reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=on_reboot, bg='#00b3b3', fg="black", width=10)
reboot_button.grid(row=0, column=0, padx=10)

later_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=on_later, bg='orange', fg="black", width=10)
later_button.grid(row=0, column=1, padx=10)

# Start the Tkinter main loop
root.mainloop()
EOF

# Run the final Tkinter GUI
python3 $FINAL_MESSAGE_SCRIPT

# Step 20: Handle Reboot Based on User Input
if [ $? = 0 ]; then
    echo "Rebooting system..."
    sudo reboot
else
    echo "Installation completed without reboot. Please reboot manually."
fi


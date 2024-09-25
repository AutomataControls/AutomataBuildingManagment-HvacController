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

# Step 4: Create a Python script for the Tkinter GUI with progress bar
INSTALL_GUI="/home/Automata/install_progress_gui.py"

cat << 'EOF' > $INSTALL_GUI
import tkinter as tk
from tkinter import ttk

# Create the main window
root = tk.Tk()
root.title("Automata Installation")

# Set window size and position
root.geometry("600x400")
root.configure(bg='#2e2e2e')  # Dark grey background

# Title message
label = tk.Label(root, text="Automata Installation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting installation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Update progress function
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Tkinter loop runs in the background while install runs
root.mainloop()
EOF

# Step 5: Start the Tkinter GUI in the background
python3 $INSTALL_GUI &
GUI_PID=$!

# Function to update the GUI
update_gui() {
    STEP=$1
    TOTAL=$2
    MESSAGE=$3
    python3 -c "
import tkinter as tk
from tkinter import ttk
root = tk.Tk()
root.update_idletasks()
progress = ttk.Progressbar(root, orient='horizontal', length=500, mode='determinate')
progress['value'] = ($STEP / $TOTAL) * 100
root.update_idletasks()
status_label = tk.Label(root, text='$MESSAGE')
status_label.config(text='$MESSAGE')
root.update_idletasks()
" 2>/dev/null
    echo "$MESSAGE"
    sleep 2  # Allow time for the UI to update
}

# Total steps for installation (estimate)
TOTAL_STEPS=10

# Step 6: Install Sequent Microsystems drivers (Progress: 1/10)
update_gui 1 $TOTAL_STEPS "Installing Sequent Microsystems drivers..."
echo "Installing Sequent Microsystems drivers..."

# Clone and install megabas-rpi
git clone https://github.com/SequentMicrosystems/megabas-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
cd /home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi
sudo make install || { echo "megabas-rpi installation failed"; exit 1; }

# Clone and install megaind-rpi
git clone https://github.com/SequentMicrosystems/megaind-rpi.git /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
cd /home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi
sudo make install || { echo "megaind-rpi installation failed"; exit 1; }

# Step 7: Install Node-RED and Node-RED Palettes (Progress: 2/10)
update_gui 2 $TOTAL_STEPS "Installing Node-RED and palettes..."
echo "Installing Node-RED and palettes..."

# Install Node-RED and required nodes
bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh
bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh

# Step 8: Set up Chromium auto-start (Progress: 3/10)
update_gui 3 $TOTAL_STEPS "Setting up Chromium auto-start..."
echo "Setting up Chromium auto-start..."

# Add Chromium auto-start
bash /home/Automata/AutomataBuildingManagment-HvacController/InstallChromiumAutoStart.sh

# Step 9: Move FullLogo.png and set it as wallpaper and splash screen (Progress: 4/10)
update_gui 4 $TOTAL_STEPS "Setting up logo as wallpaper and splash screen..."
echo "Setting up logo as wallpaper and splash screen..."

LOGO_SRC="/home/Automata/AutomataBuildingManagment-HvacController/FullLogo.png"
LOGO_DEST="/home/Automata/FullLogo.png"

if [ -f "$LOGO_SRC" ]; then
    sudo mv "$LOGO_SRC" "$LOGO_DEST"
    sudo -u Automata DISPLAY=:0 pcmanfm --set-wallpaper="$LOGO_DEST"
    sudo cp "$LOGO_DEST" /usr/share/plymouth/themes/pix/splash.png
else
    echo "Error: FullLogo.png not found."
fi

# Step 10: Enable I2C, SPI, RealVNC, 1-Wire, and disable serial port (Progress: 5/10)
update_gui 5 $TOTAL_STEPS "Enabling I2C, SPI, RealVNC, 1-Wire, disabling serial port..."
echo "Enabling I2C, SPI, RealVNC, 1-Wire, disabling serial port..."

sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_vnc 0
sudo raspi-config nonint do_onewire 0
sudo raspi-config nonint do_serial 1

# Step 11: Install Mosquitto (Progress: 6/10)
update_gui 6 $TOTAL_STEPS "Installing Mosquitto..."
echo "Installing Mosquitto..."

sudo apt-get install -y mosquitto mosquitto-clients
sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2

# Step 12: Increase swap size (Progress: 7/10)
update_gui 7 $TOTAL_STEPS "Increasing swap size..."
echo "Increasing swap size..."
bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh

# Step 13: Add board update to autostart (Progress: 8/10)
update_gui 8 $TOTAL_STEPS "Adding board updates to autostart..."
echo "Adding board updates to autostart..."

AUTOSTART_FILE="/home/Automata/.config/lxsession/LXDE-pi/autostart"
mkdir -p /home/Automata/.config/lxsession/LXDE-pi

cat << 'EOF2' > /home/Automata/update_sequent_boards.sh
#!/bin/bash
BOARDS=(
    "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update"
    "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update"
)
for board in "${BOARDS[@]}"; do
    if [ -d "$board" ]; then
        (cd "$board" && ./update 0)
    else
        echo "Board directory $board not found."
    fi
done
EOF2

chmod +x /home/Automata/update_sequent_boards.sh
echo "@/home/Automata/update_sequent_boards.sh" >> "$AUTOSTART_FILE"

# Step 14: Final step - Installation complete (Progress: 9/10)
update_gui 9 $TOTAL_STEPS "Installation complete. Please reboot."
echo "Installation complete. Please reboot."

# Step 15: Final Message for Reboot in a Tkinter GUI

FINAL_MESSAGE_GUI="/home/Automata/final_message_gui.py"

cat << 'EOF3' > $FINAL_MESSAGE_GUI
import tkinter as tk

def on_reboot():
    import os
    os.system('sudo reboot')

def on_exit():
    root.destroy()

# Create the main window
root = tk.Tk()
root.title("Installation Complete")

# Set window size and position
root.geometry("600x400")
root.configure(bg='#2e2e2e')  # Dark grey background

# Final message
label = tk.Label(root, text="Automata Building Management & HVAC Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

message = tk.Label(root, text="A New Realm of Automation Awaits!\nPlease reboot to finalize settings and config files.\n\nReboot Now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
message.pack(pady=20)

# Reboot and Later buttons
button_frame = tk.Frame(root, bg='#2e2e2e')
button_frame.pack(pady=20)

reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=on_reboot, bg='#00b3b3', fg="black", width=10)
reboot_button.grid(row=0, column=0, padx=10)

exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=on_exit, bg='orange', fg="black", width=10)
exit_button.grid(row=0, column=1, padx=10)

# Start the Tkinter main loop
root.mainloop()
EOF3

# Step 16: Start the final message GUI
python3 $FINAL_MESSAGE_GUI

# Step 17: Close the progress GUI after completion
kill $GUI_PID
echo "Installation complete. Exiting."

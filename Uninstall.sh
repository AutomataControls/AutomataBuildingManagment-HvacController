#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Function to handle errors
handle_error() {
    log "Error occurred in line $1"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Step 1: Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Re-running with sudo..."
    sudo bash "$0" "$@"
    exit
fi

# Step 2: Log file setup
LOGFILE="/home/Automata/uninstall_log.txt"
log "Uninstallation started"

# Step 3: Create Python GUI for uninstallation progress
log "Creating uninstallation GUI script..."
UNINSTALL_GUI="/home/Automata/uninstall_progress_gui.py"

cat << 'EOF' > $UNINSTALL_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os

# Create the main window
root = tk.Tk()
root.title("Automata Uninstallation Progress")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

label = tk.Label(root, text="Automata Uninstallation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

status_label = tk.Label(root, text="Starting uninstallation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        print(f"Error output: {result.stderr}")
        root.update_idletasks()
    else:
        print(f"Command output: {result.stdout}")

def run_uninstallation_steps():
    total_steps = 9
    
    # Stop Mosquitto
    run_shell_command("sudo systemctl stop mosquitto && sudo systemctl disable mosquitto && sudo apt-get remove --purge -y mosquitto mosquitto-clients", 1, total_steps, "Removing Mosquitto services...")
    run_shell_command("sudo rm -f /etc/mosquitto/passwd && sudo rm -f /etc/mosquitto/mosquitto.conf", 2, total_steps, "Cleaning Mosquitto credentials...")
    
    # Restore default swap size
    run_shell_command("sudo dphys-swapfile swapoff && sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=100/' /etc/dphys-swapfile && sudo dphys-swapfile setup && sudo dphys-swapfile swapon", 3, total_steps, "Restoring default swap size...")

    # Remove Node-RED
    run_shell_command("sudo systemctl stop nodered && sudo systemctl disable nodered && sudo apt-get remove --purge -y nodered", 4, total_steps, "Removing Node-RED...")

    # Remove Sequent Microsystems drivers
    drivers = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi"
    ]
    for step, driver in enumerate(drivers, start=5):
        if os.path.isdir(driver):
            run_shell_command(f"cd {driver} && sudo make uninstall", step, total_steps, f"Removing {driver} driver...")

    # Disable interfaces: I2C, SPI, VNC, etc.
    run_shell_command("sudo raspi-config nonint do_i2c 1 && sudo raspi-config nonint do_spi 1 && sudo raspi-config nonint do_vnc 1 && sudo raspi-config nonint do_onewire 1 && sudo raspi-config nonint do_serial 0", 8, total_steps, "Disabling I2C, SPI, VNC, etc...")

    # Remove repository directory
    run_shell_command("sudo rm -rf /home/Automata/AutomataBuildingManagment-HvacController", 9, total_steps, "Removing repository directory...")

    show_uninstall_complete_message()

def show_uninstall_complete_message():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Uninstallation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata BMS Uninstallation Complete", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="Uninstallation Successful.\nWould you like to reboot the system now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    final_message.pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

threading.Thread(target=run_uninstallation_steps, daemon=True).start()
root.mainloop()
EOF

# Ensure that the GUI script has execute permissions
chmod +x $UNINSTALL_GUI

# Step 4: Run the uninstallation GUI
log "Running uninstallation GUI..."
sudo -u Automata DISPLAY=:0 python3 $UNINSTALL_GUI &

# Step 5: Permissions cleanup and file removal
log "Removing permissions for repository files..."

# Remove permissions for /home/Automata directory
find /home/Automata -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod -x {} \;
find /home/Automata -type f -name "*.png" -exec chmod -r {} \;

# Remove repository directory
log "Uninstallation completed."


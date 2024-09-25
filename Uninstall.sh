#!/bin/bash

# Log file setup
LOGFILE="/home/Automata/uninstall_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Uninstallation started at: $(date)"

# Step 1: Create a Python script for the uninstallation progress GUI
UNINSTALL_GUI="/home/Automata/uninstall_progress_gui.py"

cat << 'EOF' > $UNINSTALL_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading

# Create the main window
root = tk.Tk()
root.title("Automata Uninstallation Progress")

# Set window size and position
root.geometry("600x400")
root.configure(bg='#2e2e2e')  # Dark grey background

# Title message
label = tk.Label(root, text="Automata Uninstallation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting uninstallation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Update progress function
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Function to run shell commands in a separate thread
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    result = subprocess.Popen(command, shell=True).wait()
    if result != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        root.update_idletasks()

def run_uninstallation_steps():
    total_steps = 10  # Total steps in uninstallation

    # Step 1: Stop Node-RED and related services
    run_shell_command("sudo systemctl stop nodered.service && sudo systemctl disable nodered.service", 1, total_steps, "Stopping Node-RED service...")
    run_shell_command("node-red-stop", 1, total_steps, "Ensuring Node-RED runtime is stopped...")
    
    run_shell_command("sudo systemctl stop mosquitto.service && sudo systemctl disable mosquitto.service", 1, total_steps, "Stopping Mosquitto service...")
    update_progress(1, total_steps, "Stopped Node-RED and Mosquitto services.")

    # Step 2: Restore swap size
    run_shell_command("sudo dphys-swapfile swapoff && sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=100/' /etc/dphys-swapfile && sudo dphys-swapfile setup && sudo dphys-swapfile swapon", 2, total_steps, "Restoring default swap size...")

    # Step 3: Remove Node-RED
    run_shell_command("sudo apt-get remove --purge -y nodered && sudo rm -rf /home/Automata/.node-red", 3, total_steps, "Removing Node-RED...")

    # Step 4: Remove Mosquitto
    run_shell_command("sudo apt-get remove --purge -y mosquitto mosquitto-clients && sudo rm -f /etc/mosquitto/passwd && sudo rm -f /etc/mosquitto/mosquitto.conf", 4, total_steps, "Removing Mosquitto...")

    # Step 5: Remove Sequent Microsystems drivers
    DRIVER_PATHS = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi"
    ]
    step = 5
    for driver in DRIVER_PATHS:
        if os.path.isdir(driver):
            run_shell_command(f"cd {driver} && sudo make uninstall", step, total_steps, f"Removing driver from {driver}...")
        else:
            update_progress(step, total_steps, f"Driver path {driver} not found.")
        step += 1

    # Step 6: Disable I2C, SPI, VNC, 1-Wire, and SSH
    run_shell_command("sudo raspi-config nonint do_i2c 1 && sudo raspi-config nonint do_spi 1 && sudo raspi-config nonint do_vnc 1 && sudo raspi-config nonint do_onewire 1 && sudo raspi-config nonint do_ssh 1 && sudo raspi-config nonint do_serial 0", step, total_steps, "Disabling I2C, SPI, VNC, 1-Wire, and SSH...")

    # Step 7: Remove auto-start entries and desktop files
    run_shell_command("sudo sed -i '/update_sequent_boards.sh/d' /home/Automata/.config/lxsession/LXDE-pi/autostart && sudo sed -i '/launch_chromium_permanent.sh/d' /home/Automata/.config/lxsession/LXDE-pi/autostart", step, total_steps, "Removing auto-start entries...")

    run_shell_command("rm -f /home/Automata/Desktop/NodeRed.desktop", step, total_steps, "Removing Node-RED desktop entry...")

    # Step 8: Remove repository
    run_shell_command("sudo rm -rf /home/Automata/AutomataBuildingManagment-HvacController", step, total_steps, "Removing repository files...")

    # Step 9: Completion
    update_progress(total_steps, total_steps, "Uninstallation complete. Please reboot.")
    show_reboot_prompt()

# Function to show reboot prompt
def show_reboot_prompt():
    root.withdraw()  # Hide the main window
    reboot_window = tk.Tk()
    reboot_window.title("Uninstallation Complete")
    reboot_window.geometry("600x400")
    reboot_window.configure(bg='#2e2e2e')

    message = tk.Label(reboot_window, text="Uninstallation is complete. Would you like to reboot now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    message.pack(pady=20)

    button_frame = tk.Frame(reboot_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: subprocess.Popen('sudo reboot', shell=True), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=reboot_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    reboot_window.mainloop()

# Start the uninstallation steps in a separate thread to keep GUI responsive
threading.Thread(target=run_uninstallation_steps).start()

# Tkinter loop runs in the background while uninstallation progresses
root.mainloop()
EOF

# Step 2: Start the uninstallation GUI
python3 $UNINSTALL_GUI


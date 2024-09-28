#!/usr/bin/env python3

import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os

# Create the main window
root = tk.Tk()
root.title("Automata Uninstallation Progress")

# Set window size and position
root.geometry("600x400")
root.configure(bg='#2e2e2e')

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
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        print(f"Command output: {result.stdout}")
    except subprocess.CalledProcessError as e:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        print(f"Error output: {e.stderr}")
    root.update_idletasks()

def run_uninstallation_steps():
    total_steps = 7

    # Step 1: Stop and remove Mosquitto service and user credentials
    run_shell_command("sudo systemctl stop mosquitto && sudo systemctl disable mosquitto && sudo apt-get remove --purge -y mosquitto mosquitto-clients && sudo rm -f /etc/mosquitto/passwd && sudo rm -f /etc/mosquitto/mosquitto.conf", 1, total_steps, "Removing Mosquitto...")

    # Step 2: Restore the default swap size
    run_shell_command("sudo dphys-swapfile swapoff && sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=100/' /etc/dphys-swapfile && sudo dphys-swapfile setup && sudo dphys-swapfile swapon", 2, total_steps, "Restoring default swap size...")

    # Step 3: Remove Node-RED and related services
    run_shell_command("sudo systemctl stop nodered && sudo systemctl disable nodered && sudo apt-get remove --purge -y nodered", 3, total_steps, "Removing Node-RED...")

    # Step 4: Remove Sequent Microsystems drivers
    drivers = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi"
    ]
    for step, driver in enumerate(drivers, start=4):
        if os.path.isdir(driver):  # Check if directory exists
            run_shell_command(f"cd {driver} && sudo make uninstall", step, total_steps, f"Removing {driver} driver...")

    # Step 5: Disable I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH
    run_shell_command("sudo raspi-config nonint do_i2c 1 && sudo raspi-config nonint do_spi 1 && sudo raspi-config nonint do_vnc 1 && sudo raspi-config nonint do_onewire 1 && sudo raspi-config nonint do_rgpio 1 && sudo raspi-config nonint do_ssh 1 && sudo raspi-config nonint do_serial 0", 5, total_steps, "Disabling interfaces and enabling serial port...")

    # Step 6: Remove Node-RED desktop icon
    run_shell_command("rm -f /home/Automata/Desktop/NodeRed.desktop", 6, total_steps, "Removing Node-RED desktop icon...")

    # Step 7: Remove the cloned repository directory
    run_shell_command("sudo rm -rf /home/Automata/AutomataBuildingManagment-HvacController", 7, total_steps, "Removing repository directory...")

    # Show final message after uninstallation
    show_uninstall_complete_message()

# Function to show final uninstallation message and reboot prompt
def show_uninstall_complete_message():
    root.withdraw()  # Hide the main window
    final_window = tk.Tk()
    final_window.title("Uninstallation Complete")
    final_window.geometry("400x200")
    final_window.configure(bg='#2e2e2e')

    message = tk.Label(final_window, text="Uninstallation completed successfully!\nDo you want to reboot now?", font=("Helvetica", 12), fg="#00b3b3", bg="#2e2e2e")
    message.pack(pady=20)

    def reboot():
        os.system("sudo reboot")

    def close():
        final_window.destroy()
        root.destroy()

    reboot_button = tk.Button(final_window, text="Reboot", command=reboot, bg="#008080", fg="white")
    reboot_button.pack(side=tk.LEFT, padx=20)

    close_button = tk.Button(final_window, text="Close", command=close, bg="#008080", fg="white")
    close_button.pack(side=tk.RIGHT, padx=20)

    final_window.mainloop()

# Start the uninstallation process
threading.Thread(target=run_uninstallation_steps, daemon=True).start()

# Start the GUI
root.mainloop()


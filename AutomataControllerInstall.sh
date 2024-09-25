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

# Step 3: Start the installation GUI before any installation steps
echo "Starting installation GUI..."
INSTALL_GUI="/home/Automata/install_progress_gui.py"

# Create the Python GUI script for installation progress
cat << 'EOF' > $INSTALL_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading

# Create the main window
root = tk.Tk()
root.title("Automata Installation Progress")

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

# Function to run shell commands in a separate thread
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    result = subprocess.Popen(command, shell=True).wait()
    if result != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        root.update_idletasks()

def run_installation_steps():
    total_steps = 11  # Updated step count

    # Step 1: Disable screen blanking
    run_shell_command("sudo raspi-config nonint do_blanking 1", 1, total_steps, "Disabling screen blanking...")
    sleep(5)

    # Step 2: Set Internet Time with Eastern Standard Time
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", 2, total_steps, "Setting system time to Eastern Standard Time...")
    sleep(5)

    # Step 3: Install Sequent Microsystems drivers
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh", 3, total_steps, "Installing Sequent Microsystems drivers...")
    sleep(5)

    # Step 4: Install Node-RED interactively with prompts
    run_shell_command("lxterminal -e 'bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh'", 4, total_steps, "Installing Node-RED interactively with prompts...")
    sleep(5)

    # Step 5: Install Node-RED palettes
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh", 5, total_steps, "Installing Node-RED palettes...")

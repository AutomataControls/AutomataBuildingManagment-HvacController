#!/bin/bash

# Step 1: Create the Python GUI script with progress bar and status updates
UPDATE_GUI="/home/Automata/update_progress_gui.py"

cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os

# Create the main window
root = tk.Tk()
root.title("Automata Board Updates")

# Set window size and position
root.geometry("600x400")
root.configure(bg='#2e2e2e')  # Dark grey background

# Title message
label = tk.Label(root, text="Automata Board Updates", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting updates...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Update progress function
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Function to run shell commands in a separate thread
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    subprocess.Popen(command, shell=True).wait()

def run_update_steps():
    total_steps = 6  # Total steps in the update process
    success = False  # Track if at least one board update succeeds

    # Step 1: Stop Node-RED services and Node-RED runtime
    update_progress(1, total_steps, "Stopping Node-RED services...")
    
    # Stop Node-RED system service if running
    if subprocess.run("systemctl list-units --full -all | grep -q 'nodered.service'", shell=True).returncode == 0:
        run_shell_command("sudo systemctl stop nodered.service && sudo systemctl disable nodered.service", 1, total_steps, "Stopping Node-RED system service...")

    # Run node-red-stop if available
    if subprocess.run("command -v node-red-stop", shell=True).returncode == 0:
        run_shell_command("node-red-stop", 2, total_steps, "Stopping Node-RED runtime...")

    # Step 2: Update Sequent boards
    boards = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update"
    ]
    step = 3
    for board in boards:
        if os.path.isdir(board):
            result = subprocess.run(f"cd {board} && ./update 0", shell=True)
            if result.returncode == 0:
                success = True  # Mark success if at least one update succeeds
                update_progress(step, total_steps, f"Successfully updated board in {board}")
            else:
                update_progress(step, total_steps, f"Failed to update board in {board}")
        else:
            update_progress(step, total_steps, f"Board directory {board} not found.")
        step += 1

    # Step 3: Show success message and reboot prompt
    if success:
        status_label.config(text="Updates completed successfully! Rebooting now...")
    else:
        status_label.config(text="No updates were applied. Rebooting now...")

    # Add a reboot prompt
    root.after(30000, lambda: subprocess.run("sudo reboot", shell=True))

# Run updates in a separate thread to keep GUI responsive
threading.Thread(target=run_update_steps).start()

# Tkinter loop runs in the background while updates are processed
root.mainloop()
EOF

# Step 2: Start the Tkinter GUI for the update process
python3 $UPDATE_GUI

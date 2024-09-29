#!/bin/bash

# Create Python GUI for board update progress
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
root.geometry("600x400")
root.configure(bg='#2e2e2e')

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

# Function to handle board updates
def run_update_steps():
    total_steps = 7  # Total steps in the update process
    success = False  # Track if at least one board update succeeds

    # Step 1: Stop Node-RED services
    update_progress(1, total_steps, "Stopping Node-RED services...")
    
    if subprocess.run("systemctl is-active --quiet nodered.service", shell=True).returncode == 0:
        run_shell_command("sudo systemctl stop nodered.service && sudo systemctl disable nodered.service", 1, total_steps, "Stopping Node-RED service...")
    else:
        update_progress(1, total_steps, "Node-RED service not found or already stopped.")

    # Step 2: Update Sequent Microsystems Boards
    boards = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update"
    ]
    step = 2
    for board in boards:
        if os.path.isdir(board):
            update_progress(step, total_steps, f"Updating board in {board}...")
            result = subprocess.run(f"cd {board} && ./update 0", shell=True)
            if result.returncode == 0:
                success = True  # Mark success if at least one update succeeds
                update_progress(step, total_steps, f"Successfully updated board in {board}")
            else:
                update_progress(step, total_steps, f"Failed to update board in {board}")
        else:
            update_progress(step, total_steps, f"Board directory {board} not found.")
        step += 1

    # Step 3: Handle success or failure
    if success:
        update_progress(total_steps, total_steps, "Updates completed successfully.")
    else:
        update_progress(total_steps, total_steps, "No updates were applied.")

    # Step 4: Re-enable services if needed
    update_progress(total_steps, total_steps, "Re-enabling Node-RED service...")
    subprocess.run("sudo systemctl enable nodered.service", shell=True)

    # Completion message
    root.after(5000, lambda: subprocess.run("sudo reboot", shell=True))

# Start the update process in a separate thread
threading.Thread(target=run_update_steps).start()

# Tkinter loop runs in the background while updates are processed
root.mainloop()
EOF

# Ensure the Python script has execute permissions
chmod +x $UPDATE_GUI

# Run the Python GUI script
python3 $UPDATE_GUI

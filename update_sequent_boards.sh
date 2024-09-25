#!/bin/bash

# Create Python GUI for board update progress
UPDATE_GUI="/home/Automata/update_progress_gui.py"
cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os

def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        print(f"Error during {message}: {result.stderr}")
    else:
        print(f"{message} completed successfully.")

def run_update_steps():
    total_steps = 7
    success = False

    # Step 1: Stopping Node-RED services
    update_progress(1, total_steps, "Stopping Node-RED services...")
    result = subprocess.run("systemctl is-active --quiet nodered.service", shell=True)
    if result.returncode == 0:
        run_shell_command("sudo systemctl stop nodered.service && sudo systemctl disable nodered.service", 1, total_steps, "Stopping Node-RED system service")
    else:
        print("Node-RED service is not active.")

    # Step 2-6: Board update process
    boards = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi",
        # Add other board directories as needed
    ]

    step = 2
    for board in boards:
        if os.path.isdir(board):
            update_progress(step, total_steps, f"Updating board at {board}...")
            result = subprocess.run(f"cd {board} && sudo ./update 0", shell=True, text=True, capture_output=True)
            if result.returncode == 0:
                success = True
                print(f"Successfully updated {board}")
            else:
                print(f"Failed to update {board}: {result.stderr}")
            step += 1
        else:
            print(f"Board directory {board} not found.")
            step += 1

    # Step 7: Enabling Chromium launch if successful
    if success:
        update_progress(total_steps, total_steps, "Board update succeeded. Enabling Chromium launch...")
        run_shell_command("sudo systemctl enable chromium-launch.service", total_steps, total_steps, "Enabling Chromium launch service")
    else:
        update_progress(total_steps, total_steps, "Board update failed.")
        print("No boards were updated successfully.")

    # Finish GUI
    status_label.config(text="Update process completed.")
    root.update_idletasks()

root = tk.Tk()
root.title("Automata Board Updates")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

label = tk.Label(root, text="Automata Board Updates", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

status_label = tk.Label(root, text="Starting updates...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

threading.Thread(target=run_update_steps).start()
root.mainloop()
EOF

# Ensure the Python script has execute permissions
chmod +x $UPDATE_GUI

# Run the Python GUI script
python3 $UPDATE_GUI



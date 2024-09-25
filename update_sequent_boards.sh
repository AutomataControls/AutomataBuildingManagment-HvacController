#!/bin/bash

# Step 1: Create the Python GUI script with progress bar and status updates
UPDATE_GUI="/home/Automata/update_progress_gui.py"

cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os

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

def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    subprocess.Popen(command, shell=True).wait()

def run_update_steps():
    total_steps = 6
    success = False

    update_progress(1, total_steps, "Stopping Node-RED services...")
    if subprocess.run("systemctl list-units --full -all | grep -q 'nodered.service'", shell=True).returncode == 0:
        run_shell_command("sudo systemctl stop nodered.service && sudo systemctl disable nodered.service", 1, total_steps, "Stopping Node-RED system service...")
    
    if subprocess.run("command -v node-red-stop", shell=True).returncode == 0:
        run_shell_command("node-red-stop", 2, total_steps, "Stopping Node-RED runtime...")

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
                success = True
                update_progress(step, total_steps, f"Successfully updated board in {board}")
            else:
                update_progress(step, total_steps, f"Failed to update board in {board}")
        else:
            update_progress(step, total_steps, f"Board directory {board} not found.")
        step += 1

    if success:
        status_label.config(text="Updates completed successfully!")
    else:
        status_label.config(text="No updates were applied.")
        
    root.after(30000, lambda: subprocess.run("sudo reboot", shell=True))

threading.Thread(target=run_update_steps).start()
root.mainloop()
EOF

# Step 2: Start the Tkinter GUI for the update process
python3 $UPDATE_GUI

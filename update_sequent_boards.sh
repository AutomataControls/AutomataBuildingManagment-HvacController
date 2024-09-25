#!/bin/bash

# Create Python GUI for board update progress
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
    total_steps = 7
    success = False

    update_progress(1, total_steps, "Stopping Node-RED services...")
    if subprocess.run("systemctl list-units --full --all | grep -q 'nodered.service'", shell=True).returncode == 0; then
        run_shell_command("sudo systemctl stop nodered.service && sudo systemctl disable nodered.service", 1, total_steps, "Stopping Node-RED system service...")
    fi

    # Board update process
    boards=(
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update"
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update"
    )

    for board in "${boards[@]}"; do
        if [ -d "$board" ]; then
            result=$(cd "$board" && ./update 0)
            if [ $? -eq 0 ]; then
                success=true
                update_progress(3, total_steps, "Successfully updated $board")
            fi
        fi
    done

    if [ "$success" = true ]; then
        update_progress(6, total_steps, "Board update succeeded. Enabling Chromium launch...")
        systemctl enable chromium-launch.service
    fi
    root.mainloop()
EOF

python3 $UPDATE_GUI


#!/bin/bash

# Create Python GUI for board update progress
UPDATE_GUI="/home/Automata/update_progress_gui.py"
cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import re
import os
from time import sleep

def update_progress(step, total_steps, message):
    """Update the progress bar and show a status message."""
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()
    sleep(3)

def get_board_name(board_dir):
    """Extract the board name from the directory path."""
    return os.path.basename(os.path.dirname(board_dir))

def run_command_with_timeout(command, timeout=30):
    """Run a command with a timeout to prevent hanging."""
    try:
        result = subprocess.run(command, shell=True, text=True, capture_output=True, timeout=timeout)
        return result
    except subprocess.TimeoutExpired:
        print(f"Command '{command}' timed out.")
        return None

def stream_output(process, step, total_steps):
    """Stream the output of the update command and refresh the GUI."""
    cpu_id = "Unknown"
    version = "Unknown"
    bootloader_warning = False

    while True:
        output = process.stdout.readline()
        if output:
            print(output.strip())
            root.update_idletasks()

            if "Bootloader no answer!!!" in output:
                bootloader_warning = True
                update_progress(step, total_steps, f"Warning: Bootloader no answer for {get_board_name(board_dir)}")

            cpu_match = re.search(r"CPUID:\s*(\S+)", output)
            version_match = re.search(r"Board version\s*>?=\s*(\S+)", output)

            if cpu_match:
                cpu_id = cpu_match.group(1)
                update_progress(step, total_steps, f"Updating... CPU ID: {cpu_id}")

            if version_match:
                version = version_match.group(1)
                update_progress(step, total_steps, f"Board version: {version}")

        elif process.poll() is not None:
            break

    return bootloader_warning

def run_interactive_update(board_dir, step, total_steps):
    """Run the update script with real-time progress updates."""
    board_name = get_board_name(board_dir)
    try:
        update_progress(step, total_steps, f"Starting update for {board_name}...")
        process = subprocess.Popen(
            "yes | sudo ./update 0",
            cwd=board_dir,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        bootloader_warning = stream_output(process, step, total_steps)

        if process.returncode == 0 or bootloader_warning:
            update_progress(step, total_steps, f"Successfully updated {board_name}.")
        else:
            update_progress(step, total_steps, f"Update failed for {board_name}.")
    except Exception as e:
        update_progress(step, total_steps, f"Error updating {board_name}: {str(e)}")

def run_update_steps():
    total_steps = 12

    update_progress(1, total_steps, "Stopping services...")
    run_command_with_timeout("sudo systemctl stop mosquitto.service nodered.service chromium-launch.service", 30)

    update_progress(2, total_steps, "Disabling services...")
    run_command_with_timeout("sudo systemctl disable nodered.service chromium-launch.service", 30)

    step = 3

    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi"]
    for board in boards:
        board_dir = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}/update"
        board_name = get_board_name(board_dir)

        if not os.path.isdir(board_dir):
            update_progress(step, total_steps, f"Board {board_name} not found. Skipping...")
            step += 1
            continue

        if not os.path.isfile(f"{board_dir}/update"):
            update_progress(step, total_steps, f"Update script for {board_name} not found. Skipping...")
            step += 1
            continue

        update_progress(step, total_steps, f"Setting permissions for {board_name}...")
        run_command_with_timeout(f"sudo chmod +x {board_dir}/update && sudo chown Automata:Automata {board_dir}/update", 30)

        run_interactive_update(board_dir, step, total_steps)
        step += 1

    update_progress(step, total_steps, "Enabling services...")
    run_command_with_timeout("sudo systemctl enable nodered.service chromium-launch.service", 30)

    update_progress(step, total_steps, "Starting Node-RED with increased memory...")
    run_command_with_timeout("node-red-pi --max-old-space-size=2048", 30)

    update_progress(step, total_steps, "Launching Chromium...")
    run_command_with_timeout("sudo systemctl start chromium-launch.service && sudo systemctl daemon-reload", 30)

    update_progress(step, total_steps, "Update complete. Please reboot.")
    show_reboot_prompt()

def show_reboot_prompt():
    """Prompt the user to reboot."""
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Update Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    tk.Label(final_window, text="Update Complete", font=("Helvetica", 18), fg="#00b3b3", bg="#2e2e2e").pack(pady=20)
    tk.Label(final_window, text="Please reboot to finalize the update.", font=("Helvetica", 14), fg="orange", bg="#2e2e2e").pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10).grid(row=0, column=0, padx=10)
    tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10).grid(row=0, column=1, padx=10)

    final_window.mainloop()

root = tk.Tk()
root.title("Automata Board Updates")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

tk.Label(root, text="Automata Board Updates", font=("Helvetica", 18), fg="#00b3b3", bg="#2e2e2e").pack(pady=20)

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

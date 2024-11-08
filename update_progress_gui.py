#!/bin/bash

# Create Python GUI for board update progress
UPDATE_GUI="/home/Automata/update_progress_gui.py"
cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk, messagebox
import subprocess
import threading
import os

# Create the main window
root = tk.Tk()
root.title("Automata Board Updates")
window_width = 700  # Increased width
window_height = 500  # Increased height

# Get screen dimensions
screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()

# Calculate position for the window to appear centered
center_x = int((screen_width - window_width) / 2)
center_y = int((screen_height - window_height) / 2)

# Set the window size and position
root.geometry(f"{window_width}x{window_height}+{center_x}+{center_y}")
root.configure(bg='#2e2e2e')

# Title message
label = tk.Label(root, text="Automata Board Updates", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=600, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting updates...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Log file path
log_file = "/home/Automata/update_log.txt"

# Function to log messages to a file
def log_message(message):
    with open(log_file, "a") as log:
        log.write(message + "\n")

# Update progress function
def update_progress(step, total_steps, message, success=False):
    progress['value'] = (step / total_steps) * 100
    color = "green" if success else "orange"
    status_label.config(text=message, fg=color)
    root.update_idletasks()
    log_message(message)

# Function to run shell commands with automated "yes" input
def run_update_command(command, cwd=None):
    result = subprocess.run(
        f"echo yes | {command}",
        shell=True,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    return result

# Function to handle board updates
def run_update_steps():
    total_steps = 7  # Total steps in the update process
    step = 1
    success = False  # Track if at least one board update succeeds

    # Clear log file
    with open(log_file, "w") as log:
        log.write("Automata Board Updates Log\n\n")

    # Step 1: Stop Node-RED services
    update_progress(step, total_steps, "Stopping Node-RED service...")
    if subprocess.run("systemctl is-active --quiet nodered.service", shell=True).returncode == 0:
        result = subprocess.run("sudo systemctl stop nodered.service && sudo systemctl disable nodered.service", shell=True)
        if result.returncode == 0:
            update_progress(step, total_steps, "Node-RED service stopped successfully.", success=True)
        else:
            update_progress(step, total_steps, "Failed to stop Node-RED service.", success=False)
    else:
        update_progress(step, total_steps, "Node-RED service not running or already stopped.", success=True)
    step += 1

    # Step 2: Update Sequent Microsystems Boards
    boards = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi/update"
    ]
    for board in boards:
        update_progress(step, total_steps, f"Updating board in {board}...")
        if os.path.isdir(board):
            result = run_update_command("sudo ./update 0", cwd=board)
            if result.returncode == 0:
                success = True
                update_progress(step, total_steps, f"Successfully updated board in {board}", success=True)
            else:
                error_message = result.stderr.decode('utf-8').strip() if result.stderr else "Unknown error"
                update_progress(step, total_steps, f"Failed to update board in {board}: {error_message}", success=False)
        else:
            update_progress(step, total_steps, f"Board directory {board} not found.", success=False)
        step += 1

    # Step 3: Re-enable Node-RED service
    update_progress(step, total_steps, "Re-enabling Node-RED service...")
    result = subprocess.run("sudo systemctl enable nodered.service", shell=True)
    if result.returncode == 0:
        update_progress(step, total_steps, "Node-RED service re-enabled successfully.", success=True)
    else:
        update_progress(step, total_steps, "Failed to re-enable Node-RED service.", success=False)
    step += 1

    # Completion message
    final_message = "Updates completed successfully." if success else "No updates were applied."
    update_progress(total_steps, total_steps, final_message, success=success)

    # Ask for reboot
    confirm_reboot()

# Function to confirm reboot
def confirm_reboot():
    if messagebox.askyesno("Reboot", "Updates complete. Reboot now?"):
        subprocess.run("sudo reboot", shell=True)

# Start the update process in a separate thread
threading.Thread(target=run_update_steps).start()

# Tkinter loop runs in the background while updates are processed
root.mainloop()
EOF

# Ensure the Python script has execute permissions
chmod +x $UPDATE_GUI

# Run the Python GUI script
python3 $UPDATE_GUI

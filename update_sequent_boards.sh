#!/bin/bash

# Create Python GUI for board update progress
UPDATE_GUI="/home/Automata/update_progress_gui.py"
cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import re
import os  # Ensure this import is present
from time import sleep

def update_progress(step, total_steps, message):
    """Update the progress bar and show a status message."""
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()
    sleep(3)  # Delay to make each step visible

def stream_output(process, step, total_steps):
    """Stream the output of the update command and capture CPU ID and version."""
    cpu_id = "Unknown"
    version = "Unknown"

    while True:
        output = process.stdout.readline()
        if output:
            print(output.strip())  # Debug print in the terminal
            root.update_idletasks()

            # Extract CPU ID and version from output using regex
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

def run_interactive_update(board_dir, step, total_steps):
    """Run the update script with real-time progress updates."""
    try:
        update_progress(step, total_steps, f"Starting update for {board_dir}...")
        process = subprocess.Popen(
            ["sudo", "./update", "0"],
            cwd=board_dir,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        process.stdin.write("yes\n")
        process.stdin.flush()

        stream_output(process, step, total_steps)

        if process.returncode == 0:
            update_progress(step, total_steps, f"Successfully updated {board_dir}.")
        else:
            update_progress(step, total_steps, f"Update failed for {board_dir}.")
    except Exception as e:
        update_progress(step, total_steps, f"Error updating {board_dir}: {str(e)}")

def run_shell_command(command, step, total_steps, message):
    """Run a shell command, update progress, and return the result."""
    update_progress(step, total_steps, message)
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    if result.stderr:
        print(result.stderr)
    return result  # Ensure the result is returned

def enable_and_restart_mosquitto(step, total_steps):
    """Enable and restart Mosquitto with error checking."""
    update_progress(step, total_steps, "Enabling Mosquitto service...")
    enable_result = run_shell_command("sudo systemctl enable mosquitto.service", step, total_steps, "Enabling Mosquitto")

    if enable_result and enable_result.returncode == 0:
        update_progress(step, total_steps, "Restarting Mosquitto...")
        restart_result = run_shell_command("sudo systemctl restart mosquitto.service", step, total_steps, "Restarting Mosquitto")

        if restart_result.returncode != 0:
            update_progress(step, total_steps, "Failed to restart Mosquitto. Check status manually.")
    else:
        update_progress(step, total_steps, "Failed to enable Mosquitto service.")

def run_update_steps():
    total_steps = 14  # Adjusted total steps

    # Step 1: Stop services
    update_progress(1, total_steps, "Stopping services...")
    run_shell_command("sudo systemctl stop mosquitto.service nodered.service chromium-launch.service", 1, total_steps, "Stopping services")

    # Step 2: Disable services
    update_progress(2, total_steps, "Disabling Node-RED and Chromium services...")
    run_shell_command("sudo systemctl disable nodered.service chromium-launch.service", 2, total_steps, "Disabling services")

    step = 3

    # Step 3-7: Board update process
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi"]
    for board in boards:
        board_dir = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}/update"
        if os.path.isfile(f"{board_dir}/update"):
            update_progress(step, total_steps, f"Setting permissions for {board}...")
            run_shell_command(f"sudo chmod +x {board_dir}/update && sudo chown Automata:Automata {board_dir}/update", step, total_steps, f"Setting permissions for {board}")

            run_interactive_update(board_dir, step, total_steps)
            step += 1
        else:
            update_progress(step, total_steps, f"Update script not found for {board}.")
            step += 1

    # Step 8: Re-enable Node-RED and Chromium
    update_progress(step, total_steps, "Re-enabling services...")
    run_shell_command("sudo systemctl enable nodered.service chromium-launch.service", step, total_steps, "Re-enabling services")

    # Step 9: Enable and restart Mosquitto
    enable_and_restart_mosquitto(step, total_steps)

    # Step 10: Start Node-RED with max-old-space-size=2048
    update_progress(step, total_steps, "Starting Node-RED with increased memory...")
    run_shell_command("node-red-start --max-old-space-size=2048", step, total_steps, "Starting Node-RED")

    # Step 11: Launch Chromium
    update_progress(step, total_steps, "Launching Chromium...")
    run_shell_command("sudo systemctl start chromium-launch.service && sudo systemctl daemon-reload", step, total_steps, "Launching Chromium")

    update_progress(step, total_steps, "Update complete. Please reboot.")
    show_reboot_prompt()

def show_reboot_prompt():
    """Display a prompt to reboot the system."""
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

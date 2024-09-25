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
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        status_label.config(text=f"Error during: {message}")
        root.update_idletasks()

def run_update_steps():
    total_steps = 7
    success = False

    # Step 1: Kill lingering services (Node-RED, Mosquitto, etc.)
    update_progress(1, total_steps, "Stopping lingering services...")
    services = ['nodered', 'mosquitto']
    for service in services:
        subprocess.run(f"sudo systemctl stop {service}", shell=True)
    sleep(2)

    # Step 2: Update Sequent Microsystems Boards
    boards = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi/update",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi/update",
        # Add more boards as needed
    ]
    
    step = 2
    for board in boards:
        if os.path.isdir(board):
            run_shell_command(f"cd {board} && ./update 0", step, total_steps, f"Updating board in {board}")
            success = True
        else:
            update_progress(step, total_steps, f"Board directory {board} not found.")
        step += 1

    if success:
        update_progress(total_steps, total_steps, "Board updates completed successfully!")
    else:
        update_progress(total_steps, total_steps, "No updates were applied.")

    root.after(5000, root.quit)  # Close the GUI after 5 seconds

# Run updates in a separate thread to keep GUI responsive
threading.Thread(target=run_update_steps).start()

# Tkinter loop runs in the background while updates are processed
root.mainloop()

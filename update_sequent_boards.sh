
#!/bin/bash

# Step 1: Install necessary dependencies for the GUI
sudo apt-get update
sudo apt-get install -y python3-tk python3-pil python3-pil.imagetk

# Step 2: Create the Python GUI script with progress bar and status updates
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
    total_steps = 7  # Total steps in the update process
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

    # Step 3: Create permanent Chromium auto-start
    update_progress(step, total_steps, "Creating permanent Chromium auto-start script...")
    with open("/home/Automata/launch_chromium_permanent.sh", "w") as f:
        f.write('''
#!/bin/bash
# Wait for the network to be connected
while ! ping -c 1 127.0.0.1 &>/dev/null; do
    sleep 1
done

# Wait for an additional 10 seconds after network connection
sleep 10

# Launch Chromium in windowed mode
chromium-browser --disable-features=KioskMode --new-window http://127.0.0.1:1880/ http://127.0.0.1:1880/ui
''')
    subprocess.run("chmod +x /home/Automata/launch_chromium_permanent.sh", shell=True)

    autostart_file = "/home/Automata/.config/lxsession/LXDE-pi/autostart"
    subprocess.run(f'mkdir -p $(dirname "{autostart_file}")', shell=True)
    with open(autostart_file, "a") as f:
        if 'launch_chromium_permanent.sh' not in f.read():
            f.write("@/home/Automata/launch_chromium_permanent.sh\n")

    step += 1
    update_progress(step, total_steps, "Permanent Chromium auto-start script created.")

    # Step 4: Remove the temporary auto-start entry if successful
    if success:
        update_progress(step, total_steps, "Removing temporary auto-start entry...")
        subprocess.run("sed -i '/update_sequent_boards.sh/d' /home/Automata/.config/lxsession/LXDE-pi/autostart", shell=True)
        step += 1
        update_progress(step, total_steps, "Temporary auto-start entry removed.")

    # Step 5: Show success message and reboot prompt
    if success:
        status_label.config(text="Updates completed successfully! Rebooting now...")
    else:
        status_label.config(text="No updates were applied. Rebooting now...")

    # Add a reboot prompt
    root.after(5000, lambda: subprocess.run("sudo reboot", shell=True))

# Run updates in a separate thread to keep GUI responsive
threading.Thread(target=run_update_steps).start()

# Tkinter loop runs in the background while updates are processed
root.mainloop()
EOF

# Step 3: Start the Tkinter GUI for the update process
sleep 15  # Add a delay to avoid conflicts
python3 $UPDATE_GUI &


#!/bin/bash

# Create Python GUI for board update progress
UPDATE_GUI="/home/Automata/update_progress_gui.py"
cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
from time import sleep  # Added the missing import

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
    return result

def get_cpuid(board_path):
    cpuid_file = os.path.join(board_path, "update", "cpuid")
    try:
        if os.path.exists(cpuid_file):
            with open(cpuid_file, "r") as f:
                cpuid = f.read().strip()
            if cpuid:
                return cpuid
            else:
                return "CPU ID not found"
        else:
            return "CPU ID file missing"
    except Exception as e:
        return f"Error retrieving CPU ID: {str(e)}"

def run_update_steps():
    total_steps = 12  # Adjusted total steps
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
        "megabas-rpi",
        "megaind-rpi",
        "16univin-rpi",
        "16relind-rpi"
    ]

    step = 2
    for board in boards:
        board_update_script = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}/update/update"
        if os.path.isfile(board_update_script):
            update_progress(step, total_steps, f"Setting executable permissions for {board} update script...")
            run_shell_command(f"sudo chmod +x {board_update_script}", step, total_steps, f"Setting executable permissions for {board}...")

            # Fetch CPU ID and display it in the GUI
            cpuid = get_cpuid(f"/home/Automata/AutomataBuildingManagment-HvacController/{board}")
            update_progress(step, total_steps, f"Updating {board} (CPU ID: {cpuid})...")

            # Run the update script in a new terminal window using lxterminal
            lxterminal_command = f"lxterminal --command='bash -c \"cd /home/Automata/AutomataBuildingManagment-HvacController/{board}/update && ./update 0\"'"
            result = subprocess.run(lxterminal_command, shell=True, text=True, capture_output=True)

            if result.returncode == 0:
                success = True
                print(f"Successfully updated {board}")
            else:
                print(f"Failed to update {board}: {result.stderr}")
            step += 1
        else:
            print(f"Board update script {board_update_script} not found.")
            step += 1

    # Step 7: Re-enabling Node-RED service
    update_progress(step, total_steps, "Re-enabling and starting Node-RED service...")
    run_shell_command("sudo systemctl enable nodered.service && sudo systemctl start nodered.service", step, total_steps, "Re-enabling and starting Node-RED service")
    sleep(2)
    step += 1

    # Step 8: Re-enabling Mosquitto service
    update_progress(step, total_steps, "Re-enabling and starting Mosquitto service...")
    run_shell_command("sudo systemctl enable mosquitto.service && sudo systemctl start mosquitto.service", step, total_steps, "Re-enabling and starting Mosquitto service")
    sleep(2)
    step += 1

    # Step 9: Enabling Chromium launch if successful
    if success:
        update_progress(step, total_steps, "Board update succeeded. Enabling Chromium launch...")
        run_shell_command("sudo systemctl enable chromium-launch.service", total_steps, total_steps, "Enabling Chromium launch service")
    else:
        update_progress(total_steps, total_steps, "Board update failed.")
        print("No boards were updated successfully.")

    # Step 10: Finish GUI and prompt for reboot
    status_label.config(text="Final Reboot to save board firmware...")
    root.update_idletasks()
    show_reboot_prompt()

def show_reboot_prompt():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Board Firmware Update Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Board Firmware Update Complete", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="Please reboot to finalize the firmware update.\n\nReboot now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    final_message.pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

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



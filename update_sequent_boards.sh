# Create Python GUI for board update progress
UPDATE_GUI="/home/Automata/update_progress_gui.py"
cat << 'EOF' > $UPDATE_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
from time import sleep

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
    total_steps = 14  # Adjusted total steps to include new steps
    success = False

    # Step 1: Kill all related services (Mosquitto, Node-RED, launch_chromium)
    update_progress(1, total_steps, "Stopping related services...")
    run_shell_command("sudo systemctl stop mosquitto.service nodered.service chromium-launch.service", 1, total_steps, "Stopping Mosquitto, Node-RED, and Chromium services")
    sleep(2)

    # Step 2: Disable Node-RED and launch_chromium services
    update_progress(2, total_steps, "Disabling Node-RED and Chromium services...")
    run_shell_command("sudo systemctl disable nodered.service chromium-launch.service", 2, total_steps, "Disabling Node-RED and Chromium services")
    sleep(2)

    step = 3  # Continue from here after services are stopped

    # Step 3-7: Board update process
    boards = [
        "megabas-rpi",
        "megaind-rpi",
        "16univin-rpi",
        "16relind-rpi"
    ]

    for board in boards:
        board_update_script = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}/update/update"
        if os.path.isfile(board_update_script):
            update_progress(step, total_steps, f"Setting executable permissions for {board} update script...")
            run_shell_command(f"sudo chmod +x {board_update_script}", step, total_steps, f"Setting executable permissions for {board}...")

            # Fetch CPU ID and display it in the GUI
            cpuid = get_cpuid(f"/home/Automata/AutomataBuildingManagment-HvacController/{board}")
            update_progress(step, total_steps, f"Updating {board} (CPU ID: {cpuid})...")

            # Change directory and run the update script directly
            result = run_shell_command(f"cd /home/Automata/AutomataBuildingManagment-HvacController/{board}/update && sudo ./update 0", step, total_steps, f"Running update for {board}...")

            if result.returncode == 0:
                success = True
                print(f"Successfully updated {board}")
            else:
                print(f"Failed to update {board}: {result.stderr}")
            step += 1
        else:
            print(f"Board update script {board_update_script} not found.")
            step += 1

    # Step 8: Re-enable services
    update_progress(step, total_steps, "Re-enabling Node-RED and Chromium services...")
    run_shell_command("sudo systemctl enable nodered.service chromium-launch.service", step, total_steps, "Re-enabling Node-RED and Chromium services")
    sleep(2)
    step += 1

    # Step 9: Set permissions for launch_chromium.py
    update_progress(step, total_steps, "Setting ownership and permissions for launch_chromium.py...")
    run_shell_command("sudo chown Automata:Automata /home/Automata/launch_chromium.py && sudo chmod +x /home/Automata/launch_chromium.py", step, total_steps, "Setting ownership and permissions for launch_chromium.py")
    sleep(2)
    step += 1

    # Step 10: Create a systemd service to launch Chromium at boot
    update_progress(step, total_steps, "Creating a systemd service for Chromium auto-launch...")
    chromium_service = '''
[Unit]
Description=Auto-launch Chromium at boot after network is up
After=network.target

[Service]
ExecStart=/usr/bin/chromium-browser --new-window http://127.0.0.1:1880/ http://127.0.0.1:1880/ui
User=Automata
Environment=DISPLAY=:0
Restart=on-failure

[Install]
WantedBy=multi-user.target
    '''
    with open('/home/Automata/chromium-launch.service', 'w') as f:
        f.write(chromium_service)

    # Move the file to the systemd directory with elevated permissions
    run_shell_command("sudo mv /home/Automata/chromium-launch.service /etc/systemd/system/", step, total_steps, "Moving Chromium service to systemd directory")
    run_shell_command("sudo systemctl enable chromium-launch.service", step, total_steps, "Enabling Chromium auto-launch service")
    sleep(2)
    step += 1

    # Step 11: Restart all services and reload daemons
    update_progress(step, total_steps, "Restarting Mosquitto, Node-RED, Chromium services, and reloading daemons...")
    run_shell_command("sudo systemctl start mosquitto.service nodered.service chromium-launch.service && sudo systemctl daemon-reload", step, total_steps, "Restarting all services and reloading daemons")
    sleep(2)
    step += 1

    # Step 12: Create a desktop icon to open Node-RED UI pages
    update_progress(step, total_steps, "Creating a desktop icon for Node-RED UI pages...")
    desktop_icon_content = '''
[Desktop Entry]
Name=Open Node-RED UI
Comment=Launch Node-RED interface
Exec=/home/Automata/open_node_red.sh
Icon=/home/Automata/AutomataBuildingManagment-HvacController/NodeRedLogo.png
Terminal=false
Type=Application
Categories=Utility;
    '''
    with open('/home/Automata/Desktop/OpenNodeRedUI.desktop', 'w') as f:
        f.write(desktop_icon_content)
    
    # Set the correct permissions and ownership for the icon
    run_shell_command("chmod +x /home/Automata/Desktop/OpenNodeRedUI.desktop && chown Automata:Automata /home/Automata/Desktop/OpenNodeRedUI.desktop", step, total_steps, "Setting permissions for Node-RED desktop icon")
    sleep(2)
    step += 1

    # Step 13: Create shell script to open Node-RED UI pages
    update_progress(step, total_steps, "Creating shell script to open Node-RED UI pages...")
    node_red_script_content = '''
#!/bin/bash
xdg-open http://127.0.0.1:1880/
xdg-open http://127.0.0.1:1880/ui
    '''
    with open('/home/Automata/open_node_red.sh', 'w') as f:
        f.write(node_red_script_content)

    # Set permissions for the shell script
    run_shell_command("chmod +x /home/Automata/open_node_red.sh", step, total_steps, "Setting permissions for Node-RED shell script")
    sleep(2)
    step += 1

    # Step 14: Final step - prompt for reboot
    if success:
        update_progress(step, total_steps, "Board update succeeded. Please reboot.")
    else:
        update_progress(total_steps, total_steps, "Board update failed.")
        print("No boards were updated successfully.")

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

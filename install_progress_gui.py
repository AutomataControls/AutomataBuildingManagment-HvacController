#!/usr/bin/env python3

import tkinter as tk
from tkinter import ttk
import subprocess
import threading
from time import sleep

# Create the main window
root = tk.Tk()
root.title("Automata Installation Progress")
window_width = 700
window_height = 500

# Center the window
screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()
center_x = (screen_width - window_width) // 2
center_y = (screen_height - window_height) // 2
root.geometry(f"{window_width}x{window_height}+{center_x}+{center_y}")
root.configure(bg='#2e2e2e')

# Title message
label = tk.Label(root, text="Automata Installation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Footer message
footer_label = tk.Label(root, text="Developed by A. Jewell Sr, 2023", font=("Arial", 10), fg="#00b3b3", bg="#2e2e2e")
footer_label.pack(side="bottom", pady=5)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting installation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Spinning animation
spin_label = tk.Label(root, text="", font=("Helvetica", 12), fg="#00b3b3", bg="#2e2e2e")
spin_label.pack(pady=10)

# Spinner animation
def spin_animation():
    while True:
        for frame in ["|", "/", "-", "\\"]:
            spin_label.config(text=frame)
            sleep(0.1)
            root.update_idletasks()

# Update progress bar
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Execute shell commands
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    try:
        subprocess.run(command, shell=True, check=True, text=True)
    except subprocess.CalledProcessError as e:
        status_label.config(text=f"Error: {message}. Check logs.")
        print(f"Error output: {e.stderr}")
    root.update_idletasks()

# Create desktop icons
def create_desktop_icons():
    update_icon = "/home/Automata/Desktop/UpdateSmBoards.desktop"
    update_script = "/home/Automata/AutomataBuildingManagment-HvacController/update_sequent_boards.sh"
    update_image = "/home/Automata/AutomataBuildingManagment-HvacController/splash.png"

    update_content = f"""[Desktop Entry]
Name=Update Sequent Boards
Comment=Run the Sequent Board Update Script
Exec=lxterminal -e "bash {update_script}"
Icon={update_image}
Terminal=false
Type=Application
Categories=Utility;
"""
    with open(update_icon, "w") as f:
        f.write(update_content)
    subprocess.run(f"chmod +x {update_icon}", shell=True)
    subprocess.run(f"chown Automata:Automata {update_icon}", shell=True)

    node_red_icon = "/home/Automata/Desktop/OpenNodeRedUI.desktop"
    node_red_image = "/home/Automata/AutomataBuildingManagment-HvacController/NodeRedlogo.png"
    node_red_content = f"""[Desktop Entry]
Name=Open Node-RED
Comment=Open Node-RED UI and Dashboard
Exec=sh -c "xdg-open http://127.0.0.1:1880/ & xdg-open http://127.0.0.1:1880/ui"
Icon={node_red_image}
Terminal=false
Type=Application
Categories=Utility;
"""
    with open(node_red_icon, "w") as f:
        f.write(node_red_content)
    subprocess.run(f"chmod +x {node_red_icon}", shell=True)
    subprocess.run(f"chown Automata:Automata {node_red_icon}", shell=True)

# Mosquitto installation and setup
def setup_mosquitto(step, total_steps):
    run_shell_command("sudo apt-get update", step, total_steps, "Updating package lists for Mosquitto...")
    step += 1
    run_shell_command("sudo apt-get install -y mosquitto mosquitto-clients", step, total_steps, "Installing Mosquitto and clients...")
    step += 1
    run_shell_command("sudo touch /etc/mosquitto/passwd && sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2", step, total_steps, "Setting up Mosquitto user...")
    step += 1
    run_shell_command("sudo cp /etc/mosquitto/mosquitto.conf /etc/mosquitto/mosquitto.conf.bak", step, total_steps, "Backing up Mosquitto configuration...")
    step += 1
    config_commands = [
        "echo 'listener 1883' | sudo tee -a /etc/mosquitto/mosquitto.conf",
        "echo 'allow_anonymous false' | sudo tee -a /etc/mosquitto/mosquitto.conf",
        "echo 'password_file /etc/mosquitto/passwd' | sudo tee -a /etc/mosquitto/mosquitto.conf",
        "echo 'per_listener_settings true' | sudo tee -a /etc/mosquitto/mosquitto.conf"
    ]
    for cmd in config_commands:
        run_shell_command(cmd, step, total_steps, "Configuring Mosquitto settings...")
        step += 1
    run_shell_command("sudo systemctl restart mosquitto", step, total_steps, "Restarting Mosquitto service...")
    step += 1
    return step

# Installation steps
def run_installation_steps():
    total_steps = 50
    step = 1

    # Copy splash.png
    run_shell_command("cp /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/", step, total_steps, "Copying splash.png...")
    step += 1

    # Setup Mosquitto
    step = setup_mosquitto(step, total_steps)

    # Install Node-RED
    run_shell_command("sudo apt update && sudo apt install -y nodejs npm", step, total_steps, "Installing Node.js and npm...")
    step += 1
    run_shell_command("sudo npm install -g --unsafe-perm node-red", step, total_steps, "Installing Node-RED...")
    step += 1
    run_shell_command("node-red & sleep 5 && pkill -f node-red", step, total_steps, "Initializing Node-RED...")
    step += 1

    # Install Node-RED palettes
    palettes = [
        "node-red-contrib-ui-led",
        "node-red-dashboard",
        "node-red-contrib-sm-16inpind",
        "node-red-contrib-sm-16relind",
        "node-red-contrib-sm-8inputs",
        "node-red-contrib-sm-8relind",
        "node-red-contrib-sm-bas",
        "node-red-contrib-sm-ind",
        "node-red-node-openweathermap",
        "node-red-contrib-influxdb",
        "node-red-node-email",
        "node-red-contrib-boolean-logic-ultimate",
        "node-red-contrib-cpu",
        "node-red-contrib-bme280-rpi",
        "node-red-contrib-bme280",
        "node-red-node-aws",
        "@node-red-contrib-themes/theme-collection"
    ]
    for palette in palettes:
        run_shell_command(f"cd /home/Automata/.node-red && npm install {palette}", step, total_steps, f"Installing Node-RED Palette: {palette}")
        step += 1

    # Create desktop icons
    create_desktop_icons()

    # Finalize
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# Reboot prompt
def show_reboot_prompt():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Installation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    tk.Label(final_window, text="Installation Complete", font=("Helvetica", 18), fg="#00b3b3", bg="#2e2e2e").pack(pady=20)
    tk.Label(final_window, text="Reboot to finalize installation.", font=("Helvetica", 14), fg="orange", bg="#2e2e2e").pack(pady=20)

    tk.Button(final_window, text="Reboot Now", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10).pack(side="left", padx=20)
    tk.Button(final_window, text="Later", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10).pack(side="right", padx=20)

    final_window.mainloop()

# Start threads for installation and spinner
threading.Thread(target=run_installation_steps, daemon=True).start()
threading.Thread(target=spin_animation, daemon=True).start()

# Start main loop
root.mainloop()

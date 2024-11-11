#!/usr/bin/env python3

import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
from time import sleep

# Create the main window
root = tk.Tk()
root.title("Automata Installation Progress")
window_width = 700
window_height = 500

# Get screen dimensions and calculate the center position
screen_width = root.winfo_screenwidth()
screen_height = root.winfo_screenheight()
center_x = (screen_width - window_width) // 2
center_y = (screen_height - window_height) // 2

# Set the window size and position
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

# Spinning line animation below the progress bar
spin_label = tk.Label(root, text="", font=("Helvetica", 12), fg="#00b3b3", bg="#2e2e2e")
spin_label.pack(pady=10)

# Function to update the spinning line animation
def spin_animation():
    while True:
        for frame in ["|", "/", "-", "\\"]:
            spin_label.config(text=frame)
            sleep(0.1)
            root.update_idletasks()

# Function to update progress bar and status
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Function to run shell commands
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    try:
        subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        print(f"Error output: {e.stderr}")
    root.update_idletasks()

# Function to create desktop icons
def create_desktop_icons(step, total_steps):
    # Update SmBoards Icon
    desktop_file = "/home/Automata/Desktop/UpdateSmBoards.desktop"
    icon_script = "/home/Automata/AutomataBuildingManagment-HvacController/update_sequent_boards.sh"
    icon_image = "/home/Automata/AutomataBuildingManagment-HvacController/splash.png"
    icon_content = f"""[Desktop Entry]
Name=Update Sequent Boards
Comment=Run the Sequent Board Update Script
Exec=lxterminal -e "bash {icon_script}"
Icon={icon_image}
Terminal=false
Type=Application
Categories=Utility;
"""
    with open(desktop_file, "w") as f:
        f.write(icon_content)
    subprocess.run(f"chmod +x {desktop_file}", shell=True)
    subprocess.run(f"chown Automata:Automata {desktop_file}", shell=True)

    # Node-RED Icon
    desktop_file = "/home/Automata/Desktop/OpenNodeRedUI.desktop"
    icon_image = "/home/Automata/AutomataBuildingManagment-HvacController/NodeRedlogo.png"
    icon_content = f"""[Desktop Entry]
Name=Open Node-RED
Comment=Open Node-RED UI and Dashboard
Exec=sh -c "xdg-open http://127.0.0.1:1880/ & xdg-open http://127.0.0.1:1880/ui"
Icon={icon_image}
Terminal=false
Type=Application
Categories=Utility;
"""
    with open(desktop_file, "w") as f:
        f.write(icon_content)
    subprocess.run(f"chmod +x {desktop_file}", shell=True)
    subprocess.run(f"chown Automata:Automata {desktop_file}", shell=True)

    update_progress(step, total_steps, "Desktop icons created successfully.")
    step += 1
    return step

# Function to install Node-RED
def install_node_red(step, total_steps):
    run_shell_command("sudo apt update", step, total_steps, "Updating package lists for Node-RED")
    step += 1
    run_shell_command("sudo apt install -y nodejs npm", step, total_steps, "Installing Node.js and npm")
    step += 1
    run_shell_command("sudo npm install -g --unsafe-perm node-red", step, total_steps, "Installing Node-RED globally")
    step += 1
    run_shell_command("node-red & sleep 5 && pkill -f node-red", step, total_steps, "Initializing Node-RED for the first time")
    step += 1
    return step

# Function to install Node-RED palettes
def install_node_red_palettes(step, total_steps):
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
        "node-red-contrib-themes/theme-collection",
    ]
    for palette in palettes:
        run_shell_command(f"cd /home/Automata/.node-red && npm install {palette}", step, total_steps, f"Installing Node-RED Palette: {palette}")
        step += 1
    return step

# Function to configure NTP and timezone
def configure_ntp(step, total_steps):
    run_shell_command("sudo systemctl stop ntp", step, total_steps, "Stopping existing NTP service")
    step += 1
    run_shell_command("sudo apt install -y ntp", step, total_steps, "Installing NTP")
    step += 1
    run_shell_command("sudo systemctl enable ntp", step, total_steps, "Enabling NTP service")
    step += 1
    run_shell_command("sudo systemctl start ntp", step, total_steps, "Starting NTP service")
    step += 1
    run_shell_command("sudo ntpd -gq", step, total_steps, "Synchronizing time with NTP servers")
    step += 1
    run_shell_command("sudo timedatectl set-timezone America/New_York", step, total_steps, "Setting timezone to EST")
    step += 1
    return step

# Run all installation steps
def run_installation_steps():
    total_steps = 50  # Adjusted to match all steps
    step = 1

    # Step 1: Adjust swap size
    run_shell_command("sudo dphys-swapfile swapoff", step, total_steps, "Turning off swap")
    step += 1
    run_shell_command("sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=4096/' /etc/dphys-swapfile", step, total_steps, "Setting swap size to 4GB")
    step += 1
    run_shell_command("sudo dphys-swapfile setup", step, total_steps, "Setting up new swap size")
    step += 1
    run_shell_command("sudo dphys-swapfile swapon", step, total_steps, "Turning on swap")
    step += 1

    # Step 5: Configure NTP
    step = configure_ntp(step, total_steps)

    # Step 10: Install Node-RED
    step = install_node_red(step, total_steps)

    # Step 15: Install Node-RED palettes
    step = install_node_red_palettes(step, total_steps)

    # Step 30: Create desktop icons
    step = create_desktop_icons(step, total_steps)

    # Final Step: Show completion message
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# Function to show reboot prompt
def show_reboot_prompt():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Installation Complete")
    final_window.geometry(f"{window_width}x{window_height}+{center_x}+{center_y}")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata Building Management & HVAC Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="Please reboot to finalize settings.\nReboot now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    final_message.pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

# Start installation steps in a separate thread
threading.Thread(target=run_installation_steps, daemon=True).start()

# Start spinner animation
threading.Thread(target=spin_animation, daemon=True).start()

# Tkinter main loop
root.mainloop()

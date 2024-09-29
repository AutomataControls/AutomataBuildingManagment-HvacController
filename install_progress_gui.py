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
root.geometry("600x400")
root.configure(bg='#2e2e2e')

# Title message
label = tk.Label(root, text="Automata Installation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Footer message (Developed by A. Jewell Sr.)
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

# Function to update progress
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Function to run shell commands
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        print(f"Command output: {result.stdout}")
    except subprocess.CalledProcessError as e:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        print(f"Error output: {e.stderr}")
    root.update_idletasks()

# Function to create a desktop icon for updating boards using splash.png as the icon
def create_desktop_icon():
    desktop_file = "/home/Automata/Desktop/UpdateSmBoards.desktop"
    icon_script = "/home/Automata/AutomataBuildingManagment-HvacController/update_sequent_boards.sh"
    icon_image = "/home/Automata/AutomataBuildingManagment-HvacController/splash.png"  # Path to splash.png
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
    
    print("Desktop icon for updating Sequent boards created successfully!")

# Function to create a Node-RED desktop icon
def create_node_red_icon():
    desktop_file = "/home/Automata/Desktop/OpenNodeRedUI.desktop"
    icon_image = "/usr/lib/node_modules/node-red/public/red/images/node-red-icon.svg"
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
    
    print("Desktop icon for Node-RED created successfully!")

# Function to install Node-RED palette nodes
def install_palette_node(node, step, total_steps):
    run_shell_command(f"cd /home/Automata/.node-red && npm install {node}", step, total_steps, f"Installing {node} palette node...")
    sleep(3)

# Run all installation steps in order
def run_installation_steps():
    total_steps = 39  # Adjusted for the additional Mosquitto setup step
    step = 1

    # Step 1: Copy splash.png from the repo directory to /home/Automata
    run_shell_command("cp /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/", step, total_steps, "Copying splash.png to /home/Automata...")
    sleep(3)
    step += 1

    # Step 2: Navigate to /usr/share/plymouth/themes/pix/, move the original splash.png and copy the new one
    run_shell_command("cd /usr/share/plymouth/themes/pix/ && sudo mv splash.png splash.png.bk", step, total_steps, "Backing up original splash.png...")
    run_shell_command("sudo cp /home/Automata/splash.png /usr/share/plymouth/themes/pix/", step, total_steps, "Copying Automata splash.png to Plymouth theme...")
    sleep(3)
    step += 1
    update_progress(step, total_steps, "Splash logo moved successful!")

    # Step 3: Set desktop background
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_background.sh", step, total_steps, "Setting desktop background...")
    sleep(3)
    step += 1

    # Step 4: Overclock the Raspberry Pi
    run_shell_command("echo -e 'over_voltage=2\narm_freq=1750' | sudo tee -a /boot/config.txt", step, total_steps, "Overclocking CPU...Turbo mode engaged!")
    sleep(5)
    step += 1

    # Step 5: Set Internet Time
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", step, total_steps, "Setting internet time to Eastern Standard...")
    sleep(5)
    step += 1

    # Step 6: Increase swap size
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", step, total_steps, "Increasing swap size...")
    sleep(5)
    step += 1

    # New Step 7: Setup Mosquitto
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/setup_mosquitto.sh", step, total_steps, "Setting up Mosquitto MQTT broker...")
    sleep(5)
    step += 1

    # Step 8: Clone Sequent Microsystems drivers
    boards_to_clone = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards_to_clone:
        run_shell_command(f"git clone https://github.com/sequentmicrosystems/{board}.git /home/Automata/AutomataBuildingManagment-HvacController/{board}", step, total_steps, f"Cloning {board}...")
        update_progress(step, total_steps, f"Cloning {board} Success!")
        sleep(4)
        step += 1

    # Step 9: Install Sequent Microsystems drivers
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards:
        board_path = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}"
        if os.path.isdir(board_path):
            run_shell_command(f"cd {board_path} && sudo make install", step, total_steps, f"Installing {board} driver from Repo Directory.")
            update_progress(step, total_steps, f"Installed {board} driver successfully!")
            step += 1
        else:
            update_progress(step, total_steps, f"Board {board} not found, skipping...")
            step += 1
        sleep(5)

    # Step 10: Install Node-RED theme package and fix the missing theme issue
    run_shell_command("mkdir -p /home/Automata/.node-red/node_modules/@node-red-contrib-themes/theme-collection/themes", step, total_steps, "Creating theme collection directory...")
    step += 1

    # Step 11: Install Node-RED
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh", step, total_steps, "Installing Node-RED... This could take some time.")
    sleep(5)
    step += 1

    # Step 12: Configure Node-RED Security
    update_progress(step, total_steps, "Node-RED Security Measures initiated...")
    sleep(5)
    step += 1

    # Step 13: Setup Node-RED Encryption
    update_progress(step, total_steps, "Node-RED Encryption Finalizing...\n SSL and TLS Ready...")
    sleep(5)
    step += 1

    # Step 14: Finalize Node-RED Authorization
    update_progress(step, total_steps, "Node-RED Authorization Credentials Hashed and Configured...\n Welcome Automata!")
    sleep(5)
    step += 1

    # Step 15: Install Node-RED palette nodes
    palette_nodes = [
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
    for node in palette_nodes:
        install_palette_node(node, step, total_steps)
        step += 1

    # Step 16: Enable VNC
    run_shell_command("sudo raspi-config nonint do_vnc 0", step, total_steps, "Enabling Remote Access via RealVNC...")
    sleep(5)
    step += 1

    # Step 17: Enable I2C
    run_shell_command("sudo raspi-config nonint do_i2c 0", step, total_steps, "Enabling I2C Sensor Communication...")
    sleep(5)
    step += 1

    # Step 18: Enable SPI
    run_shell_command("sudo raspi-config nonint do_spi 0", step, total_steps, "Enabling SPI Sensor Communication...")
    sleep(5)
    step += 1

    # Step 19: Enable 1-Wire
    run_shell_command("sudo raspi-config nonint do_onewire 0", step, total_steps, "Enabling 1-Wire Data Communication...")
    sleep(5)
    step += 1

    # Step 20: Disable screen blanking
    run_shell_command("sudo raspi-config nonint do_blanking 1", step, total_steps, "Disabling screen blanking...")
    sleep(5)
    step += 1

    # Step 21: Create UpdateSmBoards desktop icon
    update_progress(step, total_steps, "Creating desktop icon for updating Sequent boards...")
    create_desktop_icon()
    step += 1

    # Step 22: Create a Node-RED desktop icon
    update_progress(step, total_steps, "Creating desktop icon for Node-RED...")
    create_node_red_icon()
    step += 1

    # Final Step: Installation complete
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# Function to show the reboot prompt
def show_reboot_prompt():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Installation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata Building Management & HVAC Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="A New Realm of Automation Awaits!\nPlease reboot to finalize settings and configuration files.\n\nReboot Now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    final_message.pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

# Start the installation steps in a separate thread to keep the GUI responsive
threading.Thread(target=run_installation_steps, daemon=True).start()

# Start spinner animation in a separate thread
threading.Thread(target=spin_animation, daemon=True).start()

# Tkinter main loop to keep the GUI running
root.mainloop()

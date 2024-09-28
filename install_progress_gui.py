#!/usr/bin/env python3

import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
from time import sleep

# ... (previous parts of the script remain unchanged)

def run_installation_steps():
    total_steps = 33
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
    update_progress(step, total_steps, "Splash logo move successful!")

    # Step 3: Overclock the Raspberry Pi
    run_shell_command("echo -e 'over_voltage=2\narm_freq=1750' | sudo tee -a /boot/config.txt", step, total_steps, "Overclocking CPU...Turbo mode engaged!")
    sleep(5)
    step += 1

    # Step 4: Set Internet Time
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", step, total_steps, "Setting internet time...")
    sleep(5)
    step += 1

    # Step 5: Increase swap size
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", step, total_steps, "Increasing swap size...")
    sleep(5)
    step += 1

    # Step 6: Clone Sequent Microsystems drivers
    boards_to_clone = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards_to_clone:
        run_shell_command(f"git clone https://github.com/sequentmicrosystems/{board}.git /home/Automata/AutomataBuildingManagment-HvacController/{board}", step, total_steps, f"Cloning {board}...")
        update_progress(step, total_steps, f"Cloning {board}... This might take a while.")
        sleep(4)
        step += 1

    # Step 7: Install Sequent Microsystems drivers
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards:
        board_path = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}"
        if os.path.isdir(board_path):
            run_shell_command(f"cd {board_path} && sudo make install", step, total_steps, f"Installing {board} driver... This could take some time.")
            update_progress(step, total_steps, f"Installed {board} driver successfully!")
            step += 1
        else:
            update_progress(step, total_steps, f"Board {board} not found, skipping...")
            step += 1
        sleep(5)

    # Step 8: Install Node-RED theme package and fix the missing theme issue
    run_shell_command("mkdir -p /home/Automata/.node-red/node_modules/@node-red-contrib-themes/theme-collection/themes", step, total_steps, "Creating theme collection directory...")
    step += 1

    # Step 9: Install Node-RED
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh", step, total_steps, "Installing Node-RED... This could take some time.")
    update_progress(step, total_steps, "Node-RED Security Measures initiated...")
    sleep(5)
    step += 1

    # Step 10: Install Node-RED palette nodes
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
        "node-red-node-aws33",
        "@node-red-contrib-themes/theme-collection"
    ]
    for node in palette_nodes:
        install_palette_node(node, step, total_steps)
        step += 1

    # Step 11: Enable VNC
    run_shell_command("sudo raspi-config nonint do_vnc 0", step, total_steps, "Enabling VNC...")
    sleep(5)
    step += 1

    # Step 12: Enable I2C
    run_shell_command("sudo raspi-config nonint do_i2c 0", step, total_steps, "Enabling I2C...")
    sleep(5)
    step += 1

    # Step 13: Enable SPI
    run_shell_command("sudo raspi-config nonint do_spi 0", step, total_steps, "Enabling SPI...")
    sleep(5)
    step += 1

    # Step 14: Enable 1-Wire
    run_shell_command("sudo raspi-config nonint do_onewire 0", step, total_steps, "Enabling 1-Wire...")
    sleep(5)
    step += 1

    # Step 15: Disable screen blanking
    run_shell_command("sudo raspi-config nonint do_blanking 1", step, total_steps, "Disabling screen blanking...")
    sleep(5)
    step += 1

    # Step 16: Create a Node-RED desktop icon
    update_progress(step, total_steps, "Creating desktop icon for Node-RED...")
    create_node_red_icon()
    step += 1

    # Final Step: Installation complete
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# ... (rest of the script remains unchanged)

# Start the installation steps in a separate thread to keep the GUI responsive
threading.Thread(target=run_installation_steps, daemon=True).start()

# Start spinner animation in a separate thread
threading.Thread(target=spin_animation, daemon=True).start()

# Tkinter main loop to keep the GUI running
root.mainloop()

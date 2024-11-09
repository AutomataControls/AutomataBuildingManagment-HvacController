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
    
    print("Desktop icon for updating Sequent boards created successfully!")

# Function to create a Node-RED desktop icon
def create_node_red_icon():
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
    
    print("Desktop icon for Node-RED created successfully!")

# Function to install Node-RED palette nodes
def install_palette_node(node, step, total_steps):
    run_shell_command(f"cd /home/Automata/.node-red && npm install {node}", step, total_steps, f"Installing {node} palette node...")
    sleep(3)

# Run all installation steps in order
def run_installation_steps():
    total_steps = 40
    step = 1

    # Step 1: Copy splash.png
    run_shell_command("cp /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/", step, total_steps, "Copying splash.png to /home/Automata...")
    sleep(3)
    step += 1

    # Step 2: Move and copy splash.png for Plymouth theme
    run_shell_command("cd /usr/share/plymouth/themes/pix/ && sudo mv splash.png splash.png.bk", step, total_steps, "Backing up original splash.png...")
    run_shell_command("sudo cp /home/Automata/splash.png /usr/share/plymouth/themes/pix/", step, total_steps, "Copying Automata splash.png to Plymouth theme...")
    sleep(3)
    step += 1

    # Step 13-17: Install Sequent Microsystems drivers
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards:
        board_path = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}"
        if os.path.isdir(board_path):
            run_shell_command(f"cd {board_path} && sudo make install", step, total_steps, f"Installing {board} driver from Repo Directory.")
        else:
            update_progress(step, total_steps, f"Board {board} not found, skipping...")
        sleep(5)
        step += 1

    # Final Step: Installation complete
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# Function to show the reboot prompt
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

# Start the installation steps in a separate thread to keep the GUI responsive
threading.Thread(target=run_installation_steps, daemon=True).start()

# Start spinner animation in a separate thread
threading.Thread(target=spin_animation, daemon=True).start()

# Tkinter main loop to keep the GUI running
root.mainloop()

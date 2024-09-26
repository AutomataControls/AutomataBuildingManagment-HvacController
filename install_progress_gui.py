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
    result = subprocess.run(command, shell=True, text=True, capture_output=True, timeout=600)
    if result.returncode != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        print(f"Error output: {result.stderr}")
        root.update_idletasks()
    else:
        print(f"Command output: {result.stdout}")

# Run all installation steps in order
def run_installation_steps():
    total_steps = 31  # Adjusted total steps
    step = 1

    # Step 1: Copy splash.png from the repo directory to /home/Automata
    run_shell_command("cp /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/", step, total_steps, "Copying splash.png to /home/Automata...")
    sleep(2)
    step += 1

    # Step 2: Navigate to /usr/share/plymouth/themes/pix/, move the original splash.png and copy the new one
    run_shell_command("cd /usr/share/plymouth/themes/pix/ && sudo mv splash.png splash.png.bk", step, total_steps, "Backing up original splash.png...")
    run_shell_command("sudo cp /home/Automata/splash.png /usr/share/plymouth/themes/pix/", step, total_steps, "Copying Automata splash.png to Plymouth theme...")
    sleep(2)
    step += 1
    update_progress(step, total_steps, "Splash logo move successful!")

    # Step 3: Overclock the Raspberry Pi
    run_shell_command("echo -e 'over_voltage=2\narm_freq=1750' | sudo tee -a /boot/config.txt", step, total_steps, "Overclocking CPU...Turbo mode engaged!")
    sleep(5)
    step += 1

    # Step 4: Create LXDE wallpaper config file with "Fill" mode
    run_shell_command("mkdir -p /home/Automata/.config/pcmanfm/LXDE-pi", step, total_steps, "Creating LXDE config directory...")
    run_shell_command("cat <<EOL > /home/Automata/.config/pcmanfm/LXDE-pi/desktop-items-0.conf\n[*]\nwallpaper=/home/Automata/splash.png\nwallpaper_mode=stretch\nEOL", step, total_steps, "Setting wallpaper to Fill mode in LXDE config...")
    sleep(2)
    step += 1

    # Step 5: Increase swap size
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", step, total_steps, "Increasing swap size...")
    sleep(5)
    step += 1

    # Step 6: Clone Sequent Microsystems drivers
    boards_to_clone = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards_to_clone:
        run_shell_command(f"git clone https://github.com/sequentmicrosystems/{board}.git /home/Automata/AutomataBuildingManagment-HvacController/{board}", step, total_steps, f"Cloning {board}...")
        update_progress(step, total_steps, f"{board} cloned successfully!")
        sleep(3.5)
        step += 1

    # Step 7: Install Sequent Microsystems drivers
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards:
        board_path = f"/home/Automata/AutomataBuildingManagment-HvacController/{board}"
        if os.path.isdir(board_path):
            run_shell_command(f"cd {board_path} && sudo make install", step, total_steps, f"Installing {board} driver...")
            update_progress(step, total_steps, f"{board} driver installed successfully!")
            step += 1
        else:
            update_progress(step, total_steps, f"Board {board} not found, skipping...")
            step += 1
        sleep(5)

    # Step 8: Install Node-RED theme package and fix the missing theme issue
    run_shell_command("mkdir -p /home/Automata/.node-red/node_modules/@node-red-contrib-themes/theme-collection/themes", step, total_steps, "Creating theme collection directory...")
    run_shell_command("cd /home/Automata/.node-red && npm install @node-red-contrib-themes/theme-collection", step, total_steps, "Installing Node-RED theme package...")
    sleep(5)
    step += 1

    # Step 9: Install Node-RED
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh", step, total_steps, "Installing Node-RED...")
    update_progress(step, total_steps, "Node-RED Security Measures initiated...")
    sleep(5)
    
    # Reflect Node-RED security setup
    update_progress(step, total_steps, "Setting up Node-RED security...")
    sleep(2)  # Simulate security setup time
    update_progress(step, total_steps, "Node-RED User and Password Security & VPN setup Successful!\n Welcome Automata.")
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
threading.Thread(target=run_installation_steps).start()

# Start spinner animation in a separate thread
threading.Thread(target=spin_animation, daemon=True).start()

# Tkinter main loop to keep the GUI running
root.mainloop()

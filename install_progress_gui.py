import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
from time import sleep

# Function to run shell commands and update progress
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        root.update_idletasks()
        print(f"Error output: {result.stderr}")
    else:
        print(f"Command output: {result.stdout}")

def run_installation_steps():
    total_steps = 12

    # Step 1: Disabling screen blanking
    run_shell_command("sudo raspi-config nonint do_blanking 1", 1, total_steps, "Disabling screen blanking...")
    sleep(2)

    # Step 2: Setting system time
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", 2, total_steps, "Setting system time...")
    sleep(2)

    # Step 3: Installing Sequent Microsystems drivers
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    step = 3
    for board in boards:
        if os.path.isdir(f"/home/Automata/AutomataBuildingManagment-HvacController/{board}"):
            run_shell_command(f"cd /home/Automata/AutomataBuildingManagment-HvacController/{board} && sudo make install", step, total_steps, f"Installing {board} driver...")
        else:
            update_progress(step, total_steps, f"{board} driver not found, skipping...")
        step += 1

    # Step 4: Installing Node-RED
    run_shell_command("gnome-terminal -- bash -c 'bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh; exec bash'", step, total_steps, "Installing Node-RED interactively...")
    sleep(2)

    # Step 5: Installing Node-RED palettes
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh", step, total_steps, "Installing Node-RED palettes...")
    sleep(2)

    # Step 6: Moving splash screen
    run_shell_command("sudo mv /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/splash.png", step, total_steps, "Moving splash.png...")
    sleep(2)

    # Step 7: Setting splash screen
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_boot_splash_screen.sh", step, total_steps, "Setting boot splash screen...")
    sleep(2)

    # Step 8: Configuring interfaces (i2c, spi, vnc, etc.)
    run_shell_command("sudo raspi-config nonint do_i2c 0 && sudo raspi-config nonint do_spi 0 && sudo raspi-config nonint do_vnc 0 && sudo raspi-config nonint do_onewire 0 && sudo raspi-config nonint do_serial 1", step, total_steps, "Configuring interfaces...")
    sleep(2)

    # Step 9: Installing Mosquitto
    run_shell_command("sudo apt-get install -y mosquitto mosquitto-clients", step, total_steps, "Installing Mosquitto...")
    run_shell_command("sudo touch /etc/mosquitto/passwd && sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2", step, total_steps, "Setting Mosquitto password file...")
    sleep(2)

    # Step 10: Increasing swap size
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", step, total_steps, "Increasing swap size...")
    sleep(2)

    # Final step: Installation complete
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# Function to update the progress bar
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Function to show the reboot prompt
def show_reboot_prompt():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Installation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata Building Management & HVAC Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="A New Realm of Automation Awaits!\nDeveloped by A. Jewell Sr., Automata Controls in Collaboration With Current Mechanical.\nPlease reboot to finalize settings and config files.\n\nReboot Now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e", wraplength=500)
    final_message.pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

# Tkinter window setup
root = tk.Tk()
root.title("Initializing Automata Configuration and Startup")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

label = tk.Label(root, text="Initializing Automata Configuration and Startup", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

status_label = tk.Label(root, text="Starting installation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Start the installation steps in a separate thread to keep the GUI responsive
threading.Thread(target=run_installation_steps, daemon=True).start()

root.mainloop()

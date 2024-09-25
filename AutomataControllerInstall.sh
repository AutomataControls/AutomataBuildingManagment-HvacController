#!/bin/bash

# Step 1: Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Re-running with sudo..."
    sudo bash "$0" "$@"
    exit
fi

# Step 2: Log file setup
LOGFILE="/home/Automata/install_log.txt"
exec > >(tee -i "$LOGFILE") 2>&1
echo "Installation started at: $(date)"

# Step 3: Start the installation GUI before any installation steps
echo "Starting installation GUI..."
INSTALL_GUI="/home/Automata/install_progress_gui.py"

# Create the Python GUI script for installation progress
cat << 'EOF' > $INSTALL_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
from time import sleep

# Create the main window
root = tk.Tk()
root.title("Automata Installation Progress")

# Set window size and position
root.geometry("600x400")
root.configure(bg='#2e2e2e')  # Dark grey background

# Title message
label = tk.Label(root, text="Automata Installation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting installation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Update progress function
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

# Function to run shell commands in a separate thread
def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    result = subprocess.Popen(command, shell=True).wait()
    if result != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        root.update_idletasks()

def run_installation_steps():
    total_steps = 12

    # Step 1: Disable screen blanking
    run_shell_command("sudo raspi-config nonint do_blanking 1", 1, total_steps, "Disabling screen blanking...")
    sleep(5)

    # Step 2: Set Internet Time with Eastern Standard Time
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", 2, total_steps, "Setting system time to Eastern Standard Time...")
    sleep(5)

    # Step 3: Install Sequent Microsystems drivers
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh", 3, total_steps, "Installing Sequent Microsystems drivers...")
    sleep(5)

    # Step 4: Install Node-RED interactively with prompts
    run_shell_command("lxterminal -e 'bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh'", 4, total_steps, "Installing Node-RED interactively with prompts...")
    sleep(5)

    # Step 5: Install Node-RED palettes
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh", 5, total_steps, "Installing Node-RED palettes...")
    sleep(5)

    # Step 6: Move splash.png and set it as wallpaper and splash screen
    run_shell_command("sudo mv /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/splash.png", 6, total_steps, "Moving splash.png to /home/Automata...")
    sleep(5)

    # Set splash.png as wallpaper and splash screen
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_full_logo_image_rpi4.sh", 6, total_steps, "Setting splash.png as wallpaper and splash screen...")
    sleep(5)

    # Step 7: Enable I2C, SPI, RealVNC, 1-Wire, disable serial port
    run_shell_command("sudo raspi-config nonint do_i2c 0 && sudo raspi-config nonint do_spi 0 && sudo raspi-config nonint do_vnc 0 && sudo raspi-config nonint do_onewire 0 && sudo raspi-config nonint do_serial 1", 7, total_steps, "Enabling I2C, SPI, RealVNC, disabling serial port...")
    sleep(5)

    # Step 8: Install Mosquitto and set password file
    run_shell_command("sudo apt-get install -y mosquitto mosquitto-clients", 8, total_steps, "Installing Mosquitto...")
    run_shell_command("sudo mkdir -p /etc/mosquitto && sudo touch /etc/mosquitto/passwd && sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2", 8, total_steps, "Setting Mosquitto password file...")
    sleep(5)

    # Step 9: Increase swap size
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", 9, total_steps, "Increasing swap size...")
    sleep(5)

    # Step 10: Ensure autostart directory exists and add auto-start entry
    run_shell_command("mkdir -p /home/Automata/.config/lxsession/LXDE-pi && echo '@/home/Automata/update_sequent_boards.sh' >> /home/Automata/.config/lxsession/LXDE-pi/autostart", 10, total_steps, "Ensuring autostart directory exists and adding board update auto-start...")
    sleep(5)

    # Step 11: Installation complete
    update_progress(11, total_steps, "Installation complete. Please reboot.")

    # Show final message after reboot
    show_reboot_prompt()

# Function to show final reboot prompt
def show_reboot_prompt():
    root.withdraw()  # Hide the main window
    final_window = tk.Tk()
    final_window.title("Installation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata Building Management & HVAC Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="A New Realm of Automation Awaits!\nPlease reboot to finalize settings and config files.\n\nReboot Now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    final_message.pack(pady=20)

    # Reboot and Exit buttons
    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: subprocess.Popen('sudo reboot', shell=True), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

# Start the installation in a separate thread to keep GUI responsive
threading.Thread(target=run_installation_steps).start()

# Tkinter loop runs in the background while install runs
root.mainloop()
EOF

# Step 4: Start the Tkinter GUI in the background
sleep 15  # Ensures that desktop and GUI are fully loaded
python3 $INSTALL_GUI &



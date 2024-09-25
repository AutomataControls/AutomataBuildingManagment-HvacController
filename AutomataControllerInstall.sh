#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Function to handle errors
handle_error() {
    log "Error occurred in line $1"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Step 1: Ensure the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root. Re-running with sudo..."
    sudo bash "$0" "$@"
    exit
fi

# Step 2: Log file setup
LOGFILE="/home/Automata/install_log.txt"
log "Installation started"

# Step 3: Install necessary dependencies
log "Updating package lists and installing dependencies..."
apt-get update
apt-get install -y python3-tk python3-pil python3-pil.imagetk mosquitto mosquitto-clients chromium-browser lxterminal

# Step 4: Set permissions for necessary files
log "Setting permissions for necessary files..."
find /home/Automata -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
find /home/Automata -type f -name "*.png" -exec chmod +r {} \;

# Include the repository directory for setting permissions
REPO_DIR="/home/Automata/AutomataBuildingManagment-HvacController"
if [ -d "$REPO_DIR" ]; then
    log "Setting permissions for files in repository directory..."
    find "$REPO_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
    find "$REPO_DIR" -type f -name "*.png" -exec chmod +r {} \;
fi

# Step 5: Stop lingering services
for service in nodered mosquitto; do
    if systemctl is-active --quiet $service; then
        log "Stopping $service service..."
        systemctl stop $service
    fi
done

# Step 6: Create and run the installation progress GUI
log "Starting installation GUI..."
INSTALL_GUI="/home/Automata/install_progress_gui.py"

# Create the Python GUI script for installation progress
cat << 'EOF' > $INSTALL_GUI
import tkinter as tk
from tkinter import ttk
import subprocess
import threading
from time import sleep

root = tk.Tk()
root.title("Automata Installation Progress")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

label = tk.Label(root, text="Automata Installation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

status_label = tk.Label(root, text="Starting installation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

def run_shell_command(command, step, total_steps, message):
    update_progress(step, total_steps, message)
    result = subprocess.Popen(command, shell=True).wait()
    if result != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        root.update_idletasks()

def run_installation_steps():
    total_steps = 12

    run_shell_command("sudo raspi-config nonint do_blanking 1", 1, total_steps, "Disabling screen blanking...")
    sleep(5)

    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", 2, total_steps, "Setting system time to Eastern Standard Time...")
    sleep(5)

    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh", 3, total_steps, "Installing Sequent Microsystems drivers...")
    sleep(5)

    run_shell_command("lxterminal -e 'bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh'", 4, total_steps, "Installing Node-RED interactively with prompts...")
    sleep(5)

    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh", 5, total_steps, "Installing Node-RED palettes...")
    sleep(5)

    run_shell_command("sudo mv /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/splash.png", 6, total_steps, "Moving splash.png to /home/Automata...")
    sleep(5)

    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_full_logo_image_rpi4.sh", 6, total_steps, "Setting splash.png as wallpaper and splash screen...")
    sleep(5)

    run_shell_command("sudo raspi-config nonint do_i2c 0 && sudo raspi-config nonint do_spi 0 && sudo raspi-config nonint do_vnc 0 && sudo raspi-config nonint do_onewire 0 && sudo raspi-config nonint do_serial 1", 7, total_steps, "Enabling I2C, SPI, RealVNC, disabling serial port...")
    sleep(5)

    run_shell_command("sudo apt-get install -y mosquitto mosquitto-clients", 8, total_steps, "Installing Mosquitto...")
    run_shell_command("sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2", 8, total_steps, "Setting Mosquitto password file...")
    sleep(5)

    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", 9, total_steps, "Increasing swap size...")
    sleep(5)

    update_progress(11, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

def show_reboot_prompt():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Installation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata Building Management & HVAC Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="A New Realm of Automation Awaits!\nDeveloped by A. Jewell Sr., Automata Controls in Collaboration With Current Mechanical.\nPlease reboot to finalize settings and config files.\n\nReboot Now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    final_message.pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: subprocess.Popen('sudo reboot', shell=True), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

threading.Thread(target=run_installation_steps).start()
root.mainloop()
EOF

# Ensure that the GUI script has execute permissions
chmod +x $INSTALL_GUI

# Step 7: Set up Chromium Auto-launch
log "Setting up Chromium auto-launch..."
AUTO_LAUNCH_SCRIPT="/home/Automata/launch_chromium.py"

cat << 'EOF' > $AUTO_LAUNCH_SCRIPT
import time
import subprocess

# Wait for the network to connect
while True:
    try:
        subprocess.check_call(['ping', '-c', '1', '127.0.0.1'])
        break
    except subprocess.CalledProcessError:
        time.sleep(1)

# Wait additional time for services to load
time.sleep(15)

# Launch Chromium in windowed mode
subprocess.Popen(['chromium-browser', '--disable-features=KioskMode', '--new-window', 'http://127.0.0.1:1880/', 'http://127.0.0.1:1880/ui'])
EOF

# Create systemd service for Chromium auto-launch
cat << 'EOF' > /etc/systemd/system/chromium-launch.service
[Unit]
Description=Auto-launch Chromium at boot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/Automata/launch_chromium.py
User=Automata
Environment=DISPLAY=:0
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable chromium-launch.service

log "Installation completed. You may reboot to finalize settings."

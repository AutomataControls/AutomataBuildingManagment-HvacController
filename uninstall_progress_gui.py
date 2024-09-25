import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os  # Ensure os module is imported for directory checking

# Create the main window
root = tk.Tk()
root.title("Automata Uninstallation Progress")

# Set window size and position
root.geometry("600x400")
root.configure(bg='#2e2e2e')  # Dark grey background

# Title message
label = tk.Label(root, text="Automata Uninstallation Progress", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
label.pack(pady=20)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting uninstallation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
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

def run_uninstallation_steps():
    total_steps = 7

    # Step 1: Stop and remove Mosquitto service and user credentials
    run_shell_command("sudo systemctl stop mosquitto && sudo systemctl disable mosquitto && sudo apt-get remove --purge -y mosquitto mosquitto-clients && sudo rm -f /etc/mosquitto/passwd && sudo rm -f /etc/mosquitto/mosquitto.conf", 1, total_steps, "Removing Mosquitto...")

    # Step 2: Restore the default swap size
    run_shell_command("sudo dphys-swapfile swapoff && sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=100/' /etc/dphys-swapfile && sudo dphys-swapfile setup && sudo dphys-swapfile swapon", 2, total_steps, "Restoring default swap size...")

    # Step 3: Remove Node-RED and related services
    run_shell_command("sudo systemctl stop nodered && sudo systemctl disable nodered && sudo apt-get remove --purge -y nodered", 3, total_steps, "Removing Node-RED...")

    # Step 4: Remove Sequent Microsystems drivers
    drivers = [
        "/home/Automata/AutomataBuildingManagment-HvacController/megabas-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/megaind-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/16univin-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/16relind-rpi",
        "/home/Automata/AutomataBuildingManagment-HvacController/8relind-rpi"
    ]
    for step, driver in enumerate(drivers, start=4):
        if os.path.isdir(driver):  # Check if directory exists
            run_shell_command(f"cd {driver} && sudo make uninstall", step, total_steps, f"Removing {driver} driver...")

    # Step 5: Disable I2C, SPI, VNC, 1-Wire, Remote GPIO, and SSH
    run_shell_command("sudo raspi-config nonint do_i2c 1 && sudo raspi-config nonint do_spi 1 && sudo raspi-config nonint do_vnc 1 && sudo raspi-config nonint do_onewire 1 && sudo raspi-config nonint do_rgpio 1 && sudo raspi-config nonint do_ssh 1 && sudo raspi-config nonint do_serial 0", 5, total_steps, "Disabling interfaces and enabling serial port...")

    # Step 6: Remove Node-RED desktop icon
    run_shell_command("rm -f /home/Automata/Desktop/NodeRed.desktop", 6, total_steps, "Removing Node-RED desktop icon...")

    # Step 7: Remove the cloned repository directory
    run_shell_command("sudo rm -rf /home/Automata/AutomataBuildingManagment-HvacController", 7, total_steps, "Removing repository directory...")

    # Show final message after uninstallation
    show_uninstall_complete_message()

# Function to show final uninstallation message and reboot prompt
def show_uninstall_complete_message():
    root.withdraw()  # Hide the main window
    final_window = tk.Tk()
    final_window.title("Uninstallation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata BMS Uninstallation Complete", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="Uninstallation Successful.\nWould you like to reboot the system now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
    final_message.pack(pady=20)

    # Reboot and Exit buttons
    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: subprocess.Popen('sudo reboot', shell=True), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

# Run uninstallation steps in a separate thread to keep GUI responsive
threading.Thread(target=run_uninstallation_steps).start()

# Tkinter loop runs in the background while uninstallation runs
root.mainloop()

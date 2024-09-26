import tkinter as tk
from tkinter import ttk
import subprocess
import threading
from time import sleep

# Function to update progress in the GUI
def update_progress(step, total_steps, message):
    progress['value'] = (step / total_steps) * 100
    status_label.config(text=message)
    root.update_idletasks()

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
    sleep(2)  # Ensure each step completes before moving to the next

# Function to run the entire installation process step by step
def run_installation_steps():
    total_steps = 12
    
    # Update the GUI with the welcome message
    update_progress(0, total_steps, "Welcome to the Automata Installation. Preparing to start...")

    # Example of overclocking the Raspberry Pi
    run_shell_command("echo 'over_voltage=2\narm_freq=1750' >> /boot/config.txt", 1, total_steps, "Overclocking CPU... Turning up to 11 Meow!")

    # Disable screen blanking
    run_shell_command("sudo raspi-config nonint do_blanking 1", 2, total_steps, "Disabling screen blanking...")

    # Install dependencies
    run_shell_command("sudo apt-get install -y python3-tk python3-pil python3-pil.imagetk", 3, total_steps, "Installing dependencies...")

    # Clone Sequent MS repositories
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/SequentMSInstall.sh", 4, total_steps, "Cloning Sequent MS repositories...")

    # Install Sequent MS board drivers
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    step = 5
    for board in boards:
        if subprocess.run(f"test -d /home/Automata/AutomataBuildingManagment-HvacController/{board}", shell=True).returncode == 0:
            run_shell_command(f"cd /home/Automata/AutomataBuildingManagment-HvacController/{board} && sudo make install", step, total_steps, f"Installing {board} driver...")
        else:
            update_progress(step, total_steps, f"Board {board} not found, skipping...")
        step += 1

    # Install Node-RED
    run_shell_command("gnome-terminal -- bash -c 'bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh; exec bash'", step, total_steps, "Installing Node-RED interactively...")
    step += 1

    # Install Node-RED palettes
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh", step, total_steps, "Installing Node-RED palettes...")

    # Final step: installation complete
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# Function to show the reboot prompt after installation completes
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

# GUI setup
root = tk.Tk()
root.title("Automata Installation Progress")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

# Welcome message
welcome_label = tk.Label(root, text="Automata Building Management & HVAC Controller Installer", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
welcome_label.pack(pady=10)

# Progress bar
progress = ttk.Progressbar(root, orient="horizontal", length=500, mode="determinate")
progress.pack(pady=20)

# Status message
status_label = tk.Label(root, text="Starting installation...", font=("Helvetica", 12), fg="orange", bg="#2e2e2e")
status_label.pack(pady=10)

# Footer with your custom message
footer_label = tk.Label(root, text="Developed by A. Jewell Sr., Automata Controls, 2023", font=("Helvetica", 10), fg="#00b3b3", bg="#2e2e2e")
footer_label.pack(side="bottom", pady=10)

# Run the installation steps in a separate thread
threading.Thread(target=run_installation_steps, daemon=True).start()

# Run the Tkinter loop
root.mainloop()


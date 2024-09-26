import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
from time import sleep

# Create the main installation window
root = tk.Tk()
root.title("Automata Installer")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

# Installation GUI screen
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
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        status_label.config(text=f"Error during: {message}. Check logs for details.")
        root.update_idletasks()
    sleep(2)

def run_installation_steps():
    total_steps = 20  # Adjust total steps according to the number of installation tasks
    step = 1

    # Step 1: Set Timezone
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", step, total_steps, "Setting system time to EST...")
    step += 1

    # Step 2: Install Sequent Microsystems Drivers
    boards = ["megabas-rpi", "megaind-rpi", "16univin-rpi", "16relind-rpi", "8relind-rpi"]
    for board in boards:
        if os.path.isdir(f"/home/Automata/AutomataBuildingManagment-HvacController/{board}"):
            run_shell_command(f"cd /home/Automata/AutomataBuildingManagment-HvacController/{board} && sudo make install", step, total_steps, f"Installing Sequent MS driver for {board}...")
            status_label.config(text=f"Make install for {board} succeeded!")
        else:
            status_label.config(text=f"Board {board} not found, skipping...")
        step += 1

    # Step 3: Node-RED Installation
    run_shell_command("gnome-terminal -- bash -c 'bash /home/Automata/AutomataBuildingManagment-HvacController/install_node_red.sh; exec bash'", step, total_steps, "Installing Node-RED interactively...")
    step += 1

    # Step 4: Node-RED Palettes Installation
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/InstallNodeRedPallete.sh", step, total_steps, "Installing Node-RED palettes...")
    step += 1

    # Step 5: Move Splash Screen
    run_shell_command("sudo mv /home/Automata/AutomataBuildingManagment-HvacController/splash.png /home/Automata/splash.png", step, total_steps, "Moving splash screen...")
    step += 1

    # Step 6: Set Boot Splash Screen
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_boot_splash_screen.sh", step, total_steps, "Setting boot splash screen...")
    step += 1

    # Step 7: Configure Interfaces
    run_shell_command("sudo raspi-config nonint do_i2c 0 && sudo raspi-config nonint do_spi 0 && sudo raspi-config nonint do_vnc 0 && sudo raspi-config nonint do_onewire 0 && sudo raspi-config nonint do_serial 1", step, total_steps, "Configuring interfaces...")
    step += 1

    # Step 8: Mosquitto Installation
    run_shell_command("sudo apt-get install -y mosquitto mosquitto-clients", step, total_steps, "Installing Mosquitto...")
    run_shell_command("sudo touch /etc/mosquitto/passwd && sudo mosquitto_passwd -b /etc/mosquitto/passwd Automata Inverted2", step, total_steps, "Setting Mosquitto password file...")
    step += 1

    # Step 9: Increase Swap Size
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", step, total_steps, "Increasing swap size...")
    step += 1

    # Final Step: Complete Installation
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

def show_reboot_prompt():
    root.withdraw()
    final_window = tk.Tk()
    final_window.title("Installation Complete")
    final_window.geometry("600x400")
    final_window.configure(bg='#2e2e2e')

    final_label = tk.Label(final_window, text="Automata Building Management & HVAC Controller", font=("Helvetica", 18, "bold"), fg="#00b3b3", bg="#2e2e2e")
    final_label.pack(pady=20)

    final_message = tk.Label(final_window, text="A New Realm of Automation Awaits!\nPlease reboot to finalize settings and config files.\n\nReboot Now?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e", wraplength=500)
    final_message.pack(pady=20)

    button_frame = tk.Frame(final_window, bg='#2e2e2e')
    button_frame.pack(pady=20)

    reboot_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=lambda: os.system('sudo reboot'), bg='#00b3b3', fg="black", width=10)
    reboot_button.grid(row=0, column=0, padx=10)

    exit_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=final_window.destroy, bg='orange', fg="black", width=10)
    exit_button.grid(row=0, column=1, padx=10)

    final_window.mainloop()

# Start the installation steps
threading.Thread(target=run_installation_steps, daemon=True).start()

# Footer
footer_label = tk.Label(root, text="Developed by A. Jewell Sr, 2023", font=("Helvetica", 10), fg="gray", bg="#2e2e2e")
footer_label.pack(side="bottom", pady=10)

root.mainloop()


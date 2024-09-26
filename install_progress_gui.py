import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
from time import sleep

root = tk.Tk()
root.title("Automata Installer")
root.geometry("600x400")
root.configure(bg='#2e2e2e')

def run_installation():
    # Close the welcome screen
    welcome_window.destroy()

    # Proceed with the normal installation steps

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
        subprocess.run(command, shell=True)

    def run_installation_steps():
        total_steps = 15
        step = 1

        # Example installation steps (replace with your real steps)
        run_shell_command("sudo raspi-config nonint do_blanking 1", step, total_steps, "Disabling screen blanking...")
        sleep(2)
        step += 1

        run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", step, total_steps, "Setting system time...")
        sleep(2)
        step += 1

        # Add more installation steps as needed here

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

    threading.Thread(target=run_installation_steps, daemon=True).start()

def exit_installer():
    welcome_window.destroy()
    root.destroy()

# Welcome Screen
welcome_window = tk.Toplevel(root)
welcome_window.title("Welcome to Automata Installer")
welcome_window.geometry("600x400")
welcome_window.configure(bg='#2e2e2e')

welcome_label = tk.Label(welcome_window, text="Welcome to Automata Building Management & HVAC Controller Installer", font=("Helvetica", 16, "bold"), fg="#00b3b3", bg="#2e2e2e", wraplength=550)
welcome_label.pack(pady=40)

prompt_label = tk.Label(welcome_window, text="Do you want to proceed with the installation?", font=("Helvetica", 14), fg="orange", bg="#2e2e2e")
prompt_label.pack(pady=20)

button_frame = tk.Frame(welcome_window, bg='#2e2e2e')
button_frame.pack(pady=20)

yes_button = tk.Button(button_frame, text="Yes", font=("Helvetica", 12), command=run_installation, bg='#00b3b3', fg="black", width=10)
yes_button.grid(row=0, column=0, padx=10)

no_button = tk.Button(button_frame, text="No", font=("Helvetica", 12), command=exit_installer, bg='orange', fg="black", width=10)
no_button.grid(row=0, column=1, padx=10)

# Footer
footer_label = tk.Label(welcome_window, text="Developed by A. Jewell Sr, 2023", font=("Helvetica", 10), fg="gray", bg="#2e2e2e")
footer_label.pack(side="bottom", pady=10)

root.mainloop()


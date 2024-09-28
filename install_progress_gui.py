# ... (previous parts of the script remain unchanged)

def run_installation_steps():
    total_steps = 33  # Adjusted total steps (removed 1 step for wallpaper setup)
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

    # New Step 4: Set Internet Time
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/set_internet_time_rpi4.sh", step, total_steps, "Setting internet time...")
    sleep(5)
    step += 1

    # Step 5: Increase swap size
    run_shell_command("bash /home/Automata/AutomataBuildingManagment-HvacController/increase_swap_size.sh", step, total_steps, "Increasing swap size...")
    sleep(5)
    step += 1

    # ... (rest of the steps remain unchanged)

    # Final Step: Installation complete
    update_progress(total_steps, total_steps, "Installation complete. Please reboot.")
    show_reboot_prompt()

# ... (rest of the script remains unchanged)

import subprocess
import time
import os

# First, call the board update script which has its own GUI
def run_board_update():
    update_script = "/home/Automata/AutomataBuildingManagment-HvacController/update_sequent_boards.sh"
    if os.path.isfile(update_script):
        print("Running board update script...")
        result = subprocess.run([update_script], check=True)
        return result.returncode == 0  # Returns True if successful
    else:
        print(f"Board update script {update_script} not found!")
        return False

# Function to enable and start the Node-RED service
def enable_start_node_red():
    print("Enabling and starting Node-RED service...")
    try:
        # Enable Node-RED service to start on boot
        subprocess.run(["sudo", "systemctl", "enable", "nodered.service"], check=True)
        # Start Node-RED service immediately
        subprocess.run(["sudo", "systemctl", "start", "nodered.service"], check=True)
        print("Node-RED service started successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to start Node-RED service: {e}")

# Function to launch Chromium in windowed mode after updates
def launch_chromium():
    print("Waiting for network connectivity...")
    
    # Wait for the network to connect
    while True:
        try:
            subprocess.check_call(['ping', '-c', '1', '127.0.0.1'])
            break
        except subprocess.CalledProcessError:
            time.sleep(1)

    # Wait additional time for services to load
    print("Waiting for services to load...")
    time.sleep(15)

    # Launch Chromium in windowed mode
    print("Launching Chromium...")
    subprocess.Popen(['chromium-browser', '--new-window', 'http://127.0.0.1:1880/', 'http://127.0.0.1:1880/ui'])

# Main execution
if __name__ == "__main__":
    # Run board update process first
    if run_board_update():
        # If at least one board update succeeded, enable and start Node-RED service
        enable_start_node_red()
    else:
        print("No boards were updated successfully. Skipping Node-RED service start.")

    # Then launch Chromium
    launch_chromium()

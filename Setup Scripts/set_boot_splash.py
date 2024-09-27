import subprocess
import os

def set_splash_screen():
    # Define the paths
    splash_screen_src = "/home/Automata/splash.png"
    splash_screen_dst = "./splash.png"
    backup_dst = "./splash.png.bk"

    try:
        # Backup the current splash screen
        if os.path.exists(splash_screen_dst):
            subprocess.run(f"sudo mv {splash_screen_dst} {backup_dst}", shell=True, check=True)
            print(f"Backed up current splash screen to {backup_dst}")
        
        # Copy the new splash screen
        if os.path.exists(splash_screen_src):
            subprocess.run(f"sudo cp {splash_screen_src} {splash_screen_dst}", shell=True, check=True)
            print(f"New splash screen set from {splash_screen_src} to {splash_screen_dst}")
        else:
            print(f"Source splash screen {splash_screen_src} not found")
    
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while setting the splash screen: {e}")
        return False

    return True

if __name__ == "__main__":
    success = set_splash_screen()
    if success:
        print("Splash screen updated successfully!")
    else:
        print("Failed to update the splash screen.")

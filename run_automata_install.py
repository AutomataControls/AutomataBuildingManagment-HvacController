import subprocess
import sys
import os

def main():
    # Path to the shell script to be executed
    script_path = "AutomataControllerInstall.sh"
    
    # Check if the script exists
    if not os.path.isfile(script_path):
        print(f"Error: {script_path} not found.")
        sys.exit(1)

    # Run the shell script using subprocess
    try:
        result = subprocess.run(["bash", script_path], check=True)
        if result.returncode == 0:
            print(f"Successfully executed {script_path}")
        else:
            print(f"Error: {script_path} exited with code {result.returncode}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to execute {script_path}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

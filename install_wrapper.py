import subprocess
import sys

def main():
    # Define the shell script to be executed
    script = "AutomataControllerInstall.sh"

    try:
        # Run the shell script using subprocess
        result = subprocess.run(["bash", script], check=True)
        if result.returncode == 0:
            print(f"Successfully executed {script}")
        else:
            print(f"Error: {script} exited with code {result.returncode}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to execute {script}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

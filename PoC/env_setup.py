"""
Virtual environment setup and management utilities.
This module must be executed at the very beginning to ensure dependencies are available.
"""

import os
import sys
import subprocess
import platform


VENV_DIR = ".venv"
REQUIRED_PACKAGES = ["requests", "bs4"]
FLAG = "--inside-venv"


def get_venv_python() -> str:
    """Return the path to the venv python interpreter for the current platform."""
    if platform.system().lower() == "windows":
        return os.path.join(VENV_DIR, "Scripts", "python.exe")
    else:
        return os.path.join(VENV_DIR, "bin", "python")


def is_in_venv() -> bool:
    """Check if currently running inside the virtual environment."""
    return FLAG in sys.argv


def ensure_venv(required_packages: list[str] = None) -> None:
    """
    Create and activate venv if not already running inside it.
    Restarts the script inside the venv if necessary.
    
    Args:
        required_packages: List of pip packages to install. Defaults to REQUIRED_PACKAGES.
    """
    if required_packages is None:
        required_packages = REQUIRED_PACKAGES
    
    # If already in venv, nothing to do
    if is_in_venv():
        return
    
    # Create venv if it doesn't exist
    if not os.path.exists(VENV_DIR):
        print("⚙️  Creating virtual environment...")
        try:
            subprocess.run([sys.executable, "-m", "venv", VENV_DIR], check=True)
            print("✅ Virtual environment created")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to create virtual environment: {e}")
            sys.exit(1)
    
    # Install dependencies
    venv_python = get_venv_python()
    print("📦 Installing dependencies...")
    try:
        cmd = [venv_python, "-m", "pip", "install", "-q", "-U", "pip"] + required_packages
        subprocess.run(cmd, check=True)
        print("✅ Dependencies installed")
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to install dependencies: {e}")
        sys.exit(1)
    
    # Restart inside venv
    print("🚀 Restarting inside virtual environment...\n")
    os.execv(venv_python, [venv_python] + sys.argv + [FLAG])

#!/usr/bin/env python3
"""
Raspundel Istetel Updater - Main Entry Point

Professional tool for managing .bnl files for Raspunde Istetel pens.
Automatically downloads content from the website and syncs to USB drives.

Usage:
    python main.py download [--force]     Download missing files from website
    python main.py update [--dry-run]     Sync files to USB drive
    python main.py sync [--dry-run]       Download + update in one step
"""

import sys

# CRITICAL: Setup venv FIRST before any other imports
import env_setup
env_setup.ensure_venv()

# Now safe to import other modules (which may need installed packages)
import commands


def print_usage():
    """Print usage information."""
    print(__doc__)
    print("\nExamples:")
    print("  python main.py download          # Download new files only")
    print("  python main.py download --force  # Re-download all files")
    print("  python main.py update            # Sync to USB")
    print("  python main.py update --dry-run  # Preview USB changes")
    print("  python main.py sync              # Download + Update")
    print("  python main.py sync --dry-run    # Download + Preview update")


def main():
    """Main entry point - parse arguments and dispatch to command handlers."""
    args = sys.argv[1:]
    
    # Remove the venv flag if present (added by env_setup)
    args = [arg for arg in args if arg != env_setup.FLAG]
    
    if not args or args[0] in ['-h', '--help', 'help']:
        print_usage()
        return 0
    
    command = args[0]
    flags = args[1:]
    
    # Parse common flags
    force = '--force' in flags
    dry_run = '--dry-run' in flags
    
    # Dispatch to command handlers
    if command == 'download':
        return commands.cmd_download(force=force)
    elif command == 'update':
        return commands.cmd_update(dry_run=dry_run)
    elif command == 'sync':
        return commands.cmd_sync(dry_run=dry_run)
    else:
        print(f"❌ Unknown command: {command}\n")
        print_usage()
        return 1


if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)

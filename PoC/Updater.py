import os
import sys
import glob
import shutil
import platform

def find_usb_drive_windows():
    """Find first USB drive containing .bnl files on Windows"""
    from ctypes import windll
    bitmask = windll.kernel32.GetLogicalDrives()
    
    for letter in range(65, 91):  # A-Z
        if bitmask & (1 << (letter - 65)):
            drive = f"{chr(letter)}:\\"
            if os.path.exists(drive):
                bnl_files = glob.glob(os.path.join(drive, "*.bnl"))
                if bnl_files:
                    return drive
    return None

def find_usb_drive_linux():
    """Find first USB drive containing .bnl files on Linux"""
    mount_points = [
        "/media",        # Ubuntu-style
        "/run/media",    # Arch-style
        "/mnt"          # General mount point
    ]
    
    for base in mount_points:
        if not os.path.exists(base):
            continue
            
        # Check user-specific mounts first
        user_mounts = []
        if os.path.exists(os.path.join(base, os.getenv('USER', ''))):
            user_mounts = [os.path.join(base, os.getenv('USER', ''), d) 
                         for d in os.listdir(os.path.join(base, os.getenv('USER', '')))]
        
        # Check direct mounts
        direct_mounts = []
        if os.path.exists(base):
            direct_mounts = [os.path.join(base, d) for d in os.listdir(base)]
            
        # Combine and check all potential mount points
        for mount in user_mounts + direct_mounts:
            if os.path.ismount(mount):
                bnl_files = glob.glob(os.path.join(mount, "*.bnl"))
                if bnl_files:
                    return mount
    return None

def find_usb_drive():
    """Find USB drive based on operating system"""
    system = platform.system().lower()
    if system == 'windows':
        return find_usb_drive_windows()
    elif system == 'linux':
        return find_usb_drive_linux()
    else:
        print(f"❌ Unsupported operating system: {system}")
        sys.exit(1)

def sync_files(usb_path, download_dir):
    """Sync files between download directory and USB drive"""
    # Get lists of files
    local_files = {os.path.basename(f) for f in glob.glob(os.path.join(download_dir, "*.bnl"))}
    usb_files = {os.path.basename(f) for f in glob.glob(os.path.join(usb_path, "*.bnl"))}
    
    if not local_files:
        print("❌ No .bnl files found in downloads directory!")
        return False
        
    # Files to remove (on USB but not in downloads)
    to_remove = usb_files - local_files
    # Files to copy (in downloads but not on USB)
    to_copy = local_files - usb_files
    
    print(f"\n📊 Status:")
    print(f"Found {len(local_files)} files in downloads")
    print(f"Found {len(usb_files)} files on USB")
    
    print(f"Files to remove: {len(to_remove)}")
    if to_remove:
        print("\n🗑️  Files to be removed:")
        for file in sorted(to_remove):
            print(f"   - {file}")
    
    print(f"\n\nFiles to copy: {len(to_copy)}")
    if to_copy:
        print("\n📥 Files to be copied:")
        for file in sorted(to_copy):
            print(f"   - {file}")
            
    if not (to_remove or to_copy):
        print("\n✅ USB drive is already up to date!")
        return True
    
    # Confirm with user
    if input("\nProceed with update? (y/N): ").lower() != 'y':
        print("Operation cancelled")
        return False
        
    # Remove outdated files
    for file in to_remove:
        try:
            os.remove(os.path.join(usb_path, file))
            print(f"🗑️  Removed {file}")
        except Exception as e:
            print(f"❌ Error removing {file}: {e}")
            
    # Copy new files
    for file in to_copy:
        try:
            shutil.copy2(
                os.path.join(download_dir, file),
                os.path.join(usb_path, file)
            )
            print(f"📁 Copied {file}")
        except Exception as e:
            print(f"❌ Error copying {file}: {e}")
    
    return True

def main():
    download_dir = "downloads_raspundel_istetel"
    
    if not os.path.exists(download_dir):
        print("❌ Downloads directory not found!")
        sys.exit(1)
        
    usb_path = find_usb_drive()
    if not usb_path:
        print("❌ No USB drive with .bnl files found!")
        sys.exit(1)
    
    print(f"📁 Found USB drive at {usb_path}")
    
    if sync_files(usb_path, download_dir):
        print("\n✅ USB update complete!")
    else:
        print("\n❌ Update failed or was cancelled")

if __name__ == "__main__":
    main()
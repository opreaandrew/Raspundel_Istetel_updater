"""
USB drive detection and file synchronization utilities.
Handles finding USB drives and syncing .bnl files to them.
"""

import os
import glob
import platform
import shutil
import time
from collections import deque
from typing import Optional


def find_usb_drive() -> Optional[str]:
    """
    Find USB drive based on operating system.
    Returns the first USB drive containing .bnl files.
    
    Returns:
        Path to USB drive, or None if not found
    """
    system = platform.system().lower()
    
    if system == 'windows':
        return _find_usb_drive_windows()
    elif system == 'linux':
        return _find_usb_drive_linux()
    else:
        print(f"❌ Unsupported operating system: {system}")
        return None


def _find_usb_drive_windows() -> Optional[str]:
    """Find first USB drive containing .bnl files on Windows."""
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


def _find_usb_drive_linux() -> Optional[str]:
    """Find first USB drive containing .bnl files on Linux."""
    mount_points = [
        "/media",      # Ubuntu-style
        "/run/media",  # Arch-style
        "/mnt"         # General mount point
    ]
    
    for base in mount_points:
        if not os.path.exists(base):
            continue
        
        # Check user-specific mounts first
        user_mounts = []
        user_base = os.path.join(base, os.getenv('USER', ''))
        if os.path.exists(user_base):
            user_mounts = [
                os.path.join(user_base, d) 
                for d in os.listdir(user_base)
            ]
        
        # Check direct mounts
        direct_mounts = []
        if os.path.exists(base):
            direct_mounts = [
                os.path.join(base, d) 
                for d in os.listdir(base)
            ]
        
        # Check all potential mount points
        for mount in user_mounts + direct_mounts:
            if os.path.ismount(mount):
                bnl_files = glob.glob(os.path.join(mount, "*.bnl"))
                if bnl_files:
                    return mount
    
    return None


def copy_file_with_progress(src: str, dst: str, bufsize: int = 64 * 1024) -> None:
    """
    Copy a single file with progress bar.
    
    Args:
        src: Source file path
        dst: Destination file path
        bufsize: Buffer size for copying in bytes
    """
    def human_size(n):
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if n < 1024.0:
                return f"{n:3.1f} {unit}"
            n /= 1024.0
        return f"{n:.1f} PB"
    
    def fmt_time(s):
        if s is None or s == float('inf'):
            return '--:--'
        m = int(s // 60)
        sec = int(s % 60)
        return f"{m:02d}:{sec:02d}"
    
    total = 0
    try:
        total = os.path.getsize(src)
    except Exception:
        total = 0
    
    if total == 0:
        # Empty file or unknown size: fallback to copy2
        shutil.copy2(src, dst)
        print(f"   📁 Copied {os.path.basename(src)}")
        return
    
    transferred = 0
    start = time.time()
    last_print = 0
    samples = deque()
    sample_window = 1.0  # seconds
    
    with open(src, 'rb') as fsrc, open(dst, 'wb') as fdst:
        while True:
            chunk = fsrc.read(bufsize)
            if not chunk:
                break
            
            fdst.write(chunk)
            transferred += len(chunk)
            
            now = time.time()
            samples.append((now, transferred))
            
            # Drop old samples outside the window
            while samples and (now - samples[0][0]) > sample_window:
                samples.popleft()
            
            # Throttle updates to ~5 per second
            if now - last_print >= 0.2 or transferred == total:
                last_print = now
                pct = transferred / total * 100
                elapsed = now - start
                
                # Compute speed using oldest sample in window
                if len(samples) >= 2:
                    t0, v0 = samples[0]
                    t1, v1 = samples[-1]
                    dt = max(1e-6, t1 - t0)
                    speed_bps = (v1 - v0) / dt
                else:
                    speed_bps = transferred / max(1e-6, elapsed)
                
                speed_mb = speed_bps / (1024 * 1024)
                remaining = total - transferred
                eta = (remaining / speed_bps) if (speed_bps and speed_bps > 0) else None
                
                bar_len = 30
                filled = int(bar_len * transferred / total)
                bar = ('#' * filled) + ('-' * (bar_len - filled))
                
                print(
                    f"\r   📁 {os.path.basename(src)} [{bar}] {pct:6.2f}% "
                    f"{speed_mb:6.2f} MB/s elapsed={fmt_time(elapsed)} "
                    f"eta={fmt_time(eta)} size={human_size(total)}",
                    end='', flush=True
                )
        
        # Ensure all data is flushed
        try:
            fdst.flush()
            os.fsync(fdst.fileno())
        except Exception:
            pass
        
        # Final update
        elapsed = time.time() - start
        speed_mb = (transferred / max(1e-6, elapsed)) / (1024 * 1024)
        print(
            f"\r   📁 {os.path.basename(src)} [{'#' * 30}] 100.00% "
            f"{speed_mb:6.2f} MB/s elapsed={fmt_time(elapsed)} "
            f"eta=00:00 size={human_size(total)}",
            flush=True
        )
    
    # Copy file metadata
    try:
        shutil.copystat(src, dst)
    except Exception:
        pass
    
    print(f"   ✅ Copied {os.path.basename(src)}")


def sync_files_to_usb(source_dir: str, usb_path: str, dry_run: bool = False) -> bool:
    """
    Sync files from source directory to USB drive.
    
    Args:
        source_dir: Directory containing files to sync
        usb_path: Path to USB drive
        dry_run: If True, only show what would be done without making changes
        
    Returns:
        True if successful, False otherwise
    """
    # Get file lists
    local_files = {
        os.path.basename(f) 
        for f in glob.glob(os.path.join(source_dir, "*.bnl"))
    }
    usb_files = {
        os.path.basename(f) 
        for f in glob.glob(os.path.join(usb_path, "*.bnl"))
    }
    
    if not local_files:
        print("❌ No .bnl files found in source directory!")
        return False
    
    # Determine what needs to change
    to_remove = usb_files - local_files
    to_copy = local_files - usb_files
    
    # Print status
    print(f"\n📊 Sync Status:")
    print(f"   Local files: {len(local_files)}")
    print(f"   USB files: {len(usb_files)}")
    print(f"   To remove: {len(to_remove)}")
    print(f"   To copy: {len(to_copy)}")
    
    if to_remove:
        print(f"\n🗑️  Files to be removed from USB:")
        for file in sorted(to_remove):
            print(f"   - {file}")
    
    if to_copy:
        print(f"\n📥 Files to be copied to USB:")
        for file in sorted(to_copy):
            print(f"   - {file}")
    
    if not (to_remove or to_copy):
        print("\n✅ USB drive is already up to date!")
        return True
    
    # If dry run, stop here
    if dry_run:
        print("\n🔍 Dry run complete - no changes made")
        return True
    
    # Confirm with user
    response = input("\n⚠️  Proceed with sync? (y/N): ").lower()
    if response != 'y':
        print("❌ Operation cancelled")
        return False
    
    # Remove outdated files
    for file in to_remove:
        try:
            file_path = os.path.join(usb_path, file)
            os.remove(file_path)
            print(f"🗑️  Removed: {file}")
        except Exception as e:
            print(f"❌ Error removing {file}: {e}")
    
    # Copy new files
    for file in to_copy:
        try:
            src = os.path.join(source_dir, file)
            dst = os.path.join(usb_path, file)
            copy_file_with_progress(src, dst)
        except Exception as e:
            print(f"❌ Error copying {file}: {e}")
    
    return True

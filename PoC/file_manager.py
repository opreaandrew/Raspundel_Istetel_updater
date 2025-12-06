"""
File management utilities for listing and comparing files.
Handles local downloads directory and USB drive file operations.
"""

import os
import glob
from typing import Set, Tuple, Dict


def list_local_files(directory: str) -> Set[str]:
    """
    Get list of .bnl files in the local downloads directory.
    
    Args:
        directory: Path to the downloads directory
        
    Returns:
        Set of filenames (basename only, not full paths)
    """
    if not os.path.exists(directory):
        return set()
    
    pattern = os.path.join(directory, "*.bnl")
    files = glob.glob(pattern)
    return {os.path.basename(f) for f in files}


def list_usb_files(usb_path: str) -> Set[str]:
    """
    Get list of .bnl files on the USB drive.
    
    Args:
        usb_path: Path to the USB drive
        
    Returns:
        Set of filenames (basename only, not full paths)
    """
    if not os.path.exists(usb_path):
        return set()
    
    pattern = os.path.join(usb_path, "*.bnl")
    files = glob.glob(pattern)
    return {os.path.basename(f) for f in files}


def compare_file_lists(source: Set[str], target: Set[str]) -> Tuple[Set[str], Set[str]]:
    """
    Compare two file lists and determine what needs to be added/removed.
    
    Args:
        source: Set of filenames that should be present
        target: Set of filenames currently present
        
    Returns:
        Tuple of (files_to_add, files_to_remove)
        - files_to_add: Files in source but not in target
        - files_to_remove: Files in target but not in source
    """
    files_to_add = source - target
    files_to_remove = target - source
    return files_to_add, files_to_remove


def get_file_info(file_path: str) -> Dict[str, any]:
    """
    Get metadata about a file.
    
    Args:
        file_path: Full path to the file
        
    Returns:
        Dictionary with file metadata (size, modified_time, exists)
    """
    info = {
        "exists": os.path.exists(file_path),
        "size": 0,
        "size_human": "0 B",
        "modified_time": None
    }
    
    if info["exists"]:
        try:
            stat = os.stat(file_path)
            info["size"] = stat.st_size
            info["size_human"] = _human_size(stat.st_size)
            info["modified_time"] = stat.st_mtime
        except Exception:
            pass
    
    return info


def _human_size(size_bytes: int) -> str:
    """Convert bytes to human-readable size string."""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} PB"

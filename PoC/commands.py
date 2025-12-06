"""
CLI command implementations for the Raspundel Istetel Updater.

This module contains all command logic for download, update, and sync operations.
"""

import os
import file_manager
import downloader
import updater


DOWNLOAD_DIR = "downloads_raspundel_istetel"


def cmd_download(force: bool = False) -> int:
    """
    Download missing files from website.
    
    Args:
        force: If True, re-download all files (ignore existing)
        
    Returns:
        Exit code (0 for success, 1 for failure)
    """
    print("=" * 60)
    print("📥 DOWNLOAD COMMAND")
    print("=" * 60)
    
    try:
        # Get list of files from website
        print("\n🌐 Fetching file list from website...")
        website_files = downloader.fetch_website_file_list()
        
        if not website_files:
            print("❌ No files found on website")
            return 1
        
        # Get list of already downloaded files
        if force:
            print("🔄 Force mode: will re-download all files")
            local_files = set()
        else:
            local_files = file_manager.list_local_files(DOWNLOAD_DIR)
            print(f"📂 Found {len(local_files)} files already downloaded")
        
        # Download missing files
        count = downloader.download_missing_files(website_files, local_files, DOWNLOAD_DIR)
        
        if count > 0:
            print(f"\n✅ Download complete: {count} new files")
        else:
            print("\n✅ All files up to date")
        
        return 0
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Download cancelled by user")
        return 1
    except Exception as e:
        print(f"\n❌ Download failed: {e}")
        return 1


def cmd_update(dry_run: bool = False) -> int:
    """
    Sync downloaded files to USB drive.
    
    Args:
        dry_run: If True, only show what would be done
        
    Returns:
        Exit code (0 for success, 1 for failure)
    """
    print("=" * 60)
    print("📱 UPDATE COMMAND")
    print("=" * 60)
    
    try:
        # Check if download directory exists
        if not os.path.exists(DOWNLOAD_DIR):
            print(f"❌ Downloads directory not found: {DOWNLOAD_DIR}")
            print("   Run 'python main.py download' first")
            return 1
        
        # Find USB drive
        print("\n🔍 Looking for USB drive...")
        usb_path = updater.find_usb_drive()
        
        if not usb_path:
            print("❌ No USB drive with .bnl files found")
            print("   Please insert a USB drive containing .bnl files")
            return 1
        
        print(f"✅ Found USB drive: {usb_path}")
        
        # Sync files
        if dry_run:
            print("\n🔍 DRY RUN MODE - No changes will be made\n")
        
        success = updater.sync_files_to_usb(DOWNLOAD_DIR, usb_path, dry_run=dry_run)
        
        if success:
            if dry_run:
                print("\n✅ Dry run complete")
            else:
                print("\n✅ USB update complete")
            return 0
        else:
            print("\n❌ Update failed or was cancelled")
            return 1
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Update cancelled by user")
        return 1
    except Exception as e:
        print(f"\n❌ Update failed: {e}")
        return 1


def cmd_sync(dry_run: bool = False) -> int:
    """
    Download missing files from USB perspective and sync to USB in one step.
    Compares USB files with website files, downloads only what's missing from USB.
    Also removes outdated files from USB that are no longer on the website.
    
    Args:
        dry_run: If True, only show what would be done for USB update
        
    Returns:
        Exit code (0 for success, 1 for failure)
    """
    print("=" * 60)
    print("🔄 SYNC COMMAND (Smart Delta Download + Update)")
    print("=" * 60)
    
    try:
        # Step 1: Find USB drive
        print("\n🔍 Looking for USB drive...")
        usb_path = updater.find_usb_drive()
        
        if not usb_path:
            print("❌ No USB drive with .bnl files found")
            print("   Please insert a USB drive containing .bnl files")
            return 1
        
        print(f"✅ Found USB drive: {usb_path}")
        
        # Step 2: Get USB files
        usb_files = file_manager.list_usb_files(usb_path)
        print(f"📂 USB has {len(usb_files)} files")
        
        # Step 3: Get website files
        print("\n🌐 Fetching file list from website...")
        website_files = downloader.fetch_website_file_list()
        
        if not website_files:
            print("❌ No files found on website")
            return 1
        
        website_filenames = {filename for filename, url in website_files}
        
        # Step 4: Determine delta (missing and outdated)
        missing_from_usb = website_filenames - usb_files
        outdated_on_usb = usb_files - website_filenames
        
        print(f"\n📊 Delta Analysis:")
        print(f"   Website has: {len(website_filenames)} files")
        print(f"   USB has: {len(usb_files)} files")
        print(f"   Missing from USB: {len(missing_from_usb)} files")
        print(f"   Outdated on USB: {len(outdated_on_usb)} files")
        
        if missing_from_usb:
            print(f"\n📥 Files to download:")
            for filename in sorted(missing_from_usb):
                print(f"   - {filename}")
        
        if outdated_on_usb:
            print(f"\n🗑️  Files to remove (not on website):")
            for filename in sorted(outdated_on_usb):
                print(f"   - {filename}")
        
        if not missing_from_usb and not outdated_on_usb:
            print("\n✅ USB is already perfectly synced with website!")
            return 0
        
        # Step 5: Confirm or dry-run
        if dry_run:
            print("\n🔍 DRY RUN MODE - No changes will be made")
            return 0
        
        if missing_from_usb or outdated_on_usb:
            response = input("\n⚠️  Proceed with sync (download + remove)? (y/N): ").lower()
            if response != 'y':
                print("❌ Sync cancelled")
                return 1
        
        # Step 6: Remove outdated files first
        if outdated_on_usb:
            print(f"\n🗑️  Removing {len(outdated_on_usb)} outdated files...")
            for filename in outdated_on_usb:
                try:
                    file_path = os.path.join(usb_path, filename)
                    os.remove(file_path)
                    print(f"   ✅ Removed: {filename}")
                except Exception as e:
                    print(f"   ❌ Error removing {filename}: {e}")
        
        # Step 7: Download missing files
        if missing_from_usb:
            print(f"\n⬇️  Downloading {len(missing_from_usb)} missing files to USB...")
            
            files_to_download = [(name, url) for name, url in website_files if name in missing_from_usb]
            
            success_count = 0
            for filename, url in files_to_download:
                if downloader.download_file(url, usb_path, filename):
                    success_count += 1
            
            print(f"\n✅ Downloaded {success_count}/{len(files_to_download)} files")
        
        print(f"\n✅ Sync complete! USB now matches website perfectly.")
        return 0
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Sync cancelled by user")
        return 1
    except Exception as e:
        print(f"\n❌ Sync failed: {e}")
        return 1

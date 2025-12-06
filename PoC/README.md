# Raspundel Updater

Professional proof of concept tool to update Raspunde Istetel pens with latest .bnl files.

## Features

- **Intelligent Downloads**: Only downloads new files by comparing website vs local content
- **Smart USB Sync**: Compares files and syncs only what's needed
- **Auto-Cleanup**: Automatically removes outdated files from USB that are no longer on website
- **Cross-platform Support**: Works on Windows and Linux
- **Safe Operations**: Dry-run mode to preview changes before applying
- **Professional Architecture**: Modular design with clear separation of concerns
- **Automatic Environment Setup**: Virtual environment created and managed automatically

## Requirements

- Python 3.6+
- Internet connection (for downloading)
- USB drive with .bnl files (for updating)

## Quick Start

Smart sync (downloads missing files, removes outdated ones):
```bash
python main.py sync
```

Download new files from website:
```bash
python main.py download
```

Update USB drive with downloaded files:
```bash
python main.py update
```

## Usage

### Sync Command (Recommended)

Smart sync: compares USB with website, downloads missing files, removes outdated files:
```bash
python main.py sync
```

Preview what would change (dry-run):
```bash
python main.py sync --dry-run
```

**How it works:**
1. Finds your USB drive automatically
2. Compares USB files with website files
3. Shows you what will be downloaded and removed
4. Asks for confirmation
5. Removes files not on website anymore
6. Downloads missing files directly to USB
7. USB perfectly matches website

### Download Command

Download only missing files to local downloads folder (smart comparison):
```bash
python main.py download
```

Force re-download all files:
```bash
python main.py download --force
```

### Update Command

Sync files from downloads folder to USB drive:
```bash
python main.py update
```

Preview what would be changed (dry-run):
```bash
python main.py update --dry-run
```

## Architecture

The project uses a modular architecture with clear separation of concerns:

```
PoC/
├── main.py              # Main entry point and CLI orchestration
├── commands.py          # Command implementations (download, update, sync)
├── env_setup.py         # Virtual environment management (runs first)
├── file_manager.py      # File listing and comparison utilities
├── downloader.py        # Website scraping and file downloads
├── updater.py           # USB drive detection and file sync
├── .venv/              # Python virtual environment (auto-created)
└── downloads_raspundel_istetel/  # Downloaded files storage
```

### Module Descriptions

**`main.py`** - Entry point and CLI orchestration. Parses arguments and dispatches to command handlers. Ensures venv is set up before any operations.

**`commands.py`** - All command implementations:
- `cmd_download()` - Download files from website to local folder
- `cmd_update()` - Sync local folder to USB
- `cmd_sync()` - Smart sync USB directly with website

**`env_setup.py`** - Manages virtual environment creation and dependency installation. Runs transparently at startup.

**`file_manager.py`** - Provides utilities for:
- Listing .bnl files in directories
- Comparing file lists to determine differences
- Getting file metadata

**`downloader.py`** - Handles website interaction:
- Scrapes raspundelistetel.ro for available files
- Downloads individual files with progress tracking
- Smart downloading of only missing files

**`updater.py`** - Manages USB operations:
- Platform-specific USB drive detection
- File synchronization with progress bars
- Safe copying with verification

## How It Works

### Smart Sync (Recommended)

1. Automatically finds USB drive with .bnl files
2. Fetches complete file list from website (across all pages)
3. Compares USB content with website content
4. Identifies files to download (on website but not on USB)
5. Identifies files to remove (on USB but not on website)
6. Shows delta analysis and asks for confirmation
7. Removes outdated files from USB
8. Downloads missing files directly to USB
9. USB now perfectly mirrors the website

### Smart Downloads

1. Fetches list of all .bnl files from website (across all pages)
2. Compares with locally downloaded files
3. Downloads only files that are missing locally
4. Saves bandwidth and time by skipping existing files

### Intelligent USB Sync

1. Scans local downloads directory for .bnl files
2. Scans USB drive for .bnl files
3. Determines files to add (in downloads, not on USB)
4. Determines files to remove (on USB, not in downloads)
5. Prompts for confirmation before making changes
6. Syncs files with progress tracking

## Notes

- USB drive must contain at least one .bnl file to be recognized
- The `sync` command ensures USB always matches the website (removes outdated files automatically)
- The `update` command ensures USB matches the downloads folder
- Outdated files are automatically removed during sync operations
- Virtual environment is created automatically on first run
- All dependencies (requests, beautifulsoup4) are installed automatically
- Use `--dry-run` flag to preview changes before making them
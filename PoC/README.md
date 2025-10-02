# Raspundel Updater

Proof of concept command line tool to update Raspunde Istetel pens with latest .bnl files.

## Features

- Downloads latest .bnl files from raspundelistetel.ro
- Updates USB pen drives with new content
- Cross-platform support (Windows/Linux)
- Safe update process with verification
- Automatic virtual environment setup

## Requirements

- Python 3.6+
- Internet connection
- USB drive with .bnl files for updating

## Usage

Download latest files:
```bash
python Downloader.py
```

Update USB drive:
```bash
python UsbUpdater.py
```

## Project Structure

```
Raspundel_updater/
├── Downloader.py     # Downloads latest .bnl files
├── UsbUpdater.py     # Updates USB drive content
├── .venv/           # Python virtual environment (auto-created)
└── downloads_raspundel_istetel/  # Downloaded files storage
```

## Notes

- USB drive must contain .bnl files to be recognized as valid
- New files take precedence over existing ones
- Outdated files are removed during update
- Python virtual environment is created and managed automatically
# raspundel_updater

# Raspundel Updater

A cross-platform GUI application to download and manage .bnl files for Raspunde Istetel pens.

## Features

- Download latest .bnl files from raspundelistetel.ro
- Display download progress with speed and file count
- Download files in parallel with progress tracking
- Detect and sync files to USB pens
- Cross-platform support (Windows, Linux, macOS)
- Automatic update checking
- Material Design UI

## Technologies

- Flutter 3.0+
- Dart SDK >=3.0.0
- Key packages:
  - http: Web requests and file downloads
  - file_picker: File and directory selection
  - path_provider: Cross-platform file system access
  - flutter_local_notifications: Download notifications
  - window_size: Window management for desktop
  - html: HTML parsing for file listing
  - provider: State management

## Project Structure

```
lib/
├── models/
│   ├── download_progress.dart     # Download progress tracking
│   └── file_models.dart          # File and USB drive models
├── pages/
│   └── home_page.dart            # Main application page
├── providers/
│   └── app_providers.dart        # Application state providers
├── screens/
│   └── home_screen.dart          # Main screen implementation
├── services/
│   ├── download_service.dart     # File download handling
│   ├── downloader_service.dart   # File listing and download logic
│   ├── file_service.dart         # File system operations
│   ├── update_service.dart       # Update checking
│   └── usb_service.dart         # USB device detection
├── widgets/
│   └── progress_widget.dart      # Progress visualization
└── main.dart                     # Application entry point
```

## Getting Started

### Prerequisites

1. Install Flutter (3.0 or higher)
2. Install Dart SDK (3.0 or higher)
3. Setup your preferred IDE (VS Code recommended)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/raspundel_updater.git
```

2. Install dependencies:
```bash
cd raspundel_updater/App
flutter pub get
```

3. Run the application:
```bash
flutter run -d windows  # For Windows
flutter run -d linux   # For Linux
flutter run -d macos   # For macOS
```

## Build

To create a release build:

```bash
flutter build windows  # For Windows
flutter build linux   # For Linux
flutter build macos   # For macOS
```

## Downloads Location

By default, files are downloaded to:
- Windows: `%APPDATA%/com.example.raspundel_updater/Downloads/RaspundeListetel`
- Linux: `~/.local/share/com.example.raspundel_updater/Downloads/RaspundeListetel`
- macOS: `~/Library/Application Support/com.example.raspundel_updater/Downloads/RaspundeListetel`

## License

MIT License

## Contributing

1. Fork the Project
2. Create your Feature Branch
3. Commit your Changes
4. Push to the Branch
5. Open a Pull Request

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

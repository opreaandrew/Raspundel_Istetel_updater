Raspunde Istetel Pen Updater — App Plan
Overview

Goal:
Build a cross-platform app to update Raspunde Istetel pens with the latest .bnl files from
https://www.raspundelistetel.ro/ro/fisiere-pentru-descarcare

Use case:
A parent buys a new book for their child and wants to update the pen’s content with the newest versions and add the new book.

Requirements:

Works on Windows, Linux, Android, macOS, iOS

Has a simple graphical interface

Downloads latest .bnl files

Syncs them to the pen via USB or SD card

Focus on usability and simplicity (Check Updates and Sync to Pen)

Stack Choice

Use Flutter with Dart.
Single codebase for all platforms.
No backend required.
Performs web scraping and file operations locally.

Required Platforms

Windows

Linux

Android

macOS

iOS

Architecture

lib/
├── main.dart
├── services/
│ ├── downloader_service.dart # Scrapes the website and downloads .bnl files
│ ├── file_service.dart # Detects USB/SD storage and manages copying
│ └── update_service.dart # Handles synchronization and update logic
├── screens/
│ └── home_screen.dart # Main app interface
├── widgets/
│ └── progress_widget.dart # Displays progress and user feedback
└── models/
└── file_entry.dart # Represents a downloadable file entry

Packages
Purpose	Package	Description
HTTP requests	http	Fetches HTML and file URLs
HTML parsing	html	Parses the site’s structure to extract .bnl links
File handling	path_provider, file_picker, dart:io	Manages folders, file writing, and USB/SD detection
Notifications	flutter_local_notifications	Shows success or failure messages
Progress indicators	percent_indicator, lottie	Provides visual progress during downloads or sync
USB/OTG support	usb_serial, flutter_usb_write	Enables direct writing to USB or OTG pens (if supported)
State management	provider	Manages app logic and state
App Flow

User opens the app.
The app scrapes the website for available .bnl files.

The app lists files.
Each file entry shows title, size, and update status.

User clicks "Download latest".
The app downloads new or updated files to a local folder (Downloads/RaspundeListetel/).

User connects the pen via USB or selects SD card storage.
The app automatically detects the drive or asks the user to select it manually.

User clicks "Sync to Pen".
The app copies the updated files to the connected pen or SD card and shows progress.

After syncing, the app confirms completion and returns to the home screen.

UI Design

Minimal, practical interface.

Elements:

Header: "Update your pen’s library"

Button: "Check for Updates"

File list: each entry showing book name and update status (up to date, needs update, downloading)

Button: "Sync to Pen"

Progress bar shown during download or synchronization

Deployment
Platform	Output	Distribution
Android	.apk or .aab	Google Play or manual install
Windows	.exe	Distributed via website or USB
macOS	.app	Drag-and-drop install
Linux	.AppImage or .deb	Local installation
iOS	.ipa	App Store or sideload
Summary
Category	Description
Language	Dart
Framework	Flutter
Target platforms	Windows, Linux, Android, macOS, iOS
Web scraping	http and html packages
File synchronization	dart:io with USB/SD access
Interface	Flutter Material UI
Data persistence	Local cache (optional)
Architecture style	Simple service-based structure
# Raspundel Updater Project

## The Problem

Managing educational content on Raspunde Istetel pens was a manual and time-consuming process. I had to:
- Regularly check the website for new content
- Manually download each .bnl file
- Keep track of which files were already downloaded
- Manually copy files to the pen
- Verify successful transfers

This process was error-prone and inefficient, especially when managing multiple pens or handling regular updates.

## The Journey

### Phase 1: Proof of Concept (PoC)
Started with a Python script to automate the basic download process. This proved that I could:
- Scrape the website for available files
- Automatically download new content
- Handle the file management process

See [PoC Documentation](PoC/README.md) for technical details.

### Phase 2: GUI Application
Evolved the concept into a full-fledged cross-platform application using Flutter. This added:
- User-friendly interface
- Progress tracking and notifications
- Automatic USB pen detection
- Cross-platform support
- Robust error handling

See [App Documentation](App/README.md) for implementation details.

## Project Structure

```
.
├── PoC/                    # Initial Python proof of concept
│   ├── Downloader.py      # File downloading logic
│   ├── Updater.py         # File management
│   └── README.md          # PoC documentation
│
└── App/                    # Flutter application
    ├── lib/               # Application source code
    └── README.md          # Full application documentation
```

## Evolution & Improvements

The transition from PoC to App brought several improvements:
- From command-line to intuitive GUI
- From single-platform to cross-platform support
- From basic downloads to full content management
- From manual to automated USB detection
- From simple progress to detailed download statistics

## Getting Started

- For the Python PoC, see [PoC/README.md](PoC/README.md)
- For the Flutter application, see [App/README.md](App/README.md)
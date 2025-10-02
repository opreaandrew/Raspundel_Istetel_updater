import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/downloader_service.dart';
import '../services/file_service.dart';
import '../services/update_service.dart';
import '../widgets/progress_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileService _fileService = FileService();
  late DownloaderService _downloaderService;
  late UpdateService _updateService;
  
  List<String>? _availableFiles;
  String? _penPath;
  bool _isDownloading = false;
  bool _isSyncing = false;
  String? _currentOperation;
  double _progress = 0.0;
  ProgressState _progressState = ProgressState.idle;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final downloadDir = await _fileService.getDownloadDirectory();
    _downloaderService = DownloaderService(downloadDir: downloadDir);
    _updateService = UpdateService(downloadDir: downloadDir);
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _progressState = ProgressState.inProgress;
      _currentOperation = 'Checking for updates...';
    });

    try {
      final files = await _downloaderService.getAvailableFiles();
      setState(() {
        _availableFiles = files;
        _progressState = ProgressState.completed;
        _currentOperation = 'Found ${files.length} files';
      });
    } catch (e) {
      setState(() {
        _progressState = ProgressState.error;
        _currentOperation = 'Error checking updates: $e';
      });
    }
  }

  Future<void> _downloadFiles() async {
    if (_availableFiles == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progressState = ProgressState.inProgress;
      _progress = 0.0;
    });

    try {
      for (var i = 0; i < _availableFiles!.length; i++) {
        final file = _availableFiles![i];
        setState(() {
          _currentOperation = 'Downloading ${file.split('/').last}...';
        });

        await _downloaderService.downloadFile(
          file,
          (progress) {
            setState(() {
              _progress = (i + progress.progress) / _availableFiles!.length;
              _currentOperation = 'Downloading ${progress.fileName} (${(i + 1)}/${_availableFiles!.length}) - ${progress.speedMBps.toStringAsFixed(1)} MB/s';
            });
          },
          i + 1,
          _availableFiles!.length,
        );
      }

      setState(() {
        _progressState = ProgressState.completed;
        _currentOperation = 'Download completed';
      });
    } catch (e) {
      setState(() {
        _progressState = ProgressState.error;
        _currentOperation = 'Download error: $e';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _syncToPen() async {
    if (_isSyncing) return;

    final penPath = await _fileService.getPenDirectory();
    if (penPath == null) {
      setState(() {
        _progressState = ProgressState.error;
        _currentOperation = 'No pen detected';
      });
      return;
    }

    setState(() {
      _penPath = penPath;
      _isSyncing = true;
      _progressState = ProgressState.inProgress;
      _progress = 0.0;
      _currentOperation = 'Starting sync...';
    });

    try {
      final localFiles = await _fileService.getLocalFiles();
      final penFiles = await _fileService.getPenFiles(penPath);

      await _updateService.syncToPen(
        penPath: penPath,
        localFiles: localFiles,
        penFiles: penFiles,
        onProgress: (message, progress) {
          setState(() {
            _currentOperation = message;
            _progress = progress;
          });
        },
        onError: (error) {
          setState(() {
            _progressState = ProgressState.error;
            _currentOperation = error;
          });
        },
      );

      final success = await _updateService.verifySync(penPath, localFiles);
      setState(() {
        _progressState = success ? ProgressState.completed : ProgressState.error;
        _currentOperation = success ? 'Sync completed' : 'Sync verification failed';
      });
    } catch (e) {
      setState(() {
        _progressState = ProgressState.error;
        _currentOperation = 'Sync error: $e';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update your pen\'s library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isDownloading ? null : _checkForUpdates,
              child: const Text('Check for Updates'),
            ),
            const SizedBox(height: 16),
            if (_availableFiles != null) ...[
              Text(
                'Available Files (${_availableFiles!.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableFiles!.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_availableFiles![index]),
                      leading: const Icon(Icons.description),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_currentOperation != null)
              ProgressWidget(
                title: _currentOperation!,
                progress: _progress,
                state: _progressState,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDownloading || _availableFiles == null
                        ? null
                        : _downloadFiles,
                    child: const Text('Download Latest'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSyncing ? null : _syncToPen,
                    child: const Text('Sync to Pen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
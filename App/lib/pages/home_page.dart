import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/file_models.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usbDrives = ref.watch(usbDrivesProvider);
    final availableFiles = ref.watch(availableFilesProvider);
    final downloadProgress = ref.watch(downloadProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raspundel Updater'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(usbDrivesProvider);
              ref.refresh(availableFilesProvider);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // USB Drives Panel
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'USB Drives',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: usbDrives.when(
                      data: (drives) => ListView.builder(
                        itemCount: drives.length,
                        itemBuilder: (context, index) {
                          final drive = drives[index];
                          return ListTile(
                            title: Text(drive.name),
                            subtitle: Text('${drive.bnlFiles.length} files'),
                            leading: const Icon(Icons.usb),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Available Files Panel
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Available Files',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: availableFiles.when(
                      data: (files) => ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final fileName = files[index];
                          final progress = downloadProgress[fileName];
                          
                          return ListTile(
                            title: Text(fileName),
                            trailing: _buildDownloadIndicator(progress),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement sync action
        },
        label: const Text('Sync USB'),
        icon: const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildDownloadIndicator(DownloadProgress? progress) {
    if (progress == null) {
      return const Icon(Icons.download);
    }

    switch (progress.status) {
      case DownloadStatus.downloading:
        return CircularProgressIndicator(value: progress.progress);
      case DownloadStatus.completed:
        return const Icon(Icons.check, color: Colors.green);
      case DownloadStatus.error:
        return const Icon(Icons.error, color: Colors.red);
      case DownloadStatus.notStarted:
        return const Icon(Icons.download);
    }
  }
}
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/file_models.dart';

class UpdateService {
  final String downloadDir;

  UpdateService({required this.downloadDir});

  Future<void> syncToPen({
    required String penPath,
    required List<BnlFile> localFiles,
    required List<BnlFile> penFiles,
    required Function(String, double) onProgress,
    required Function(String) onError,
  }) async {
    try {
      // Calculate files to remove and add
      final localFileNames = localFiles.map((f) => f.name).toSet();
      final penFileNames = penFiles.map((f) => f.name).toSet();

      final filesToRemove = penFiles.where((f) => !localFileNames.contains(f.name));
      final filesToAdd = localFiles.where((f) => !penFileNames.contains(f.name));

      // Remove outdated files
      for (final file in filesToRemove) {
        try {
          final penFile = File(file.path);
          if (await penFile.exists()) {
            await penFile.delete();
          }
          onProgress('Removed ${file.name}', 0);
        } catch (e) {
          onError('Failed to remove ${file.name}: $e');
        }
      }

      // Copy new files
      int completed = 0;
      final totalFiles = filesToAdd.length;

      for (final file in filesToAdd) {
        try {
          final sourceFile = File(path.join(downloadDir, file.name));
          final targetFile = File(path.join(penPath, file.name));

          await sourceFile.copy(targetFile.path);
          completed++;
          onProgress(
            'Copying ${file.name}',
            completed / totalFiles,
          );
        } catch (e) {
          onError('Failed to copy ${file.name}: $e');
        }
      }
    } catch (e) {
      onError('Sync failed: $e');
      rethrow;
    }
  }

  Future<bool> verifySync(String penPath, List<BnlFile> expectedFiles) async {
    try {
      for (final file in expectedFiles) {
        final penFile = File(path.join(penPath, file.name));
        if (!await penFile.exists()) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> cleanupDownloadDir() async {
    try {
      final dir = Directory(downloadDir);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.toLowerCase().endsWith('.bnl')) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Handle cleanup errors
      print('Cleanup error: $e');
    }
  }
}
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_models.dart';

class FileService {
  Future<String> getDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = path.join(appDir.path, 'Downloads', 'RaspundeListetel');
    final dir = Directory(downloadDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    print('Download directory: ${dir.absolute.path}');
    return downloadDir;
  }

  Future<List<BnlFile>> getLocalFiles() async {
    final downloadDir = await getDownloadDirectory();
    final dir = Directory(downloadDir);
    final files = <BnlFile>[];

    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.bnl')) {
          final stat = await entity.stat();
          files.add(BnlFile(
            name: path.basename(entity.path),
            path: entity.path,
            lastModified: stat.modified,
          ));
        }
      }
    }

    return files;
  }

  Future<String?> getPenDirectory() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidUsbDirectory();
      } else {
        return await _getDesktopPenDirectory();
      }
    } catch (e) {
      print('Error getting pen directory: $e');
      return null;
    }
  }

  Future<String?> _getAndroidUsbDirectory() async {
    // For Android, we'll use USB OTG or external storage
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select pen storage location',
      );
      
      if (result != null) {
        // Verify it's a valid pen directory (contains .bnl files)
        final dir = Directory(result);
        final hasBnlFiles = await dir
            .list()
            .any((entity) => entity is File && entity.path.endsWith('.bnl'));
            
        return hasBnlFiles ? result : null;
      }
    } catch (e) {
      print('Error accessing Android storage: $e');
    }
    return null;
  }

  Future<String?> _getDesktopPenDirectory() async {
    if (Platform.isWindows) {
      // Check removable drives on Windows
      for (final letter in List.generate(26, (i) => String.fromCharCode(65 + i))) {
        final drivePath = '$letter:\\';
        try {
          if (await _isValidPenDrive(drivePath)) {
            return drivePath;
          }
        } catch (_) {
          // Skip inaccessible drives
          continue;
        }
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      // Check common mount points on Unix-like systems
      final mountPoints = [
        '/media/${Platform.environment['USER']}',
        '/run/media/${Platform.environment['USER']}',
        '/mnt',
        '/Volumes', // macOS specific
      ];

      for (final base in mountPoints) {
        final baseDir = Directory(base);
        if (await baseDir.exists()) {
          await for (final entity in baseDir.list()) {
            if (await _isValidPenDrive(entity.path)) {
              return entity.path;
            }
          }
        }
      }
    }

    // If automatic detection fails, let user choose manually
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select pen location',
    );
  }

  Future<bool> _isValidPenDrive(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return false;

      // Check if directory contains .bnl files
      return await dir
          .list()
          .any((entity) => entity is File && entity.path.endsWith('.bnl'));
    } catch (_) {
      return false;
    }
  }

  Future<List<BnlFile>> getPenFiles(String penPath) async {
    final files = <BnlFile>[];
    final dir = Directory(penPath);

    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.bnl')) {
          final stat = await entity.stat();
          files.add(BnlFile(
            name: path.basename(entity.path),
            path: entity.path,
            lastModified: stat.modified,
          ));
        }
      }
    }

    return files;
  }
}
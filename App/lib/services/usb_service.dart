import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/file_models.dart';

class UsbService {
  Future<List<UsbDrive>> findUsbDrivesWithBnl() async {
    if (Platform.isWindows) {
      return _findWindowsUsbDrives();
    } else if (Platform.isLinux) {
      return _findLinuxUsbDrives();
    }
    throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
  }

  Future<List<UsbDrive>> _findWindowsUsbDrives() async {
    final drives = <UsbDrive>[];
    
    // Check all possible drive letters
    for (var letter in List.generate(26, (i) => String.fromCharCode(65 + i))) {
      final drivePath = '$letter:\\';
      final directory = Directory(drivePath);
      
      if (await directory.exists()) {
        final bnlFiles = await _findBnlFiles(drivePath);
        if (bnlFiles.isNotEmpty) {
          drives.add(UsbDrive(
            path: drivePath,
            name: 'Drive ($letter:)',
            bnlFiles: bnlFiles,
          ));
        }
      }
    }
    
    return drives;
  }

  Future<List<UsbDrive>> _findLinuxUsbDrives() async {
    final drives = <UsbDrive>[];
    final mountPoints = ['/media', '/run/media', '/mnt'];
    
    for (final basePoint in mountPoints) {
      final base = Directory(basePoint);
      if (!await base.exists()) continue;

      // Check user-specific mounts
      final username = Platform.environment['USER'];
      if (username != null) {
        final userMount = Directory(path.join(basePoint, username));
        if (await userMount.exists()) {
          await _checkMountPoint(userMount, drives);
        }
      }

      // Check direct mounts
      await _checkMountPoint(base, drives);
    }
    
    return drives;
  }

  Future<void> _checkMountPoint(Directory base, List<UsbDrive> drives) async {
    await for (final mount in base.list()) {
      if (mount is Directory) {
        final bnlFiles = await _findBnlFiles(mount.path);
        if (bnlFiles.isNotEmpty) {
          drives.add(UsbDrive(
            path: mount.path,
            name: path.basename(mount.path),
            bnlFiles: bnlFiles,
          ));
        }
      }
    }
  }

  Future<List<BnlFile>> _findBnlFiles(String dirPath) async {
    final bnlFiles = <BnlFile>[];
    final directory = Directory(dirPath);
    
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.bnl')) {
          final stat = await entity.stat();
          bnlFiles.add(BnlFile(
            name: path.basename(entity.path),
            path: entity.path,
            lastModified: stat.modified,
          ));
        }
      }
    } catch (e) {
      // Handle permission errors or other issues
      print('Error scanning directory $dirPath: $e');
    }
    
    return bnlFiles;
  }
}
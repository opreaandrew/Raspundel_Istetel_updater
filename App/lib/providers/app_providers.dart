import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_models.dart';
import '../services/usb_service.dart';
import '../services/download_service.dart';

final usbServiceProvider = Provider((ref) => UsbService());
final downloadServiceProvider = Provider((ref) => DownloadService());

final usbDrivesProvider = FutureProvider<List<UsbDrive>>((ref) async {
  final usbService = ref.read(usbServiceProvider);
  return usbService.findUsbDrivesWithBnl();
});

final downloadProgressProvider = StateNotifierProvider<DownloadProgressNotifier, Map<String, DownloadProgress>>((ref) {
  return DownloadProgressNotifier();
});

class DownloadProgressNotifier extends StateNotifier<Map<String, DownloadProgress>> {
  DownloadProgressNotifier() : super({});

  void updateProgress(String fileName, DownloadProgress progress) {
    state = {...state, fileName: progress};
  }

  void clearProgress(String fileName) {
    final newState = Map<String, DownloadProgress>.from(state);
    newState.remove(fileName);
    state = newState;
  }
}

final availableFilesProvider = FutureProvider<List<String>>((ref) async {
  final downloadService = ref.read(downloadServiceProvider);
  return downloadService.getAvailableFiles();
});
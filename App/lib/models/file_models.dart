class BnlFile {
  final String name;
  final String path;
  final DateTime lastModified;

  BnlFile({
    required this.name,
    required this.path,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BnlFile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path;

  @override
  int get hashCode => name.hashCode ^ path.hashCode;
}

class UsbDrive {
  final String path;
  final String name;
  final List<BnlFile> bnlFiles;

  UsbDrive({
    required this.path,
    required this.name,
    required this.bnlFiles,
  });
}

enum DownloadStatus {
  notStarted,
  downloading,
  completed,
  error,
}

class DownloadProgress {
  final String fileName;
  final DownloadStatus status;
  final double progress;
  final String? error;
  final double speedMBps;
  final int currentFileIndex;
  final int totalFiles;

  const DownloadProgress({
    required this.fileName,
    required this.status,
    required this.progress,
    this.error,
    this.speedMBps = 0.0,
    this.currentFileIndex = 0,
    this.totalFiles = 0,
  });

  DownloadProgress copyWith({
    String? fileName,
    DownloadStatus? status,
    double? progress,
    String? error,
    double? speedMBps,
    int? currentFileIndex,
    int? totalFiles,
  }) {
    return DownloadProgress(
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      speedMBps: speedMBps ?? this.speedMBps,
      currentFileIndex: currentFileIndex ?? this.currentFileIndex,
      totalFiles: totalFiles ?? this.totalFiles,
    );
  }
}
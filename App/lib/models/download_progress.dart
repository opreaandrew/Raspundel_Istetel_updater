class DownloadProgress {
  final String fileName;
  final double progress;
  final double speedMBps;
  final int currentFileIndex;
  final int totalFiles;

  const DownloadProgress({
    required this.fileName,
    required this.progress,
    required this.speedMBps,
    required this.currentFileIndex,
    required this.totalFiles,
  });
}
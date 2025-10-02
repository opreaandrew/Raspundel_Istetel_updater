import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/file_models.dart';

class DownloadService {
  static const String baseUrl = 'https://raspundelistetel.ro/downloads';
  static const String downloadDir = 'downloads_raspundel_istetel';

  Future<List<String>> getAvailableFiles() async {
    final files = <String>[];
    String? nextUrl = baseUrl;

    while (nextUrl != null) {
      final response = await http.get(Uri.parse(nextUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load page: $nextUrl');
      }

      final document = parse(response.body);
      
      // Find all download options
      final options = document.querySelectorAll('select.js_downloads-select option');
      for (final opt in options) {
        final href = opt.attributes['value'];
        if (href != null && href.endsWith('.bnl')) {
          final fileName = _extractFileName(opt.text);
          if (fileName != null) {
            files.add(fileName);
          }
        }
      }

      // Find next page link
      final nextLink = document.querySelector('ul.pagination li a[rel="next"]');
      nextUrl = nextLink?.attributes['href'];
      if (nextUrl != null) {
        nextUrl = Uri.parse(baseUrl).resolve(nextUrl).toString();
      }

      // Be nice to the server
      await Future.delayed(const Duration(seconds: 1));
    }

    return files;
  }

  String? _extractFileName(String text) {
    final regex = RegExp(r'([^/\\]+\.(?:BNL|bnl))');
    final match = regex.firstMatch(text);
    return match?.group(1);
  }

  Future<void> downloadFile(String fileName, String url, void Function(DownloadProgress) onProgress) async {
    final dir = Directory(downloadDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Raspundel-Updater/1.0'},
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        onProgress(DownloadProgress(
          fileName: fileName,
          status: DownloadStatus.completed,
          progress: 1.0,
        ));
      } else {
        onProgress(DownloadProgress(
          fileName: fileName,
          status: DownloadStatus.error,
          error: 'HTTP ${response.statusCode}',
        ));
      }
    } catch (e) {
      onProgress(DownloadProgress(
        fileName: fileName,
        status: DownloadStatus.error,
        error: e.toString(),
      ));
    }
  }
}
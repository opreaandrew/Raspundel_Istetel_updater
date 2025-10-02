import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../models/file_models.dart';

import 'package:path/path.dart' as path;

class DownloaderService {
  static const String baseUrl = 'https://www.raspundelistetel.ro/ro/fisiere-pentru-descarcare';
  final String downloadDir;

  DownloaderService({required this.downloadDir});

  Future<List<String>> getAvailableFiles() async {
    final files = <String>[];
    String? nextUrl = baseUrl;
    final client = http.Client();

    try {
      while (nextUrl != null) {
        print('\n🌐 $nextUrl');
        final response = await client.get(Uri.parse(nextUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to load page: $nextUrl');
        }

        final document = parse(response.body);
        
        // Find all download options
        final options = document.querySelectorAll('select.js_downloads-select option');
        print('Found ${options.length} options on page');
        
        for (final opt in options) {
          final href = opt.attributes['value'];
          if (href != null && href.toLowerCase().endsWith('.bnl')) {
            final fullUrl = Uri.parse(baseUrl).resolve(href).toString();
            if (!files.contains(fullUrl)) {
              files.add(fullUrl);
              print('Found file: ${href.split('/').last} from href: $fullUrl');
            }
          }
        }

        // Find next page link - exactly like Python
        final nextLink = document.querySelector('ul.pagination li a[rel="next"]');
        if (nextLink != null) {
          final nextHref = nextLink.attributes['href'];
          if (nextHref != null) {
            nextUrl = Uri.parse(baseUrl).resolve(nextHref).toString();
          } else {
            nextUrl = null;
          }
        } else {
          nextUrl = null;
        }

        // Be nice to the server
        await Future.delayed(const Duration(seconds: 1));
      }
    } finally {
      client.close();
    }
    
    print('\n📦 Total files: ${files.length}');

    print('Total files found: ${files.length}');
    return files;
  }

  String? _extractFileName(String text) {
    // First try to extract from href if available
    if (text.toLowerCase().endsWith('.bnl')) {
      return text;
    }
    
    // Handle special cases like "BIBLIA PENTRU COPII - BNL"
    final specialCase = text.split('-').map((s) => s.trim());
    for (final part in specialCase) {
      if (part.toUpperCase() != 'BNL' && part.contains('BNL')) {
        final normalized = part
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'\([^)]*\)'), '') // remove size in parentheses
            .trim()
            .toLowerCase();
        return '${normalized}.bnl';
      }
    }
    
    // Standard case: try to find filename patterns
    final patterns = [
      RegExp(r'([^/\\]+\.(?:BNL|bnl))', caseSensitive: true),
      RegExp(r'([^/\\(]+)(?:\s*-\s*BNL|\s+BNL)'), // matches "Name - BNL" or "Name BNL"
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final filename = match.group(1)!
            .replaceAll(' ', '_')
            .replaceAll(RegExp(r'\s+'), '_')
            .toLowerCase();
        final result = filename.toLowerCase().endsWith('.bnl') 
            ? filename 
            : '${filename}.bnl';
        print('Extracted filename: $result from "$text"');
        return result;
      }
    }
    
    print('Could not extract filename from: $text');
    return null;
  }

  Future<void> downloadFile(String url, Function(DownloadProgress) onProgress, int currentFileIndex, int totalFiles) async {
    final dir = Directory(downloadDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final fileName = url.split('/').last;
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final contentLength = response.contentLength ?? 0;
        int received = 0;
        int lastReceived = 0;
        final stopwatch = Stopwatch()..start();
        var lastTime = stopwatch.elapsedMilliseconds;

        final sink = file.openWrite();
        await response.stream.forEach((chunk) {
          sink.add(chunk);
          received += chunk.length;
          
          final now = stopwatch.elapsedMilliseconds;
          if (now - lastTime >= 1000) { // Update every second
            final bytesPerSecond = (received - lastReceived) * (1000 / (now - lastTime));
            final speedMBps = bytesPerSecond / (1024 * 1024);
            lastReceived = received;
            lastTime = now;
            
            if (contentLength > 0) {
              onProgress(DownloadProgress(
                fileName: fileName,
                status: DownloadStatus.downloading,
                progress: received / contentLength,
                speedMBps: speedMBps,
                currentFileIndex: currentFileIndex,
                totalFiles: totalFiles,
              ));
            }
          }
        });

        await sink.close();
        onProgress(DownloadProgress(
          fileName: fileName,
          status: DownloadStatus.completed,
          progress: 1.0,
          speedMBps: 0,
          currentFileIndex: currentFileIndex,
          totalFiles: totalFiles,
        ));
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }
}
import 'dart:typed_data';
import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart' as downloader;

class PdfDownloader {
  /// Downloads or saves a PDF file across Web and native Flutter environments.
  static void download(Uint8List bytes, String filename) {
    downloader.downloadPdfFile(bytes, filename);
  }
}

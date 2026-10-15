// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

Future<String?> pickImageAsBase64() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false
    ..style.display = 'none';

  html.document.body?.append(input);

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoadEnd.listen((e) {
      input.remove();
      final result = reader.result;
      if (result is String) {
        if (!completer.isCompleted) completer.complete(result);
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });
    reader.onError.listen((e) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
    });
  });

  input.click();
  return completer.future;
}

Future<String?> pickImageFromCameraAsBase64() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..setAttribute('capture', 'user')
    ..multiple = false
    ..style.display = 'none';

  html.document.body?.append(input);

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    reader.onLoadEnd.listen((e) {
      input.remove();
      final result = reader.result;
      if (result is String) {
        if (!completer.isCompleted) completer.complete(result);
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });
    reader.onError.listen((e) {
      input.remove();
      if (!completer.isCompleted) completer.complete(null);
    });
  });

  input.click();
  return completer.future;
}

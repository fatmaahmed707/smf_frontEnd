// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickProfileImageDataUrlImpl() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..click();

  input.onChange.first.then((_) {
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) => completer.complete(null));
    reader.onLoad.first.then((_) {
      final result = reader.result;
      completer.complete(result is String ? result : null);
    });
    reader.readAsDataUrl(file);
  });

  return completer.future;
}

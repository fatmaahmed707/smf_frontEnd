import 'profile_image_picker_stub.dart'
    if (dart.library.html) 'profile_image_picker_web.dart';

Future<String?> pickProfileImageDataUrl() => pickProfileImageDataUrlImpl();

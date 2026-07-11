import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies picked images into the app's documents directory so they
/// survive after the picker's temporary files are cleaned up.
class PhotoStorage {
  Future<String> savePetPhoto(String sourcePath) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'pet_photos'));
    await dir.create(recursive: true);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final saved = await File(sourcePath).copy(p.join(dir.path, fileName));
    return saved.path;
  }

  Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

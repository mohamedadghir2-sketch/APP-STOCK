import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copie les photos choisies dans le dossier privé de l'application.
///
/// En base de données on ne stocke que le **nom du fichier** : le chemin
/// absolu est reconstruit au démarrage, ce qui évite les liens cassés après
/// une mise à jour de l'application.
class PhotoStorage {
  PhotoStorage._();

  static Directory? _dir;
  static final ImagePicker _picker = ImagePicker();

  /// À appeler une seule fois dans `main()`.
  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _dir = dir;
  }

  static String? fullPath(String? fileName) {
    if (_dir == null || fileName == null || fileName.isEmpty) return null;
    return p.join(_dir!.path, fileName);
  }

  /// Retourne le fichier s'il existe réellement sur le disque.
  static File? fileFor(String? fileName) {
    final path = fullPath(fileName);
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// Ouvre l'appareil photo ou la galerie et renvoie le nom du fichier copié.
  static Future<String?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _save(picked);
  }

  static Future<String> _save(XFile file) async {
    final extension =
        p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
    final name = 'shoe_${DateTime.now().microsecondsSinceEpoch}$extension';
    await File(file.path).copy(p.join(_dir!.path, name));
    return name;
  }

  static Future<void> delete(String? fileName) async {
    final file = fileFor(fileName);
    if (file == null) return;
    try {
      await file.delete();
    } catch (_) {
      // Le fichier a déjà disparu : rien à faire.
    }
  }
}

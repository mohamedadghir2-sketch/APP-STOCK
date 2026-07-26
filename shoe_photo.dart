import 'package:flutter/material.dart';

import '../utils/photo_storage.dart';

/// Affiche la photo d'une référence, ou un cadre neutre si elle n'en a pas.
class ShoePhoto extends StatelessWidget {
  const ShoePhoto({
    super.key,
    required this.fileName,
    this.width,
    this.height,
    this.radius = 16,
    this.iconSize = 26,
  });

  final String? fileName;
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = PhotoStorage.fileFor(fileName);

    final Widget child = file != null
        ? Image.file(
            file,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) => _placeholder(scheme),
            gaplessPlayback: true,
          )
        : _placeholder(scheme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest.withOpacity(0.55),
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_camera_outlined,
        size: iconSize,
        color: scheme.onSurfaceVariant.withOpacity(0.7),
      ),
    );
  }
}

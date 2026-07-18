import 'dart:io';

import 'package:flutter/material.dart';

import '../util/image_store.dart';

/// A small rounded product image loaded from disk by filename (see ImageStore).
///
/// Renders nothing when [filename] is null/empty, when the store isn't ready,
/// or when the file can't be decoded — so callers can drop it in unconditionally.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.filename, {super.key, this.size = 44, this.radius = 8});

  final String? filename;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = filename;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    final path = ImageStore.instance.pathFor(name);
    if (path == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        // Keep the decoded bitmap small — these are thumbnails.
        cacheWidth: (size * 3).round(),
        filterQuality: FilterQuality.low,
      ),
    );
  }
}

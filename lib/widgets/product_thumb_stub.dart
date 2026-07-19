import 'package:flutter/material.dart';

/// Fallback: no image rendering. Mirrors the web variant.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.filename, {super.key, this.size = 44, this.radius = 8});

  final String? filename;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

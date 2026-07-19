import 'package:flutter/material.dart';

/// Web build: product images are disabled (v1), so the thumbnail renders
/// nothing. Same constructor as the IO variant so call sites are identical.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.filename, {super.key, this.size = 44, this.radius = 8});

  final String? filename;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

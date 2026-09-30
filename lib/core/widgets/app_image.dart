import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image universelle — gère les 3 sources utilisées par l'app :
///  • `https://...`   → réseau (Firebase Storage, plan A)
///  • `asset:...`     → assets embarqués (images de test du seed)
///  • `data:image/...;base64,...` → base64 Firestore (plan B, plan Spark)
class AppImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AppImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.image_outlined,
              color: Theme.of(context).colorScheme.outline),
        );

    final src = url;
    if (src == null || src.isEmpty) return placeholder();

    if (src.startsWith('asset:')) {
      return Image.asset(src.substring(6),
          fit: fit, width: width, height: height,
          errorBuilder: (_, __, ___) => placeholder());
    }
    if (src.startsWith('data:image')) {
      try {
        final bytes = base64Decode(src.split(',').last);
        return Image.memory(bytes,
            fit: fit, width: width, height: height,
            errorBuilder: (_, __, ___) => placeholder());
      } catch (_) {
        return placeholder();
      }
    }
    return CachedNetworkImage(
      imageUrl: src,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder(),
      errorWidget: (_, __, ___) => placeholder(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DriverAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String cacheKey;

  const DriverAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 50.0,
    required this.cacheKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: radius > 30 ? 3 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: radius > 30 ? 8 : 4,
            offset: Offset(0, radius > 30 ? 4 : 2),
          ),
        ],
      ),
      child: ClipOval(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  key: ValueKey(cacheKey),
                  imageUrl: imageUrl,
                  cacheKey: cacheKey,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(Icons.person, color: Colors.grey, size: radius),
                  ),
                )
              : Container(
                  key: const ValueKey('empty_avatar'),
                  color: Colors.grey.shade200,
                  child: Icon(Icons.person, color: Colors.grey, size: radius),
                ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that can display images from network URLs or base64 data URIs
class FlexibleImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FlexibleImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? _defaultErrorWidget();
    }

    // Check if it's a base64 data URI
    if (imageUrl!.startsWith('data:image/')) {
      try {
        // Extract base64 string from data URI
        final base64String = imageUrl!.split(',')[1];
        final imageBytes = base64Decode(base64String);
        
        return Image.memory(
          imageBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? _defaultErrorWidget();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return errorWidget ?? _defaultErrorWidget();
      }
    } else {
      // Regular network image with better error handling
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _defaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          // Silently handle 404 errors - don't log to avoid spam
          // Suppress the exception from being logged
          if (error.toString().contains('404') || 
              error.toString().contains('statusCode: 404') ||
              error.toString().contains('NetworkImageLoadException')) {
            // 404 is expected for missing images - just show fallback silently
            // Use FlutterError to suppress the exception
            FlutterError.onError?.call(FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'image resource service',
              silent: true, // Suppress the error
            ));
            return errorWidget ?? _defaultErrorWidget();
          }
          // Log other errors for debugging (non-404 errors)
          print('Image load error for URL: $imageUrl');
          print('Error: $error');
          return errorWidget ?? _defaultErrorWidget();
        },
        // Add headers to prevent CORS issues
        headers: const {
          'Accept': 'image/*',
        },
        // Cache the image to avoid repeated failed requests
        cacheWidth: width?.toInt(),
        cacheHeight: height?.toInt(),
      );
    }
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
      ),
    );
  }
}

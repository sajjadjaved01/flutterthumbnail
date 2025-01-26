import 'flutterthumbnail_platform_interface.dart';
import 'package:flutter/services.dart';

/// Uses libwebp to encode WebP image on iOS platform.
enum ImageFormat { JPEG, PNG, WEBP }

class Flutterthumbnail {
  static const MethodChannel _channel = MethodChannel('flutterthumbnail');

  Future<String?> getPlatformVersion() {
    return FlutterthumbnailPlatform.instance.getPlatformVersion();
  }

  /// Generates a thumbnail file from a video.
  /// The video can be a local file path or URL (iOS/Android supported formats).
  ///
  /// Parameters:
  /// - [video]: Required path/URL to video file
  /// - [headers]: Optional HTTP headers for video URL requests
  /// - [path]: Optional output path for thumbnail file
  /// - [format]: Image format (JPEG, PNG, WEBP), defaults to JPEG
  /// - [maxh]: Maximum height of thumbnail (0 for original video height)
  /// - [maxw]: Maximum width of thumbnail (0 for original video width)
  /// - [timeMs]: Video position for thumbnail in milliseconds
  /// - [quality]: JPEG/WebP quality 0-100 (ignored for PNG)
  Future<String?> file({
    required String video,
    Map<String, String>? headers,
    String? path,
    ImageFormat format = ImageFormat.JPEG,
    int maxh = 0,
    int maxw = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    assert(video.isNotEmpty);
    if (video.isEmpty) return null;

    final reqMap = <String, dynamic>{
      'video': video,
      'headers': headers,
      'path': path,
      'format': format.index,
      'maxh': maxh,
      'maxw': maxw,
      'timeMs': timeMs,
      'quality': quality
    };

    return await _channel.invokeMethod('file', reqMap);
  }

  /// Generates a thumbnail as raw image data (Uint8List).
  /// The video can be a local file path or URL (iOS/Android supported formats).
  ///
  /// Parameters:
  /// - [video]: Required path/URL to video file
  /// - [headers]: Optional HTTP headers for video URL requests
  /// - [format]: Image format (JPEG, PNG, WEBP), defaults to JPEG
  /// - [maxh]: Maximum height of thumbnail (0 for original video height)
  /// - [maxw]: Maximum width of thumbnail (0 for original video width)
  /// - [timeMs]: Video position for thumbnail in milliseconds
  /// - [quality]: JPEG/WebP quality 0-100 (ignored for PNG)
  Future<Uint8List?> data({
    required String video,
    Map<String, String>? headers,
    ImageFormat format = ImageFormat.JPEG,
    int maxh = 0,
    int maxw = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    assert(video.isNotEmpty);
    if (video.isEmpty) return null;

    final reqMap = <String, dynamic>{
      'video': video,
      'headers': headers,
      'format': format.index,
      'maxh': maxh,
      'maxw': maxw,
      'timeMs': timeMs,
      'quality': quality,
    };

    return await _channel.invokeMethod('data', reqMap);
  }
}

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutterthumbnail_method_channel.dart';

abstract class FlutterthumbnailPlatform extends PlatformInterface {
  /// Constructs a FlutterthumbnailPlatform.
  FlutterthumbnailPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterthumbnailPlatform _instance = MethodChannelFlutterthumbnail();

  /// The default instance of [FlutterthumbnailPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterthumbnail].
  static FlutterthumbnailPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterthumbnailPlatform] when
  /// they register themselves.
  static set instance(FlutterthumbnailPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

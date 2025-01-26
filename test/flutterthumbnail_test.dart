import 'package:flutter_test/flutter_test.dart';
import 'package:flutterthumbnail/flutterthumbnail.dart';
import 'package:flutterthumbnail/flutterthumbnail_platform_interface.dart';
import 'package:flutterthumbnail/flutterthumbnail_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterthumbnailPlatform
    with MockPlatformInterfaceMixin
    implements FlutterthumbnailPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterthumbnailPlatform initialPlatform = FlutterthumbnailPlatform.instance;

  test('$MethodChannelFlutterthumbnail is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterthumbnail>());
  });

  test('getPlatformVersion', () async {
    Flutterthumbnail flutterthumbnailPlugin = Flutterthumbnail();
    MockFlutterthumbnailPlatform fakePlatform = MockFlutterthumbnailPlatform();
    FlutterthumbnailPlatform.instance = fakePlatform;

    expect(await flutterthumbnailPlugin.getPlatformVersion(), '42');
  });
}

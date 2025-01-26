import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutterthumbnail/flutterthumbnail.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _flutterthumbnailPlugin = Flutterthumbnail();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _flutterthumbnailPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Video Thumbnail Example'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final thumbnail = Flutterthumbnail();
              final thumbnailPath = await thumbnail.file(
                video: 'https://firebasestorage.googleapis.com/v0/b/app-zoeta-dogsoul.firebasestorage.app/o/videos%2Fyes_and_no_achieve%20(1080p).mp4?alt=media&token=173dd3bc-ce10-4b25-8926-7eb22b1e4eea',
                format: ImageFormat.PNG, // JPEG
                maxh: 200,
                maxw: 200,
                timeMs: 1000,
                quality: 90,
              );
              print('Thumbnail saved to: $thumbnailPath');
            },
            child: Text('Generate Thumbnail'),
          ),
        ),
      ),
    );
  }
}

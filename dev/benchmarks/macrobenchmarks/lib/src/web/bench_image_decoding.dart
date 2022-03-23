// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'recorder.dart';

/// Measures the performance of image decoding.
///
/// The benchmark measures the decoding latency and not impact on jank. It
/// cannot distinguish between blocking and non-blocking decoding. It simply
/// measures the total time it takes to decode image frames. For example, the
/// WASM codecs execute on the main thread and block the UI, leading to jank,
/// but the browser's WebCodecs API is asynchronous running on a separate thread
/// and does not jank. However, the benchmark result may be the same.
///
/// This benchmark does not support the HTML renderer because the HTML renderer
/// cannot decode image frames (it always returns 1 dummy frame, even for
/// animated images).
class BenchImageDecoding extends RawRecorder {
  BenchImageDecoding()
      : super(
          name: benchmarkName,
          useCustomWarmUp: true,
        );

  static const String benchmarkName = 'bench_image_decoding';

  // These test images are taken from https://github.com/flutter/flutter_gallery_assets/tree/master/lib/splash_effects
  static const List<String> _imageUrls = <String>[
    'assets/packages/flutter_gallery_assets/splash_effects/splash_effect_1.gif',
    'assets/packages/flutter_gallery_assets/splash_effects/splash_effect_2.gif',
    'assets/packages/flutter_gallery_assets/splash_effects/splash_effect_3.gif',
  ];

  final List<Uint8List> _imageData = <Uint8List>[];

  @override
  Future<void> setUpAll() async {
    if (_imageData.isNotEmpty) {
      return;
    }
    for (final String imageUrl in _imageUrls) {
      final html.Body image = await html.window.fetch(imageUrl) as html.Body;
      _imageData.add((await image.arrayBuffer() as ByteBuffer).asUint8List());
    }
  }

  // The number of samples recorded so far.
  int _sampleCount = 0;

  // The number of samples used for warm-up.
  static const int _warmUpSampleCount = 5;

  // The number of samples used to measure performance after the warm-up.
  static const int _measuredSampleCount = 20;

  @override
  Future<void> body(Profile profile) async {
    await profile.recordAsync('recordImageDecode', () async {
      final List<Future<void>> allDecodes = <Future<void>>[
        for (final Uint8List data in _imageData) _decodeImage(data),
      ];
      await Future.wait(allDecodes);
    }, reported: true);

    _sampleCount += 1;
    if (_sampleCount == _warmUpSampleCount) {
      profile.stopWarmingUp();
    }
    if (_sampleCount >= _warmUpSampleCount + _measuredSampleCount) {
      profile.stopBenchmark();
    }
  }
}

Future<void> _decodeImage(Uint8List data) async {
  final ui.Codec codec = await ui.instantiateImageCodec(data);
  const int decodeFrameCount = 5;
  if (codec.frameCount < decodeFrameCount) {
    throw Exception(
        'Test image contains too few frames for this benchmark (${codec.frameCount}). '
        'Choose a test image with at least $decodeFrameCount frames.');
  }
  for (int i = 0; i < decodeFrameCount; i++) {
    (await codec.getNextFrame()).image.dispose();
  }
  codec.dispose();
}

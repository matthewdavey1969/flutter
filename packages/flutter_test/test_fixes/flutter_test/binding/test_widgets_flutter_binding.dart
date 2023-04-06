// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:clock/src/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  TestWidgetsFlutterBinding binding = FakeTestWidgetsFlutterBinding();
  binding.runTest(
    () async {
      // This will be unchanged as there is no equivalent API.
      binding.addTime(Duration(seconds: 30));

      await binding.runAsync(
        () async {},
        // The `additionalTime` parameter will be removed
        additionalTime: Duration(seconds: 25),
      );
    },
    () { },
    // This timeout will be removed and not replaced since there is no
    // equivalent API at this layer.
    timeout: Duration(minutes: 30),
  );
}

class FakeTestWidgetsFlutterBinding extends TestWidgetsFlutterBinding {
  @override
  Clock get clock => throw UnimplementedError();

  @override
  Timeout get defaultTestTimeout => throw UnimplementedError();

  @override
  Future<void> delayed(Duration duration) {
    throw UnimplementedError();
  }

  @override
  bool get inTest => throw UnimplementedError();

  @override
  int get microtaskCount => throw UnimplementedError();

  @override
  Future<void> pump([Duration? duration, EnginePhase newPhase = EnginePhase.sendSemanticsUpdate]) {
    throw UnimplementedError();
  }

  @override
  Future<T?> runAsync<T>(Future<T> Function() callback, {Duration additionalTime = const Duration(milliseconds: 1000)}) {
    throw UnimplementedError();
  }

  @override
  Future<void> runTest(Future<void> Function() testBody, VoidCallback invariantTester, {String description = '', Duration? timeout}) {
    throw UnimplementedError();
  }
}
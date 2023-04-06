// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test', (WidgetTester tester) async {
    final AnimationSheetBuilder animationSheet =
        AnimationSheetBuilder(frameSize: const Size(48, 24));

    await tester.pumpFrames(
      animationSheet.record(const CircularProgressIndicator()),
      const Duration(seconds: 1),
    );

    // This line will remain unchanged as there is no replacement for the
    // `sheetSize` API.
    tester.binding.setSurfaceSize(animationSheet.sheetSize());

    // This line will replace the call to `display` with a call to `collate`
    // but will still have a build error.
    final Widget display = await animationSheet.display();
    final Widget display2 = await animationSheet.display(key: UniqueKey());
  });
}

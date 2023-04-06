// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test', (WidgetTester tester) async {
    // This call will be unchanged
  }, timeout: Timeout(Duration(hours: 1)));

  testWidgets('test', (WidgetTester tester) async {
    // The `timeout` will remain unchanged, but `initialTimeout` will be removed
  },
  timeout: Timeout(Duration(minutes: 45)),
  initialTimeout: Duration(minutes: 30));

  testWidgets('test', (WidgetTester tester) async {
    // initialTimeout will be wrapped in a Timeout and changed to `timeout`
  }, initialTimeout: Duration(seconds: 30));
}

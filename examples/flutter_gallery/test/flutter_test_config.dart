// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main(FutureOr<void> testMain()) async {
  goldenFileComparator = await FlutterGoldenFileComparator.fromDefaultComparator();
  await testMain();
}

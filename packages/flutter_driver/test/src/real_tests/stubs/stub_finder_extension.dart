// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_test/src/finders.dart';
import 'package:flutter_driver/src/common/find.dart';

import 'stub_finder.dart';

class StubFinderExtension extends FinderExtension {
  @override
  Finder createFinder(SerializableFinder finder) {
    return find.byWidgetPredicate((Widget widget) {
      return widget.key.toString() == (finder as StubFinder).keyString;
    });
  }

  @override
  SerializableFinder deserialize(
      Map<String, String> params, DeserializeFinderFactory finderFactory) {
    return StubFinder(params['keyString']);
  }

  @override
  String get finderType => 'Stub';
}

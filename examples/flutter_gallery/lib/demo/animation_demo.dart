// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'animation/home.dart';

class AnimationDemo extends StatelessWidget {
  const AnimationDemo({Object debugLocation, Key key}) : super(debugLocation: debugLocation, key: key);

  static const String routeName = '/animation';

  @override
  Widget build(BuildContext context) => const AnimationDemoHome();
}

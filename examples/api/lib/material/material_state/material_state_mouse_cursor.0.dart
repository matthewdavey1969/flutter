// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [MaterialStateMouseCursor].

void main() => runApp(const MaterialStateMouseCursorExampleApp());

class MaterialStateMouseCursorExampleApp extends StatelessWidget {
  const MaterialStateMouseCursorExampleApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const Center(
          child: MaterialStateMouseCursorExample(),
        ),
      ),
    );
  }
}

class ListTileCursor extends MaterialStateMouseCursor {
  const ListTileCursor();

  @override
  MouseCursor resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.disabled)) {
      return SystemMouseCursors.forbidden;
    }
    return SystemMouseCursors.click;
  }

  @override
  String get debugDescription => 'ListTileCursor()';
}

class MaterialStateMouseCursorExample extends StatelessWidget {
  const MaterialStateMouseCursorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      title: Text('Disabled ListTile'),
      enabled: false,
      mouseCursor: ListTileCursor(),
    );
  }
}

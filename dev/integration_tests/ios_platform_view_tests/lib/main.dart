// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  // enableFlutterDriverExtension() will disable keyboard,
  // which is required for flutter_driver tests
  // But breaks the XCUITests
  if (const bool.fromEnvironment('ENABLE_DRIVER_EXTENSION', defaultValue: false)) {
    enableFlutterDriverExtension();
  }
  runApp(const MyApp());
}

/// The main app entrance of the test
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// A page with several buttons in the center.
///
/// On press the button, a page with platform view should be pushed into the scene.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});
  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? ''),
      ),
      body: Column(children: <Widget>[
        TextButton(
          key: const ValueKey<String>('platform_view_button'),
          child: const Text('show platform view'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<MergeThreadTestPage>(
                  builder: (BuildContext context) => const MergeThreadTestPage()),
            );
          },
        ),
        // Push this button to perform an animation, which ensure the threads are unmerged after the animation.
        ElevatedButton(
          key: const ValueKey<String>('unmerge_button'),
          child: const Text('Tap to unmerge threads'),
          onPressed: () {},
        ),
        TextButton(
          key: const ValueKey<String>('platform_view_focus_test'),
          child: const Text('platform view focus test'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<FocusTestPage>(
                  builder: (BuildContext context) => const FocusTestPage()),
            );
          },
        ),
      ]),
    );
  }
}

/// A page to test thread merge for platform view.
class MergeThreadTestPage extends StatelessWidget {
  const MergeThreadTestPage({super.key});

  static Key button = const ValueKey<String>('plus_button');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform View Thread Merge Tests'),
      ),
      body: Column(
        children: <Widget>[
          const Expanded(
            child: SizedBox(
              width: 300,
              child: UiKitView(viewType: 'platform_view'),
            ),
          ),
          ElevatedButton(
            key: button,
            child: const Text('button'),
            onPressed: (){},
          ),
        ],
      ),
    );
  }
}

/// A page to test platform view focus.
class FocusTestPage extends StatefulWidget {
  const FocusTestPage({super.key});

  @override
  State<FocusTestPage> createState() => _FocusTestPageState();
}

class _FocusTestPageState extends State<FocusTestPage> {

  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = "Flutter Text Input";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform View Focus Tests'),
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(
            width: 300,
            height: 50,
            child: UiKitView(viewType: 'platform_text_field'),
          ),
          TextField(
            controller: _controller,
          ),
        ],
      ),
    );
  }
}
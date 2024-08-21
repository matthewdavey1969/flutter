// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'use_cases.dart';

class TextButtonUseCase extends UseCase {
  @override
  String get name => 'TextButton';

  @override
  String get route => '/text-button';

  @override
  Widget build(BuildContext context) => const MainWidget();
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => MainWidgetState();
}

class MainWidgetState extends State<MainWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Semantics(headingLevel: 1, child: const Text('TextButton Demo')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MergeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('This is a TextButton:'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _count++;
                      });
                    },
                    child: const Text('Action'),
                  ),
                  Text('Clicked $_count time(s).'),
                ],
              ),
            ),
            const MergeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('This is a disabled TextButton:'),
                  TextButton(
                    onPressed: null,
                    child: Text('Action Disabled'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

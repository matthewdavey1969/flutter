// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/playground/playground_demo.dart';
import 'package:flutter_gallery/demo/playground/configuration/material_helpers.dart';

const String _demoWidgetName = 'Slider';

class SliderDemo extends PlaygroundDemo {
  Color _activeColor = Colors.blue;
  Color _inactiveColor = Colors.blue;
  double _value = 5.0;

  @override
  String tabName() => _demoWidgetName.toUpperCase();

  @override
  String codePreview() => '''
Slider(
  value: $_value,
  min: 0.0,
  max: 10.0,
  divisions: 10,
  activeColor: ${codeSnippetForColor(_activeColor)},
  inactiveColor: ${codeSnippetForColor(_inactiveColor)},
  onChanged: (double value) {},
)
''';

  @override
  Widget configWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        colorPicker(
          label: 'Active Color',
          selectedValue: _activeColor,
          onItemTapped: (int index, Color color) {
            updateConfiguration(() {
              _activeColor = color;
            });
          }
        ),
      ],
    );
  }

  @override
  Widget previewWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0).copyWith(right: 25.0),
      child: Slider(
        value: _value,
        min: 0.0,
        max: 10.0,
        divisions: 10,
        activeColor: _activeColor,
        inactiveColor: _inactiveColor,
        onChanged: (double value) {
          updateConfiguration(() {
            _value = value;
          });
        },
      ),
    );
  }
}

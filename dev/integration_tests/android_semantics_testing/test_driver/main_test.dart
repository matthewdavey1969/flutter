// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:android_semantics_testing/test_constants.dart';
import 'package:android_semantics_testing/android_semantics_testing.dart';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;
import 'package:flutter_driver/flutter_driver.dart';
import 'package:path/path.dart' as path;

String adbPath() {
  final String androidHome = io.Platform.environment['ANDROID_HOME'] ?? io.Platform.environment['ANDROID_SDK_ROOT'];
  if (androidHome == null) {
    return 'adb';
  } else {
    return path.join(androidHome, 'platform-tools', 'adb');
  }
}

void main() {
  group('AccessibilityBridge', () {
    FlutterDriver driver;
    Future<AndroidSemanticsNode> getSemantics(SerializableFinder finder) async {
      final int id = await driver.getSemanticsId(finder);
      final String data = await driver.requestData('getSemanticsNode#$id');
      return AndroidSemanticsNode.deserialize(data);
    }

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      // Say the magic words..
      final io.Process run = await io.Process.start(adbPath(), const <String>[
        'shell',
        'settings',
        'put',
        'secure',
        'enabled_accessibility_services',
        'com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService',
      ]);
      await run.exitCode;
    });

    tearDownAll(() async {
      // ... And turn it off again
      final io.Process run = await io.Process.start(adbPath(), const <String>[
        'shell',
        'settings',
        'put',
        'secure',
        'enabled_accessibility_services',
        'null',
      ]);
      await run.exitCode;
      driver?.close();
    });

    group('TextField', () {
      setUpAll(() async {
        await driver.tap(find.text(textFieldRoute));
      });

      test('TextField has correct Android semantics', () async {
        final SerializableFinder normalTextField = find.descendant(
          of: find.byValueKey(normalTextFieldKeyValue),
          matching: find.byType('Semantics'),
          firstMatchOnly: true,
        );
        expect(await getSemantics(normalTextField), hasAndroidSemantics(
          className: AndroidClassName.editText,
          isEditable: true,
          isFocusable: true,
          isFocused: false,
          isPassword: false,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));

        await driver.tap(normalTextField);

        expect(await getSemantics(normalTextField), hasAndroidSemantics(
          className: AndroidClassName.editText,
          isFocusable: true,
          isFocused: true,
          isEditable: true,
          isPassword: false,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.clearAccessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.copy,
            AndroidSemanticsAction.focus,
            AndroidSemanticsAction.setSelection,
          ],
        ));

        await driver.enterText('hello world');

        expect(await getSemantics(normalTextField), hasAndroidSemantics(
          text: 'hello world',
          className: AndroidClassName.editText,
          isFocusable: true,
          isFocused: true,
          isEditable: true,
          isPassword: false,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.clearAccessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.copy,
            AndroidSemanticsAction.focus,
            AndroidSemanticsAction.setSelection,
          ],
        ));
      });

      test('password TextField has correct Android semantics', () async {
        final SerializableFinder passwordTextField = find.descendant(
          of: find.byValueKey(passwordTextFieldKeyValue),
          matching: find.byType('Semantics'),
          firstMatchOnly: true,
        );
        expect(await getSemantics(passwordTextField), hasAndroidSemantics(
          className: AndroidClassName.editText,
          isEditable: true,
          isFocusable: true,
          isFocused: false,
          isPassword: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));

        await driver.tap(passwordTextField);

        expect(await getSemantics(passwordTextField), hasAndroidSemantics(
          className: AndroidClassName.editText,
          isFocusable: true,
          isFocused: true,
          isEditable: true,
          isPassword: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.clearAccessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.copy,
            AndroidSemanticsAction.focus,
            AndroidSemanticsAction.setSelection,
          ],
        ));

        await driver.enterText('hello world');

        expect(await getSemantics(passwordTextField), hasAndroidSemantics(
          text: '\u{2022}' * ('hello world'.length),
          className: AndroidClassName.editText,
          isFocusable: true,
          isFocused: true,
          isEditable: true,
          isPassword: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.clearAccessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.copy,
            AndroidSemanticsAction.focus,
            AndroidSemanticsAction.setSelection,
          ],
        ));
      });

      tearDownAll(() async {
        await driver.tap(find.byValueKey('back'));
      });
    });

    group('SelectionControls', () {
      setUpAll(() async {
        await driver.tap(find.text(selectionControlsRoute));
      });

      test('Checkbox has correct Android semantics', () async {
        expect(await getSemantics(find.byValueKey(checkboxKeyValue)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isChecked: false,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));

        await driver.tap(find.byValueKey(checkboxKeyValue));

        expect(await getSemantics(find.byValueKey(checkboxKeyValue)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isChecked: true,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));
        expect(await getSemantics(find.byValueKey(disabledCheckboxKeyValue)), hasAndroidSemantics(
          className: AndroidClassName.checkBox,
          isCheckable: true,
          isEnabled: false,
          actions: const <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.focus,
          ],
        ));
      });
      test('Radio has correct Android semantics', () async {
        expect(await getSemantics(find.byValueKey(radio2KeyValue)), hasAndroidSemantics(
          className: AndroidClassName.radio,
          isChecked: false,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));

        await driver.tap(find.byValueKey(radio2KeyValue));

        expect(await getSemantics(find.byValueKey(radio2KeyValue)), hasAndroidSemantics(
          className: AndroidClassName.radio,
          isChecked: true,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));
      });
      test('Switch has correct Android semantics', () async {
        expect(await getSemantics(find.byValueKey(switchKeyValue)), hasAndroidSemantics(
          className: AndroidClassName.toggleSwitch,
          isChecked: false,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));

        await driver.tap(find.byValueKey(switchKeyValue));

        expect(await getSemantics(find.byValueKey(switchKeyValue)), hasAndroidSemantics(
          className: AndroidClassName.toggleSwitch,
          isChecked: true,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));
      });

      // Regression test for https://github.com/flutter/flutter/issues/20820.
      test('Switch can be labeled', () async {
        expect(await getSemantics(find.byValueKey(labeledSwitchKeyValue)), hasAndroidSemantics(
          className: AndroidClassName.toggleSwitch,
          isChecked: false,
          isCheckable: true,
          isEnabled: true,
          isFocusable: true,
          contentDescription: switchLabel,
          actions: <AndroidSemanticsAction>[
            AndroidSemanticsAction.accessibilityFocus,
            AndroidSemanticsAction.click,
            AndroidSemanticsAction.focus,
          ],
        ));
      });

      tearDownAll(() async {
        await driver.tap(find.byValueKey('back'));
      });
    });
  });
}

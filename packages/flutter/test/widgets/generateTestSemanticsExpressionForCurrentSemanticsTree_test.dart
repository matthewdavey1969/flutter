// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  group('generateTestSemanticsExpressionForCurrentSemanticsTree', () {
    _tests();
  });
}

void _tests() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  Future<Null> pumpTestWidget(WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: new ListView(
        children: <Widget>[
          const Text('Plain text'),
          new Semantics(
            selected: true,
            onTap: () {},
            value: 'test-value',
            increasedValue: 'test-increasedValue',
            decreasedValue: 'test-decreasedValue',
            hint: 'test-hint',
            textDirection: TextDirection.rtl,
            child: const Text('Interactive text'),
          ),
        ],
      ),
    ));
  }

  // This test generates code using generateTestSemanticsExpressionForCurrentSemanticsTree
  // then compares it to the code used in the 'generated code is correct' test
  // below. When you update the implementation of generateTestSemanticsExpressionForCurrentSemanticsTree
  // also update this code to reflect the new output.
  //
  // This test is flexible w.r.t. leading and trailing whitespace.
  testWidgets('generates code', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await pumpTestWidget(tester);
    final String code = semantics
      .generateTestSemanticsExpressionForCurrentSemanticsTree()
      .split('\n')
      .map((String line) => line.trim())
      .join('\n')
      .trim() + ',';
    String expectedCode = new File('test/widgets/generateTestSemanticsExpressionForCurrentSemanticsTree_test.dart').readAsStringSync();
    expectedCode = expectedCode.substring(
      expectedCode.indexOf('>' * 12) + 12,
      expectedCode.indexOf('<' * 12) - 3,
    )
      .split('\n')
      .map((String line) => line.trim())
      .join('\n')
      .trim();
    semantics.dispose();
    expect(code, expectedCode);
  });

  testWidgets('generated code is correct', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await pumpTestWidget(tester);
    expect(
      semantics,
      hasSemantics(
        // The code below delimited by > and < characters is generated by
        // generateTestSemanticsExpressionForCurrentSemanticsTree function.
        // You must update it when changing the output generated by
        // generateTestSemanticsExpressionForCurrentSemanticsTree. Otherwise,
        // the test 'generates code', defined above, will fail.
        // >>>>>>>>>>>>
        new TestSemantics(
          children: <TestSemantics>[
            new TestSemantics(
              children: <TestSemantics>[
                new TestSemantics(
                  children: <TestSemantics>[
                    new TestSemantics(
                      label: r'Plain text',
                      textDirection: TextDirection.ltr,
                    ),
                    new TestSemantics(
                      flags: 4,
                      actions: 1,
                      label: r'‪Interactive text‬',
                      value: r'test-value',
                      increasedValue: r'test-increasedValue',
                      decreasedValue: r'test-decreasedValue',
                      hint: r'test-hint',
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // <<<<<<<<<<<<
        ignoreRect: true,
        ignoreTransform: true,
        ignoreId: true,
      )
    );
    semantics.dispose();
  });
}

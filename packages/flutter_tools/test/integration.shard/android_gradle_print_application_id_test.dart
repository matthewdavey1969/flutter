// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart'
    show getGradlewFileName;
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext(
      'gradle task exists named print<mode>ApplicationId that prints application id', () async {
    // Create a new flutter project.
    final String flutterBin =
    fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      tempDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());
    // Ensure that gradle files exists from templates.
    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--config-only',
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());

    final Directory androidApp = tempDir.childDirectory('android');
    result = await processManager.run(<String>[
      '.${platform.pathSeparator}${getGradlewFileName(platform)}',
      ...getLocalEngineArguments(),
      '-q', // quiet output.
      'printDebugApplicationId',
    ], workingDirectory: androidApp.path);
    // Verify that gradlew has a javaVersion task.
    expect(result, const ProcessResultMatcher());
    // Verify the format is a number on its own line.
    const List<String> expectedLines = <String>[
      'ApplicationId: com.example.testapp',
    ];
    final List<String> actualLines = LineSplitter.split(result.stdout.toString()).toList();
    expect(const ListEquality<String>().equals(actualLines, expectedLines), isTrue);
  });
}

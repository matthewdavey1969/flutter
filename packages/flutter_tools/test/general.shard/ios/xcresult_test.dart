// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/ios/xcresult.dart';
import 'package:flutter_tools/src/macos/xcode.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import 'xcresult_test_data.dart';

void main() {
  // Creates a FakeCommand for the xcresult get call to build the app
  // in the given configuration.
  FakeCommand _setUpFakeXCResultGetCommand({
    required String stdout,
    required String tempResultPath,
    required Xcode xcode,
    int exitCode = 0,
    String stderr = '',
  }) {
    return FakeCommand(
      command: <String>[
        ...xcode.xcrunCommand(),
        'xcresulttool',
        'get',
        '--path',
        tempResultPath,
        '--format',
        'json',
      ],
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      onRun: () {},
    );
  }

  const FakeCommand _kWhichSysctlCommand = FakeCommand(
    command: <String>[
      'which',
      'sysctl',
    ],
  );

  const FakeCommand _kx64CheckCommand = FakeCommand(
    command: <String>[
      'sysctl',
      'hw.optional.arm64',
    ],
    exitCode: 1,
  );

  XCResultGenerator _setupGenerator({
    required String resultJson,
    int exitCode = 0,
    String stderr = '',
  }) {
    final FakeProcessManager fakeProcessManager =
        FakeProcessManager.list(<FakeCommand>[
      _kWhichSysctlCommand,
      _kx64CheckCommand,
    ]);
    final Xcode xcode = Xcode.test(
      processManager: fakeProcessManager,
      xcodeProjectInterpreter: XcodeProjectInterpreter.test(
        processManager: fakeProcessManager,
        version: null,
      ),
    );
    fakeProcessManager.addCommands(
      <FakeCommand>[
        _setUpFakeXCResultGetCommand(
          stdout: resultJson,
          tempResultPath: _tempResultPath,
          xcode: xcode,
          exitCode: exitCode,
          stderr: stderr,
        ),
      ],
    );
    final ProcessUtils processUtils = ProcessUtils(
      processManager: fakeProcessManager,
      logger: BufferLogger.test(),
    );
    return XCResultGenerator(
      resultPath: _tempResultPath,
      xcode: xcode,
      processUtils: processUtils,
    );
  }

  testWithoutContext(
      'correctly parse sample result json when there are issues.', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: kSampleResultJsonWithIssues);
    final XCResult result = await generator.generate();
    expect(result.issues.length, 2);
    expect(result.issues.first.type, XCResultIssueType.error);
    expect(result.issues.first.subType, 'Semantic Issue');
    expect(result.issues.first.message, "Use of undeclared identifier 'asdas'");
    expect(result.issues.first.location, 'file:///Users/m/Projects/test_create/ios/Runner/AppDelegate.m:7:56');
    expect(result.issues.last.type, XCResultIssueType.warning);
    expect(result.issues.last.subType, 'Warning');
    expect(result.issues.last.message,
        "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but the range of supported deployment target versions is 9.0 to 14.0.99.");
    expect(result.parseSuccess, isTrue);
    expect(result.parsingErrorMessage, isNull);
  });

  testWithoutContext('correctly parse sample result json when no issues.',
      () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: kSampleResultJsonNoIssues);
    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, isTrue);
    expect(result.parsingErrorMessage, isNull);
  });

  testWithoutContext(
      'error: `xcresulttool get` process fail should return an `XCResult` with stderr as `parsingErrorMessage`.',
      () async {
    const String fakeStderr = 'Fake: fail to parse result json.';
    final XCResultGenerator generator = _setupGenerator(
      resultJson: '',
      exitCode: 1,
      stderr: fakeStderr,
    );

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage, fakeStderr);
  });

  testWithoutContext('error: `xcresulttool get` no stdout', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: '');

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Unrecognized top level json format.');
  });

  testWithoutContext('error: wrong top level json format.', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: '[]');

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Unrecognized top level json format.');
  });

  testWithoutContext('error: fail to parse actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: '{}');

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the actions map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator =
        _setupGenerator(resultJson: kSampleResultJsonEmptyActionsMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the actions map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: kSampleResultJsonEmptyActionsMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the actions map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: kSampleResultJsonInvalidActionMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the first action map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: kSampleResultJsonInvalidBuildResultMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the buildResult map.');
  });

  testWithoutContext('error: empty actions map', () async {
    final XCResultGenerator generator = _setupGenerator(resultJson: kSampleResultJsonInvalidIssuesMap);

    final XCResult result = await generator.generate();
    expect(result.issues.length, 0);
    expect(result.parseSuccess, false);
    expect(result.parsingErrorMessage,
        'xcresult parser: Failed to parse the issues map.');
  });
}

const String _tempResultPath = 'temp';

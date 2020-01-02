// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/analyze.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Generator _kNoColorTerminalPlatform = () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false;
final Map<Type, Generator> noColorTerminalOverride = <Type, Generator>{
  Platform: _kNoColorTerminalPlatform,
};

void main() {
  final String analyzerSeparator = platform.isWindows ? '-' : '•';

  group('analyze once', () {
    Directory tempDir;
    String projectPath;
    File libMain;
    const Pub pub = Pub();

    setUpAll(() async {
      Cache.disableLocking();
      tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_1.').absolute;
      projectPath = fs.path.join(tempDir.path, 'flutter_project');
      fs.file(fs.path.join(projectPath, 'pubspec.yaml'))
          ..createSync(recursive: true)
          ..writeAsStringSync(pubspecYamlSrc);

      Cache.flutterRoot = FlutterCommandRunner.defaultFlutterRoot;
      await context.run(
        body: () => pub.get(context: PubContext.pubGet, directory: projectPath),
        overrides: <Type, Generator> {
          Logger: () => BufferLogger(),
          ProcessUtils: () => ProcessUtils(),
          Usage: () => DisabledUsage(),
        },
      );
      return null;
    });

    setUp(() {
      libMain = fs.file(fs.path.join(projectPath, 'lib', 'main.dart'))
          ..createSync(recursive: true)
          ..writeAsStringSync(mainDartSrc);
    });

    tearDownAll(() {
      tryToDelete(tempDir);
    });

    // Analyze in the current directory - no arguments
    testUsingContext('working directory', () async {
      await runCommand(
        command: AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>['No issues found!'],
      );
    }, overrides: <Type, Generator>{
      Pub: () => pub,
    });

    // Analyze a specific file outside the current directory
    testUsingContext('passing one file throws', () async {
      await runCommand(
        command: AnalyzeCommand(),
        arguments: <String>['analyze', libMain.path],
        toolExit: true,
        exitMessageContains: 'is not a directory',
      );
    }, overrides: <Type, Generator>{
      Pub: () => pub,
    });

    // Analyze in the current directory - no arguments
    testUsingContext('working directory with errors', () async {
      // Break the code to produce the "The parameter 'onPressed' is required" hint
      // that is upgraded to a warning in package:flutter/analysis_options_user.yaml
      // to assert that we are using the default Flutter analysis options.
      // Also insert a statement that should not trigger a lint here
      // but will trigger a lint later on when an analysis_options.yaml is added.
      String source = await libMain.readAsString();
      source = source.replaceFirst(
        'onPressed: _incrementCounter,',
        '// onPressed: _incrementCounter,',
      );
      source = source.replaceFirst(
        '_counter++;',
        '_counter++; throw "an error message";',
      );
      await libMain.writeAsString(source);

      // Analyze in the current directory - no arguments
      await runCommand(
        command: AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'info $analyzerSeparator The declaration \'_incrementCounter\' isn\'t',
        ],
        exitMessageContains: '2 issues found.',
        toolExit: true,
      );
    }, overrides: <Type, Generator>{
      Pub: () => pub,
      ...noColorTerminalOverride,
    });

    // Analyze in the current directory - no arguments
    testUsingContext('working directory with local options', () async {
      // Insert an analysis_options.yaml file in the project
      // which will trigger a lint for broken code that was inserted earlier
      final File optionsFile = fs.file(fs.path.join(projectPath, 'analysis_options.yaml'));
      optionsFile.writeAsStringSync('''
  include: package:flutter/analysis_options_user.yaml
  linter:
    rules:
      - only_throw_errors
  ''');
      String source = libMain.readAsStringSync();
      source = source.replaceFirst(
        'onPressed: _incrementCounter,',
        '// onPressed: _incrementCounter,',
      );
      source = source.replaceFirst(
        '_counter++;',
        '_counter++; throw "an error message";',
      );
      libMain.writeAsStringSync(source);

      // Analyze in the current directory - no arguments
      await runCommand(
        command: AnalyzeCommand(workingDirectory: fs.directory(projectPath)),
        arguments: <String>['analyze'],
        statusTextContains: <String>[
          'Analyzing',
          'warning $analyzerSeparator The parameter \'onPressed\' is required',
          'info $analyzerSeparator The declaration \'_incrementCounter\' isn\'t',
          'info $analyzerSeparator Only throw instances of classes extending either Exception or Error',
        ],
        exitMessageContains: '3 issues found.',
        toolExit: true,
      );
      optionsFile.deleteSync();
    }, overrides: <Type, Generator>{
      Pub: () => pub,
      ...noColorTerminalOverride
    });

    testUsingContext('no duplicate issues', () async {
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_2.').absolute;

      try {
        final File foo = fs.file(fs.path.join(tempDir.path, 'foo.dart'));
        foo.writeAsStringSync('''
import 'bar.dart';

void foo() => bar();
''');

        final File bar = fs.file(fs.path.join(tempDir.path, 'bar.dart'));
        bar.writeAsStringSync('''
import 'dart:async'; // unused

void bar() {
}
''');

        // Analyze in the current directory - no arguments
        await runCommand(
          command: AnalyzeCommand(workingDirectory: tempDir),
          arguments: <String>['analyze'],
          statusTextContains: <String>[
            'Analyzing',
          ],
          exitMessageContains: '1 issue found.',
          toolExit: true,
        );
      } finally {
        tryToDelete(tempDir);
      }
    }, overrides: <Type, Generator>{
      Pub: () => pub,
      ...noColorTerminalOverride
    });

    testUsingContext('returns no issues when source is error-free', () async {
      const String contents = '''
StringBuffer bar = StringBuffer('baz');
''';
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_3.');
      tempDir.childFile('main.dart').writeAsStringSync(contents);
      try {
        await runCommand(
          command: AnalyzeCommand(workingDirectory: fs.directory(tempDir)),
          arguments: <String>['analyze'],
          statusTextContains: <String>['No issues found!'],
        );
      } finally {
        tryToDelete(tempDir);
      }
    }, overrides: <Type, Generator>{
      Pub: () => pub,
      ...noColorTerminalOverride
    });

    testUsingContext('returns no issues for todo comments', () async {
      const String contents = '''
// TODO(foobar):
StringBuffer bar = StringBuffer('baz');
''';
      final Directory tempDir = fs.systemTempDirectory.createTempSync('flutter_analyze_once_test_4.');
      tempDir.childFile('main.dart').writeAsStringSync(contents);
      try {
        await runCommand(
          command: AnalyzeCommand(workingDirectory: fs.directory(tempDir)),
          arguments: <String>['analyze'],
          statusTextContains: <String>['No issues found!'],
        );
      } finally {
        tryToDelete(tempDir);
      }
    }, overrides: <Type, Generator>{
      Pub: () => pub,
      ...noColorTerminalOverride
    });
  });
}

void assertContains(String text, List<String> patterns) {
  if (patterns == null) {
    expect(text, isEmpty);
  } else {
    for (String pattern in patterns) {
      expect(text, contains(pattern));
    }
  }
}

Future<void> runCommand({
  FlutterCommand command,
  List<String> arguments,
  List<String> statusTextContains,
  List<String> errorTextContains,
  bool toolExit = false,
  String exitMessageContains,
}) async {
  try {
    arguments.insert(0, '--flutter-root=${Cache.flutterRoot}');
    await createTestCommandRunner(command).run(arguments);
    expect(toolExit, isFalse, reason: 'Expected ToolExit exception');
  } on ToolExit catch (e) {
    if (!toolExit) {
      testLogger.clear();
      rethrow;
    }
    if (exitMessageContains != null) {
      expect(e.message, contains(exitMessageContains));
    }
  }
  assertContains(testLogger.statusText, statusTextContains);
  assertContains(testLogger.errorText, errorTextContains);

  testLogger.clear();
}

const String mainDartSrc = r'''
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
''';

const String pubspecYamlSrc = r'''name: flutter_project
description: A new Flutter project.
version: 1.0.0+1

environment:
  sdk: ">=2.1.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter''';

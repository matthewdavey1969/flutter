// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/icon_tree_shaker.dart';
import 'package:flutter_tools/src/devfs.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/fakes.dart';

final Platform kNoAnsiPlatform = FakePlatform();
const List<int> _kTtfHeaderBytes = <int>[
  0,
  1,
  0,
  0,
  0,
  15,
  0,
  128,
  0,
  3,
  0,
  112
];

const String inputPath = '/input/fonts/MaterialIcons-Regular.otf';
const String outputPath = '/output/fonts/MaterialIcons-Regular.otf';
const String relativePath = 'fonts/MaterialIcons-Regular.otf';

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late Artifacts artifacts;
  late DevFSStringContent fontManifestContent;

  late String dartPath;
  late String constFinderPath;
  late String fontSubsetPath;
  late List<String> fontSubsetArgs;

  List<String> _getConstFinderArgs(String appDillPath) => <String>[
        dartPath,
        '--disable-dart-dev',
        constFinderPath,
        '--kernel-file',
        appDillPath,
        '--class-library-uri',
        'package:flutter/src/widgets/icon_data.dart',
        '--class-name',
        'IconData',
      ];

  void _addConstFinderInvocation(
    String appDillPath, {
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
  }) {
    processManager.addCommand(FakeCommand(
      command: _getConstFinderArgs(appDillPath),
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
    ));
  }

  void _resetFontSubsetInvocation({
    int exitCode = 0,
    String stdout = '',
    String stderr = '',
    required CompleterIOSink stdinSink,
  }) {
    assert(stdinSink != null);
    stdinSink.clear();
    processManager.addCommand(FakeCommand(
      command: fontSubsetArgs,
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
      stdin: stdinSink,
    ));
  }

  setUp(() {
    processManager = FakeProcessManager.empty();
    fontManifestContent = DevFSStringContent(validFontManifestJson);
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    dartPath = artifacts.getHostArtifact(HostArtifact.engineDartBinary).path;
    constFinderPath = artifacts.getArtifactPath(Artifact.constFinder);
    fontSubsetPath = artifacts.getArtifactPath(Artifact.fontSubset);

    fontSubsetArgs = <String>[
      fontSubsetPath,
      outputPath,
      inputPath,
    ];

    fileSystem.file(constFinderPath).createSync(recursive: true);
    fileSystem.file(dartPath).createSync(recursive: true);
    fileSystem.file(fontSubsetPath).createSync(recursive: true);
    fileSystem.file(inputPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(_kTtfHeaderBytes);
  });

  Environment _createEnvironment(Map<String, String> defines) {
    return Environment.test(
      fileSystem.directory('/icon_test')..createSync(recursive: true),
      defines: defines,
      artifacts: artifacts,
      processManager: FakeProcessManager.any(),
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
    );
  }

  testWithoutContext('Prints error in debug mode environment', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'debug',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      logger.errorText,
      'Font subsetting is not supported in debug mode. The --tree-shake-icons'
      ' flag will be ignored.\n',
    );
    expect(iconTreeShaker.enabled, false);

    final bool subsets = await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsets, false);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Does not get enabled without font manifest', () {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      null,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      logger.errorText,
      isEmpty,
    );
    expect(iconTreeShaker.enabled, false);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Gets enabled', () {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      logger.errorText,
      isEmpty,
    );
    expect(iconTreeShaker.enabled, true);
    expect(processManager, hasNoRemainingExpectations);
  });

  test('No app.dill throws exception', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      () async => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Can subset a font', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    bool subsetted = await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(stdinSink.getAndClear(), '59470\n');
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    expect(subsetted, true);
    subsetted = await iconTreeShaker.subsetFont(
      input: fileSystem.file(inputPath),
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsetted, true);
    expect(stdinSink.getAndClear(), '59470\n');
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Does not subset a non-supported font', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    final File notAFont = fileSystem.file('input/foo/bar.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('I could not think of a better string');
    final bool subsetted = await iconTreeShaker.subsetFont(
      input: notAFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );
    expect(subsetted, false);
  });

  testWithoutContext('Does not subset an invalid ttf font', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(stdinSink: stdinSink);

    final File notAFont = fileSystem.file(inputPath)
      ..writeAsBytesSync(<int>[0, 1, 2]);
    final bool subsetted = await iconTreeShaker.subsetFont(
      input: notAFont,
      outputPath: outputPath,
      relativePath: relativePath,
    );

    expect(subsetted, false);
  });

  testWithoutContext('Non-constant instances', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    _addConstFinderInvocation(appDill.path,
        stdout: constFinderResultWithInvalid);

    await expectLater(
      () => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsToolExit(
        message: 'Avoid non-constant invocations of IconData or try to build'
            ' again with --no-tree-shake-icons.',
      ),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Non-zero font-subset exit code', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);
    fileSystem.file(inputPath).createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink();
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    await expectLater(
      () => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('font-subset throws on write to sdtin', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    final CompleterIOSink stdinSink = CompleterIOSink(throwOnAdd: true);
    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);
    _resetFontSubsetInvocation(exitCode: -1, stdinSink: stdinSink);

    await expectLater(
      () => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('Invalid font manifest', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    fontManifestContent = DevFSStringContent(invalidFontManifestJson);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    _addConstFinderInvocation(appDill.path, stdout: validConstFinderResult);

    await expectLater(
      () => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('ConstFinder non-zero exit', () async {
    final Environment environment = _createEnvironment(<String, String>{
      kIconTreeShakerFlag: 'true',
      kBuildMode: 'release',
    });
    final File appDill = environment.buildDir.childFile('app.dill')
      ..createSync(recursive: true);

    fontManifestContent = DevFSStringContent(invalidFontManifestJson);

    final IconTreeShaker iconTreeShaker = IconTreeShaker(
      environment,
      fontManifestContent,
      logger: logger,
      processManager: processManager,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    _addConstFinderInvocation(appDill.path, exitCode: -1);

    await expectLater(
      () async => iconTreeShaker.subsetFont(
        input: fileSystem.file(inputPath),
        outputPath: outputPath,
        relativePath: relativePath,
      ),
      throwsA(isA<IconTreeShakerException>()),
    );
    expect(processManager, hasNoRemainingExpectations);
  });
}

const String validConstFinderResult = '''
{
  "constantInstances": [
    {
      "codePoint": 59470,
      "fontFamily": "MaterialIcons",
      "fontPackage": null,
      "matchTextDirection": false
    }
  ],
  "nonConstantLocations": []
}
''';

const String constFinderResultWithInvalid = '''
{
  "constantInstances": [
    {
      "codePoint": 59470,
      "fontFamily": "MaterialIcons",
      "fontPackage": null,
      "matchTextDirection": false
    }
  ],
  "nonConstantLocations": [
    {
      "file": "file:///Path/to/hello_world/lib/file.dart",
      "line": 19,
      "column": 11
    }
  ]
}
''';

const String validFontManifestJson = '''
[
  {
    "family": "MaterialIcons",
    "fonts": [
      {
        "asset": "fonts/MaterialIcons-Regular.otf"
      }
    ]
  },
  {
    "family": "GalleryIcons",
    "fonts": [
      {
        "asset": "packages/flutter_gallery_assets/fonts/private/gallery_icons/GalleryIcons.ttf"
      }
    ]
  },
  {
    "family": "packages/cupertino_icons/CupertinoIcons",
    "fonts": [
      {
        "asset": "packages/cupertino_icons/assets/CupertinoIcons.ttf"
      }
    ]
  }
]
''';

const String invalidFontManifestJson = '''
{
  "famly": "MaterialIcons",
  "fonts": [
    {
      "asset": "fonts/MaterialIcons-Regular.otf"
    }
  ]
}
''';

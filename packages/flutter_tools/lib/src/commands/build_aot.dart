// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../base/process.dart';
import '../build_info.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import 'run.dart';

const String _kDefaultAotOutputDir = 'build/aot';

// Files generated by the ahead-of-time snapshot builder.
const List<String> kAotSnapshotFiles = const <String>[
  'snapshot_aot_instr', 'snapshot_aot_isolate', 'snapshot_aot_rodata', 'snapshot_aot_vmisolate',
];

class BuildAotCommand extends FlutterCommand {
  BuildAotCommand() {
    usesTargetOption();
    addBuildModeFlags();
    usesPubOption();
    argParser.addOption('output-dir', defaultsTo: _kDefaultAotOutputDir);
  }

  @override
  final String name = 'aot';

  @override
  final String description = "Build an ahead-of-time compiled snapshot of your app's Dart code.";

  @override
  Future<int> runInProject() async {
    String outputPath = buildAotSnapshot(
      findMainDartFile(argResults['target']),
      getBuildMode(),
      outputPath: argResults['output-dir']
    );
    if (outputPath == null)
      return 1;

    printStatus('Built $outputPath.');
    return 0;
  }
}

String _getSdkExtensionPath(String packagesPath, String package) {
  Directory packageDir = new Directory(path.join(packagesPath, package));
  return path.join(path.dirname(packageDir.resolveSymbolicLinksSync()), 'sdk_ext');
}

String buildAotSnapshot(
  String mainPath,
  BuildMode buildMode, {
  String outputPath: _kDefaultAotOutputDir
}) {
  if (!isAotBuildMode(buildMode)) {
    printError('${getModeName(buildMode)} mode does not support AOT compilation.');
    return null;
  }

  String entryPointsDir, genSnapshot;

  String engineSrc = tools.engineSrcPath;
  if (engineSrc != null) {
    entryPointsDir  = path.join(engineSrc, 'sky', 'engine', 'bindings');
    String engineOut = tools.getEngineArtifactsDirectory(
        TargetPlatform.android_arm, buildMode).path;

    String host32BitToolchain = getCurrentHostPlatform() == HostPlatform.darwin_x64 ? 'clang_i386' : 'clang_x86';
    genSnapshot = path.join(engineOut, host32BitToolchain, 'gen_snapshot');
  } else {
    String artifactsDir = tools.getEngineArtifactsDirectory(
        TargetPlatform.android_arm, buildMode).path;
    entryPointsDir = artifactsDir;
    String hostToolsDir = path.join(artifactsDir, getNameForHostPlatform(getCurrentHostPlatform()));
    genSnapshot = path.join(hostToolsDir, 'gen_snapshot');
  }

  Directory outputDir = new Directory(outputPath);
  outputDir.createSync(recursive: true);
  String vmIsolateSnapshot = path.join(outputDir.path, 'snapshot_aot_vmisolate');
  String isolateSnapshot = path.join(outputDir.path, 'snapshot_aot_isolate');
  String instructionsBlob = path.join(outputDir.path, 'snapshot_aot_instr');
  String rodataBlob = path.join(outputDir.path, 'snapshot_aot_rodata');

  String vmEntryPoints = path.join(entryPointsDir, 'dart_vm_entry_points.txt');
  String vmEntryPointsAndroid = path.join(entryPointsDir, 'dart_vm_entry_points_android.txt');

  String packagesPath = path.absolute(Directory.current.path, 'packages');
  if (!FileSystemEntity.isDirectorySync(packagesPath)) {
    printError('Could not find packages directory: $packagesPath\n' +
               'Did you run `pub get` in this directory?');
    printError('This is needed to work around ' +
               'https://github.com/dart-lang/sdk/issues/26362');
    return null;
  }

  String mojoSdkExt = _getSdkExtensionPath(packagesPath, 'mojo');
  String mojoInternalPath = path.join(mojoSdkExt, 'internal.dart');

  String skyEngineSdkExt = _getSdkExtensionPath(packagesPath, 'sky_engine');
  String uiPath = path.join(skyEngineSdkExt, 'dart_ui.dart');
  String vmServicePath = path.join(skyEngineSdkExt, 'dart', 'runtime', 'bin', 'vmservice', 'vmservice_io.dart');
  String jniPath = path.join(skyEngineSdkExt, 'dart_jni', 'jni.dart');

  List<String> filePaths = <String>[
    genSnapshot, vmEntryPoints, vmEntryPointsAndroid, mojoInternalPath, uiPath, vmServicePath, jniPath
  ];
  List<String> missingFiles = filePaths.where((String p) => !FileSystemEntity.isFileSync(p)).toList();
  if (missingFiles.isNotEmpty) {
    printError('Missing files: $missingFiles');
    return null;
  }

  List<String> genSnapshotCmd = <String>[
    genSnapshot,
    '--vm_isolate_snapshot=$vmIsolateSnapshot',
    '--isolate_snapshot=$isolateSnapshot',
    '--instructions_blob=$instructionsBlob',
    '--rodata_blob=$rodataBlob',
    '--embedder_entry_points_manifest=$vmEntryPoints',
    '--embedder_entry_points_manifest=$vmEntryPointsAndroid',
    '--package_root=$packagesPath',
    '--url_mapping=dart:mojo.internal,$mojoInternalPath',
    '--url_mapping=dart:ui,$uiPath',
    '--url_mapping=dart:vmservice_sky,$vmServicePath',
    '--url_mapping=dart:jni,$jniPath',
    '--no-sim-use-hardfp',
  ];

  if (buildMode != BuildMode.release) {
    genSnapshotCmd.addAll(<String>[
      '--no-checked',
      '--conditional_directives',
    ]);
  }

  genSnapshotCmd.add(mainPath);

  printStatus('Building snapshot...');
  runCheckedSync(genSnapshotCmd);

  return outputPath;
}

// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart';
import '../macos/build_macos.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a macos desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand() {
    usesTargetOption();
    argParser.addFlag('debug',
      negatable: false,
      help: 'Build a debug version of your app.',
    );
    argParser.addFlag('profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.'
    );
    argParser.addFlag('release',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.',
    );
  }

  @override
  final String name = 'macos';

  @override
  bool isExperimental = true;

  @override
  bool hidden = true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.macOS,
    DevelopmentArtifact.universal,
  };

  @override
  String get description => 'build the macOS desktop target (Experimental).';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final BuildInfo buildInfo = getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!platform.isMacOS) {
      throwToolExit('"build macos" only supported on macOS hosts.');
    }
    if (!flutterProject.macos.existsSync()) {
      throwToolExit('No macOS desktop project configured.');
    }
    final String executable = await buildMacOS(
      flutterProject: flutterProject,
      buildInfo: buildInfo,
      targetOverride: targetFile,
    );
    printStatus('build macOS application at $executable');
    return null;
  }
}

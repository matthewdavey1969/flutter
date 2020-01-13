// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';

/// This is a simple wrapper around the custom kernel compiler from the Fuchsia
/// SDK.
class FuchsiaKernelCompiler {
  /// Compiles the [fuchsiaProject] with entry point [target] to a collection of
  /// .dilp files (consisting of the app split along package: boundaries, but
  /// the Flutter tool should make no use of that fact), and a manifest that
  /// refers to them.
  Future<void> build({
    @required FuchsiaProject fuchsiaProject,
    @required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug,
  }) async {
    // TODO(zra): Use filesystem root and scheme information from buildInfo.
    const String multiRootScheme = 'main-root';
    final String packagesFile = fuchsiaProject.project.packagesFile.path;
    final String outDir = getFuchsiaBuildDirectory();
    final String appName = fuchsiaProject.project.manifest.appName;
    final String fsRoot = fuchsiaProject.project.directory.path;
    final String relativePackagesFile = globals.fs.path.relative(packagesFile, from: fsRoot);
    final String manifestPath = globals.fs.path.join(outDir, '$appName.dilpmanifest');
    final String kernelCompiler = globals.artifacts.getArtifactPath(
      Artifact.fuchsiaKernelCompiler,
      platform: TargetPlatform.fuchsia_arm64,  // This file is not arch-specific.
      mode: buildInfo.mode,
    );
    if (!globals.fs.isFileSync(kernelCompiler)) {
      throwToolExit('Fuchisa kernel compiler not found at "$kernelCompiler"');
    }
    final String platformDill = globals.artifacts.getArtifactPath(
      Artifact.platformKernelDill,
      platform: TargetPlatform.fuchsia_arm64,  // This file is not arch-specific.
      mode: buildInfo.mode,
    );
    if (!globals.fs.isFileSync(platformDill)) {
      throwToolExit('Fuchisa platform file not found at "$platformDill"');
    }
    List<String> flags = <String>[
      '--target', 'flutter_runner',
      '--platform', platformDill,
      '--filesystem-scheme', 'main-root',
      '--filesystem-root', fsRoot,
      '--packages', '$multiRootScheme:///$relativePackagesFile',
      '--output', globals.fs.path.join(outDir, '$appName.dil'),
      '--component-name', appName,

      // AOT/JIT:
      if (buildInfo.usesAot) ...<String>['--aot', '--tfa']
      else ...<String>[
        '--no-link-platform',
        '--split-output-by-packages',
        '--manifest', manifestPath
      ],

      // debug, profile, jit release, release:
      if (buildInfo.isDebug) '--embed-sources'
      else '--no-embed-sources',

      if (buildInfo.isProfile) '-Ddart.vm.profile=true',
      if (buildInfo.mode.isRelease) '-Ddart.vm.release=true',

      // Use bytecode and drop the ast in JIT release mode.
      if (buildInfo.isJitRelease) ...<String>[
        '--gen-bytecode',
        '--drop-ast',
      ],
    ];

    flags += <String>[
      '$multiRootScheme:///$target',
    ];

    final List<String> command = <String>[
      globals.artifacts.getArtifactPath(Artifact.engineDartBinary),
      kernelCompiler,
      ...flags,
    ];
    final Status status = globals.logger.startProgress(
      'Building Fuchsia application...',
      timeout: null,
    );
    int result;
    try {
      result = await ProcessUtils(logger: globals.logger, processManager: globals.processManager).stream(command, trace: true);
    } finally {
      status.cancel();
    }
    if (result != 0) {
      throwToolExit('Build process failed');
    }
  }
}

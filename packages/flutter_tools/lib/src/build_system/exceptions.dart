// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import 'build_system.dart';

/// An exception thrown when a rule declares an input that does not exist on
/// disk.
class MissingInputException implements Exception {
  const MissingInputException(this.entity, this.target);

  /// The file or directory we expected to find.
  final FileSystemEntity entity;

  /// The name of the target this file should have been output from.
  final String target;

  @override
  String toString() {
    return '${entity.path} was declared as an input, but does not exist on '
        'disk. Check the definition of target:$target for errors';
  }
}

/// An exception thrown if we detect a cycle in the dependencies of a target.
class CycleException implements Exception {
  CycleException(this.targets);

  final Set<Target> targets;

  @override
  String toString() => 'Dependency cycle detected in build: '
      '${targets.map((Target target) => target.name).join(' -> ')}';
}

/// An exception thrown when a pattern is invalid.
class InvalidPatternException implements Exception {
  InvalidPatternException(this.pattern);

  final String pattern;

  @override
  String toString() => 'The pattern "$pattern" is not valid';
}

/// An exception thrown when a rule declares an output that was not produced
/// by the invocation.
class MissingOutputException implements Exception {
  const MissingOutputException(this.file, this.target);

  /// The file we expected to find.
  final File file;

  /// The name of the target this file should have been output from.
  final String target;

  @override
  String toString() {
    return '${file.path} was declared as an output, but was not generated by '
        'the invocation. Check the definition of target:$target for errors';
  }
}

/// An exception thrown when asked to build with rules that do not support the
/// current environment.
class InvalidBuildException implements Exception {
  const InvalidBuildException(this.environment, this.target);

  final Target target;
  final Environment environment;

  @override
  String toString() {
    return 'Target $target cannot build with ${environment.buildMode} and '
      '${environment.targetPlatform}.';
  }

}

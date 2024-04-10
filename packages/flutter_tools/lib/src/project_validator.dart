// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:process/process.dart';

import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'cache.dart';
import 'convert.dart';
import 'dart_pub_json_formatter.dart';
import 'flutter_manifest.dart';
import 'project.dart';
import 'project_validator_result.dart';
import 'version.dart';

abstract class ProjectValidator {
  const ProjectValidator();
  String get title;
  bool get machineOutput => false;
  bool supportsProject(FlutterProject project);
  /// Can return more than one result in case a file/command have a lot of info to share to the user
  Future<List<ProjectValidatorResult>> start(FlutterProject project);
}

abstract class MachineProjectValidator extends ProjectValidator {
  const MachineProjectValidator();

  @override
  bool get machineOutput => true;
}

/// Validator run for all platforms that extract information from the pubspec.yaml.
///
/// Specific info from different platforms should be written in their own ProjectValidator.
class VariableDumpMachineProjectValidator extends MachineProjectValidator {
  VariableDumpMachineProjectValidator({
    required this.logger,
    required this.fileSystem,
    required this.platform,
  });

  final Logger logger;
  final FileSystem fileSystem;
  final Platform platform;

  String _toJsonValue(Object? obj) {
    String value = obj.toString();
    if (obj is String) {
      value = '"$obj"';
    }
    value = value.replaceAll(r'\', r'\\');
    return value;
  }

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final FlutterVersion version = FlutterVersion(
      flutterRoot: Cache.flutterRoot!,
      fs: fileSystem,
    );
    final Map<String, String> result = <String, String>{
      'FlutterProject.directory':        _toJsonValue(project.directory.absolute.path),
      'FlutterProject.metadataFile':     _toJsonValue(project.metadataFile.absolute.path),
      'FlutterProject.android.exists':   _toJsonValue(project.android.existsSync()),
      'FlutterProject.ios.exists':       _toJsonValue(project.ios.exists),
      'FlutterProject.web.exists':       _toJsonValue(project.web.existsSync()),
      'FlutterProject.macos.exists':     _toJsonValue(project.macos.existsSync()),
      'FlutterProject.linux.exists':     _toJsonValue(project.linux.existsSync()),
      'FlutterProject.windows.exists':   _toJsonValue(project.windows.existsSync()),
      'FlutterProject.fuchsia.exists':   _toJsonValue(project.fuchsia.existsSync()),

      'FlutterProject.android.isKotlin': _toJsonValue(project.android.isKotlin),
      'FlutterProject.ios.isSwift':      _toJsonValue(project.ios.isSwift),

      'FlutterProject.isModule':         _toJsonValue(project.isModule),
      'FlutterProject.isPlugin':         _toJsonValue(project.isPlugin),

      'FlutterProject.manifest.appname': _toJsonValue(project.manifest.appName),

      // FlutterVersion
      'FlutterVersion.frameworkRevision': _toJsonValue(version.frameworkRevision),

      // Platform
      'Platform.operatingSystem':        _toJsonValue(platform.operatingSystem),
      'Platform.isAndroid':              _toJsonValue(platform.isAndroid),
      'Platform.isIOS':                  _toJsonValue(platform.isIOS),
      'Platform.isWindows':              _toJsonValue(platform.isWindows),
      'Platform.isMacOS':                _toJsonValue(platform.isMacOS),
      'Platform.isFuchsia':              _toJsonValue(platform.isFuchsia),
      'Platform.pathSeparator':          _toJsonValue(platform.pathSeparator),

      // Cache
      'Cache.flutterRoot':               _toJsonValue(Cache.flutterRoot),
    };

    return <ProjectValidatorResult>[
      for (final MapEntry<String, String>(: String key, : String value) in result.entries)
        ProjectValidatorResult(name: key, value: value, status: StatusProjectValidator.info)
    ];
  }

  @override
  bool supportsProject(FlutterProject project) {
    // this validator will run for any type of project
    return true;
  }

  @override
  String get title => 'Machine JSON variable dump';
}

/// Validator run for all platforms that extract information from the pubspec.yaml.
///
/// Specific info from different platforms should be written in their own ProjectValidator.
class GeneralInfoProjectValidator extends ProjectValidator {
  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    final FlutterManifest flutterManifest = project.manifest;
    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[];
    final ProjectValidatorResult appNameValidatorResult = _getAppNameResult(flutterManifest);
    result.add(appNameValidatorResult);
    final String supportedPlatforms = _getSupportedPlatforms(project);
    if (supportedPlatforms.isEmpty) {
      return result;
    }
    final ProjectValidatorResult supportedPlatformsResult = ProjectValidatorResult(
        name: 'Supported Platforms',
        value: supportedPlatforms,
        status: StatusProjectValidator.success
    );
    final ProjectValidatorResult isFlutterPackage = _isFlutterPackageValidatorResult(flutterManifest);
    result.addAll(<ProjectValidatorResult>[supportedPlatformsResult, isFlutterPackage]);
    if (flutterManifest.flutterDescriptor.isNotEmpty) {
      result.add(_materialDesignResult(flutterManifest));
      result.add(_pluginValidatorResult(flutterManifest));
    }
    result.add(await project.android.validateJavaAndGradleAgpVersions());
    return result;
  }

  ProjectValidatorResult _getAppNameResult(FlutterManifest flutterManifest) {
    final String appName = flutterManifest.appName;
    const String name = 'App Name';
    if (appName.isEmpty) {
      return const ProjectValidatorResult(
          name: name,
          value: 'name not found',
          status: StatusProjectValidator.error
      );
    }
    return ProjectValidatorResult(
        name: name,
        value: appName,
        status: StatusProjectValidator.success
    );
  }

  ProjectValidatorResult _isFlutterPackageValidatorResult(FlutterManifest flutterManifest) {
    final String value;
    final StatusProjectValidator status;
    if (flutterManifest.flutterDescriptor.isNotEmpty) {
      value = 'yes';
      status = StatusProjectValidator.success;
    } else {
      value = 'no';
      status = StatusProjectValidator.warning;
    }

    return ProjectValidatorResult(
        name: 'Is Flutter Package',
        value: value,
        status: status
    );
  }

  ProjectValidatorResult _materialDesignResult(FlutterManifest flutterManifest) {
    return ProjectValidatorResult(
      name: 'Uses Material Design',
      value: flutterManifest.usesMaterialDesign? 'yes' : 'no',
      status: StatusProjectValidator.success
    );
  }

  String _getSupportedPlatforms(FlutterProject project) {
    return project.getSupportedPlatforms().map((SupportedPlatform platform) => platform.name).join(', ');
  }

  ProjectValidatorResult _pluginValidatorResult(FlutterManifest flutterManifest) {
    return ProjectValidatorResult(
      name: 'Is Plugin',
      value: flutterManifest.isPlugin? 'yes' : 'no',
      status: StatusProjectValidator.success
    );
  }

  @override
  bool supportsProject(FlutterProject project) {
    // this validator will run for any type of project
    return true;
  }

  @override
  String get title => 'General Info';
}

class PubDependenciesProjectValidator extends ProjectValidator {
  const PubDependenciesProjectValidator(this._processManager);
  final ProcessManager _processManager;

  @override
  Future<List<ProjectValidatorResult>> start(FlutterProject project) async {
    const String name = 'Dart dependencies';
    final ProcessResult processResult = await _processManager.run(<String>['dart', 'pub', 'deps', '--json']);
    if (processResult.stdout is! String) {
      return <ProjectValidatorResult>[
        _createProjectValidatorError(name, 'Command dart pub deps --json failed')
      ];
    }

    final LinkedHashMap<String, dynamic> jsonResult;
    final List<ProjectValidatorResult> result = <ProjectValidatorResult>[];
    try {
      jsonResult = json.decode(
        processResult.stdout.toString()
      ) as LinkedHashMap<String, dynamic>;
    } on FormatException {
      result.add(_createProjectValidatorError(name, processResult.stderr.toString()));
      return result;
    }

    final DartPubJson dartPubJson = DartPubJson(jsonResult);
    final List <String> dependencies = <String>[];

    // Information retrieved from the pubspec.lock file if a dependency comes from
    // the hosted url https://pub.dartlang.org we ignore it or if the package
    // is the current directory being analyzed (root).
    final Set<String> hostedDependencies = <String>{'hosted', 'root'};

    for (final DartDependencyPackage package in dartPubJson.packages) {
      if (!hostedDependencies.contains(package.source)) {
        dependencies.addAll(package.dependencies);
      }
    }

    final String value;
    if (dependencies.isNotEmpty) {
      final String verb = dependencies.length == 1 ? 'is' : 'are';
      value = '${dependencies.join(', ')} $verb not hosted';
    } else {
      value = 'All pub dependencies are hosted on https://pub.dartlang.org';
    }

    result.add(
       ProjectValidatorResult(
        name: name,
        value: value,
        status: StatusProjectValidator.info,
      )
    );

    return result;
  }

  @override
  bool supportsProject(FlutterProject project) {
    return true;
  }

  @override
  String get title => 'Pub dependencies';

  ProjectValidatorResult _createProjectValidatorError(String name, String value) {
    return ProjectValidatorResult(name: name, value: value, status: StatusProjectValidator.error);
  }
}

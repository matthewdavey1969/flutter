// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter, json, utf8;
import 'dart:io';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

TaskFunction createComplexLayoutScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'complex_layout_scroll_perf',
  ).run;
}

TaskFunction createTilesScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'tiles_scroll_perf',
  ).run;
}

TaskFunction createUiKitViewScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/platform_views_layout',
    'test_driver/uikit_view_scroll_perf.dart',
    'platform_views_scroll_perf',
    testDriver: 'test_driver/scroll_perf_test.dart',
  ).run;
}

TaskFunction createAndroidTextureScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/platform_views_layout',
    'test_driver/android_texture_scroll_perf.dart',
    'platform_views_scroll_perf',
    testDriver: 'test_driver/scroll_perf_test.dart',
  ).run;
}

TaskFunction createAndroidViewScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/platform_views_layout',
    'test_driver/android_view_scroll_perf.dart',
    'platform_views_scroll_perf',
    testDriver: 'test_driver/scroll_perf_test.dart',
  ).run;
}

TaskFunction createHomeScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/integration_tests/flutter_gallery',
    'test_driver/scroll_perf.dart',
    'home_scroll_perf',
  ).run;
}

TaskFunction createCullOpacityPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/cull_opacity_perf.dart',
    'cull_opacity_perf',
  ).run;
}

TaskFunction createCubicBezierPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/cubic_bezier_perf.dart',
    'cubic_bezier_perf',
  ).run;
}

TaskFunction createCubicBezierPerfSkSLWarmupTest() {
  return PerfTestWithSkSL(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/cubic_bezier_perf.dart',
    'cubic_bezier_perf',
  ).run;
}

TaskFunction createBackdropFilterPerfTest({bool needsMeasureCpuGpu = false}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/backdrop_filter_perf.dart',
    'backdrop_filter_perf',
    needsMeasureCpuGpu: needsMeasureCpuGpu,
  ).run;
}

TaskFunction createPostBackdropFilterPerfTest({bool needsMeasureCpuGpu = false}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/post_backdrop_filter_perf.dart',
    'post_backdrop_filter_perf',
    needsMeasureCpuGpu: needsMeasureCpuGpu,
  ).run;
}

TaskFunction createSimpleAnimationPerfTest({bool needsMeasureCpuGpu = false}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/simple_animation_perf.dart',
    'simple_animation_perf',
    needsMeasureCpuGpu: needsMeasureCpuGpu,
  ).run;
}

TaskFunction createAnimatedPlaceholderPerfTest({bool needsMeasureCpuGpu = false}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/animated_placeholder_perf.dart',
    'animated_placeholder_perf',
    needsMeasureCpuGpu: needsMeasureCpuGpu,
  ).run;
}

TaskFunction createPictureCachePerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/picture_cache_perf.dart',
    'picture_cache_perf',
  ).run;
}

TaskFunction createFlutterGalleryStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/dev/integration_tests/flutter_gallery',
  ).run;
}

TaskFunction createComplexLayoutStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
  ).run;
}

TaskFunction createHelloWorldStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/examples/hello_world',
    reportMetrics: false,
  ).run;
}

TaskFunction createFlutterGalleryCompileTest() {
  return CompileTest('${flutterDirectory.path}/dev/integration_tests/flutter_gallery').run;
}

TaskFunction createHelloWorldCompileTest() {
  return CompileTest('${flutterDirectory.path}/examples/hello_world', reportPackageContentSizes: true).run;
}

TaskFunction createWebCompileTest() {
  return const WebCompileTest().run;
}

TaskFunction createComplexLayoutCompileTest() {
  return CompileTest('${flutterDirectory.path}/dev/benchmarks/complex_layout').run;
}

TaskFunction createFlutterViewStartupTest() {
  return StartupTest(
      '${flutterDirectory.path}/examples/flutter_view',
      reportMetrics: false,
  ).run;
}

TaskFunction createPlatformViewStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/examples/platform_view',
    reportMetrics: false,
  ).run;
}

TaskFunction createBasicMaterialCompileTest() {
  return () async {
    const String sampleAppName = 'sample_flutter_app';
    final Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    rmTree(sampleDir);

    await inDirectory<void>(Directory.systemTemp, () async {
      await flutter('create', options: <String>['--template=app', sampleAppName]);
    });

    if (!sampleDir.existsSync())
      throw 'Failed to create default Flutter app in ${sampleDir.path}';

    return CompileTest(sampleDir.path).run();
  };
}

TaskFunction createTextfieldPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/textfield_perf.dart',
    'textfield_perf',
  ).run;
}

TaskFunction createColorFilterAndFadePerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/color_filter_and_fade_perf.dart',
    'color_filter_and_fade_perf',
  ).run;
}

TaskFunction createFadingChildAnimationPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/fading_child_animation_perf.dart',
    'fading_child_animation_perf',
  ).run;
}

TaskFunction createImageFilteredTransformAnimationPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/imagefiltered_transform_animation_perf.dart',
    'imagefiltered_transform_animation_perf',
  ).run;
}

/// Measure application startup performance.
class StartupTest {
  const StartupTest(this.testDirectory, { this.reportMetrics = true });

  final String testDirectory;
  final bool reportMetrics;

  Future<TaskResult> run() async {
    return await inDirectory<TaskResult>(testDirectory, () async {
      final String deviceId = (await devices.workingDevice).deviceId;
      await flutter('packages', options: <String>['get']);

      await flutter('run', options: <String>[
        '--verbose',
        '--profile',
        '--trace-startup',
        '-d',
        deviceId,
      ]);
      final Map<String, dynamic> data = json.decode(
        file('$testDirectory/build/start_up_info.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      if (!reportMetrics)
        return TaskResult.success(data);

      return TaskResult.success(data, benchmarkScoreKeys: <String>[
        'timeToFirstFrameMicros',
        'timeToFirstFrameRasterizedMicros',
      ]);
    });
  }
}

/// Measures application runtime performance, specifically per-frame
/// performance.
class PerfTest {
  const PerfTest(
    this.testDirectory,
    this.testTarget,
    this.timelineFileName, {
    this.needsMeasureCpuGpu = false,
    this.testDriver,
  });

  /// The directory where the app under test is defined.
  final String testDirectory;
  /// The main entry-point file of the application, as run on the device.
  final String testTarget;
  // The prefix name of the filename such as `<timelineFileName>.timeline_summary.json`.
  final String timelineFileName;
  /// The test file to run on the host.
  final String testDriver;
  /// Whether to collect CPU and GPU metrics.
  final bool needsMeasureCpuGpu;

  Future<TaskResult> run() {
    return internalRun();
  }

  @protected
  Future<TaskResult> internalRun({bool keepRunning = false, bool cacheSkSL = false, String existingApp}) {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      await flutter('drive', options: <String>[
        '-v',
        '--profile',
        '--trace-startup', // Enables "endless" timeline event buffering.
        '-t',
        testTarget,
        if (testDriver != null)
          ...<String>['--driver', testDriver],
        if (existingApp != null)
          ...<String>['--use-existing-app', existingApp],
        if (cacheSkSL) '--cache-sksl',
        if (keepRunning) '--keep-app-running',
        '-d',
        deviceId,
      ]);
      final Map<String, dynamic> data = json.decode(
        file('$testDirectory/build/$timelineFileName.timeline_summary.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      if (data['frame_count'] as int < 5) {
        return TaskResult.failure(
          'Timeline contains too few frames: ${data['frame_count']}. Possibly '
          'trace events are not being captured.',
        );
      }

      if (needsMeasureCpuGpu) {
        await inDirectory<void>('$testDirectory/build', () async {
          data.addAll(await measureIosCpuGpu(deviceId: deviceId));
        });
      }

      return TaskResult.success(data, benchmarkScoreKeys: <String>[
        'average_frame_build_time_millis',
        'worst_frame_build_time_millis',
        '90th_percentile_frame_build_time_millis',
        '99th_percentile_frame_build_time_millis',
        'average_frame_rasterizer_time_millis',
        'worst_frame_rasterizer_time_millis',
        '90th_percentile_frame_rasterizer_time_millis',
        '99th_percentile_frame_rasterizer_time_millis',
        'average_vsync_transitions_missed',
        '90th_percentile_vsync_transitions_missed',
        '99th_percentile_vsync_transitions_missed',
        if (needsMeasureCpuGpu) 'cpu_percentage',
        if (needsMeasureCpuGpu) 'gpu_percentage',
      ]);
    });
  }
}

class PerfTestWithSkSL extends PerfTest {
  PerfTestWithSkSL(
    String testDirectory,
    String testTarget,
    String timelineFileName, {
    bool needsMeasureCpuGpu = false,
    String testDriver,
  }) : super(
    testDirectory,
    testTarget,
    timelineFileName,
    needsMeasureCpuGpu: needsMeasureCpuGpu,
    testDriver: testDriver,
  );

  @override
  Future<TaskResult> run() async {
    return inDirectory<TaskResult>(testDirectory, () async {
      // Some initializations
      _device = await devices.workingDevice;
      _flutterPath = path.join(flutterDirectory.path, 'bin', 'flutter');

      // Prepare the SkSL by running the driver test.
      await _generateSkSL();

      // Build the app with SkSL artifacts and run that app
      final String observatoryUri = await _buildAndRun();

      // Attach to the running app and run the final driver test to get metrics.
      final TaskResult result = await internalRun(
        existingApp: observatoryUri,
      );

      _runProcess.kill();
      await _runProcess.exitCode;

      return result;
    });
  }

  Future<void> _generateSkSL() async {
    // First, clear all old sksl.json file so they won't affect the test.
    for (final FileSystemEntity file in Directory(testDirectory).listSync()) {
      if (file.path.endsWith('.sksl.json')) {
        file.deleteSync();
      }
    }

    await super.internalRun(keepRunning: true, cacheSkSL: true);
    final Process process = await startProcess(
      _flutterPath,
      <String>[
        'attach',
        '-d', _device.deviceId,
      ],
    );
    final Stream<List<int>> broadcastOut = process.stdout.asBroadcastStream();
    _forwardStream(broadcastOut, 'attach stdout');
    _forwardStream(process.stderr, 'attach stderr');

    final Completer<bool> attachReady = Completer<bool>();
    final Completer<bool> skslWritten = Completer<bool>();

    _transform(broadcastOut).listen((String line) {
      if (!attachReady.isCompleted && _kObservatoryReadyRegExp.hasMatch(line)) {
        attachReady.complete(true);
      }
      if (!skslWritten.isCompleted && RegExp('Wrote SkSL data to').hasMatch(line)) {
        skslWritten.complete(true);
      }
    });

    await attachReady.future;
    process.stdin.write('M');
    await skslWritten.future;
    process.stdin.write('q');
    await process.exitCode;
  }

  // Return the Observatory URI.
  Future<String> _buildAndRun() async {
    await flutter('build', options: <String>[
      // TODO(liyuqian): also supports iOS once https://github.com/flutter/flutter/issues/53115 is fully closed.
      'apk',
      '--profile',
      '--bundle-sksl-path', '$testDirectory/flutter_01.sksl.json',
      '-t', testTarget,
    ]);

    _deleteOldVmserviceFile();

    _runProcess = await startProcess(
      _flutterPath,
      <String>[
        'run',
        '--verbose',
        '--profile',
        '-d', _device.deviceId,
        '-t', testTarget,
        '--use-application-binary', '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk',
        '--vmservice-out-file', _vmserviceFileName,
      ],
    );

    final Stream<List<int>> broadcastOut = _runProcess.stdout.asBroadcastStream();
    _forwardStream(broadcastOut, 'run stdout');
    _forwardStream(_runProcess.stderr, 'run stderr');

    return await _getObservatoryUriFromVmserviceFile();
  }

  String get _vmserviceFileName => '$testDirectory/$_kVmserviceOutFileName';

  void _deleteOldVmserviceFile() {
    if (File(_vmserviceFileName).existsSync()) {
      File(_vmserviceFileName).deleteSync();
    }
  }

  Future<String> _getObservatoryUriFromVmserviceFile() async {
    const int maxWaitSeconds = 120;
    const int waitIntervalSeconds = 5;
    for (int waitSeconds = 0; waitSeconds < maxWaitSeconds; waitSeconds += waitIntervalSeconds) {
      print('Waiting $waitIntervalSeconds seconds for $_vmserviceFileName to be written...');
      await Future<void>.delayed(const Duration(seconds: waitIntervalSeconds));
      if (File(_vmserviceFileName).existsSync()) {
        return File(_vmserviceFileName).readAsStringSync();
      }
    }
    throw 'Failed to get the Observatory URI after $maxWaitSeconds seconds';
  }

  Stream<String> _transform(Stream<List<int>> stream) =>
      stream.transform<String>(utf8.decoder).transform<String>(const LineSplitter());

  void _forwardStream(Stream<List<int>> stream, String label) {
    _transform(stream).listen((String line) {
      print('$label: $line');
    });
  }

  String _flutterPath;
  Device _device;
  Process _runProcess;

  static const String _kVmserviceOutFileName = 'vmservice.out';
  static final RegExp _kObservatoryReadyRegExp = RegExp(r'An Observatory debugger and profiler on .+ is available at: ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)');
}

/// Measures how long it takes to compile a Flutter app to JavaScript and how
/// big the compiled code is.
class WebCompileTest {
  const WebCompileTest();

  Future<TaskResult> run() async {
    final Map<String, Object> metrics = <String, Object>{};

    metrics.addAll(await runSingleBuildTest(
      directory: '${flutterDirectory.path}/examples/hello_world',
      metric: 'hello_world',
    ));

    metrics.addAll(await runSingleBuildTest(
      directory: '${flutterDirectory.path}/dev/integration_tests/flutter_gallery',
      metric: 'flutter_gallery',
    ));

    const String sampleAppName = 'sample_flutter_app';
    final Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    rmTree(sampleDir);

    await inDirectory<void>(Directory.systemTemp, () async {
      await flutter('create', options: <String>['--template=app', sampleAppName]);
    });

    metrics.addAll(await runSingleBuildTest(
      directory: sampleDir.path,
      metric: 'basic_material_app',
    ));

    return TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
  }

  /// Run a single web compile test and return its metrics.
  ///
  /// Run a single web compile test for the app under [directory], and store
  /// its metrics with prefix [metric].
  static Future<Map<String, int>> runSingleBuildTest({String directory, String metric, bool measureBuildTime = false}) {
    return inDirectory<Map<String, int>>(directory, () async {
      final Map<String, int> metrics = <String, int>{};

      await flutter('packages', options: <String>['get']);
      final Stopwatch watch = measureBuildTime ? Stopwatch() : null;
      watch?.start();
      await evalFlutter('build', options: <String>[
        'web',
        '-v',
        '--release',
        '--no-pub',
      ]);
      watch?.stop();
      final String outputFileName = path.join(directory, 'build/web/main.dart.js');
      metrics.addAll(await getSize(outputFileName, metric: metric));

      if (measureBuildTime) {
        metrics['${metric}_dart2js_millis'] = watch.elapsedMilliseconds;
      }

      return metrics;
    });
  }

  /// Obtains the size and gzipped size of a file given by [fileName].
  static Future<Map<String, int>> getSize(String fileName, {String metric}) async {
    final Map<String, int> sizeMetrics = <String, int>{};

    final ProcessResult result = await Process.run('du', <String>['-k', fileName]);
    sizeMetrics['${metric}_dart2js_size'] = _parseDu(result.stdout as String);

    await Process.run('gzip',<String>['-k', '9', fileName]);
    final ProcessResult resultGzip = await Process.run('du', <String>['-k', fileName + '.gz']);
    sizeMetrics['${metric}_dart2js_size_gzip'] = _parseDu(resultGzip.stdout as String);

    return sizeMetrics;
  }

  static int _parseDu(String source) {
    return int.parse(source.split(RegExp(r'\s+')).first.trim());
  }
}

/// Measures how long it takes to compile a Flutter app and how big the compiled
/// code is.
class CompileTest {
  const CompileTest(this.testDirectory, { this.reportPackageContentSizes = false });

  final String testDirectory;
  final bool reportPackageContentSizes;

  Future<TaskResult> run() async {
    return await inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);

      final Map<String, dynamic> metrics = <String, dynamic>{
        ...await _compileApp(reportPackageContentSizes: reportPackageContentSizes),
        ...await _compileDebug(),
      };

      return TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
    });
  }

  static Future<Map<String, dynamic>> _compileApp({ bool reportPackageContentSizes = false }) async {
    await flutter('clean');
    final Stopwatch watch = Stopwatch();
    int releaseSizeInBytes;
    final List<String> options = <String>['--release'];
    final Map<String, dynamic> metrics = <String, dynamic>{};

    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        options.insert(0, 'ios');
        options.add('--tree-shake-icons');
        options.add('--split-debug-info=infos/');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        final Directory appBuildDirectory = dir(path.join(cwd, 'build/ios/Release-iphoneos'));
        final Directory appBundle = appBuildDirectory
            .listSync()
            .whereType<Directory>()
            .singleWhere((Directory directory) => path.extension(directory.path) == '.app', orElse: () => null);
        if (appBundle == null) {
          throw 'Failed to find app bundle in ${appBuildDirectory.path}';
        }
        final String appPath =  appBundle.path;
        // IPAs are created manually, https://flutter.dev/ios-release/
        await exec('tar', <String>['-zcf', 'build/app.ipa', appPath]);
        releaseSizeInBytes = await file('$cwd/build/app.ipa').length();
        if (reportPackageContentSizes)
          metrics.addAll(await getSizesFromIosApp(appPath));
        break;
      case DeviceOperatingSystem.android:
        options.insert(0, 'apk');
        options.add('--target-platform=android-arm');
        options.add('--tree-shake-icons');
        options.add('--split-debug-info=infos/');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        final String apkPath = '$cwd/build/app/outputs/flutter-apk/app-release.apk';
        final File apk = file(apkPath);
        releaseSizeInBytes = apk.lengthSync();
        if (reportPackageContentSizes)
          metrics.addAll(await getSizesFromApk(apkPath));
        break;
      case DeviceOperatingSystem.fuchsia:
        throw Exception('Unsupported option for Fuchsia devices');
    }

    metrics.addAll(<String, dynamic>{
      'release_full_compile_millis': watch.elapsedMilliseconds,
      'release_size_bytes': releaseSizeInBytes,
    });

    return metrics;
  }

  static Future<Map<String, dynamic>> _compileDebug() async {
    await flutter('clean');
    final Stopwatch watch = Stopwatch();
    final List<String> options = <String>['--debug'];
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        options.insert(0, 'ios');
        break;
      case DeviceOperatingSystem.android:
        options.insert(0, 'apk');
        options.add('--target-platform=android-arm');
        break;
      case DeviceOperatingSystem.fuchsia:
        throw Exception('Unsupported option for Fuchsia devices');
    }
    watch.start();
    await flutter('build', options: options);
    watch.stop();

    return <String, dynamic>{
      'debug_full_compile_millis': watch.elapsedMilliseconds,
    };
  }

  static Future<Map<String, dynamic>> getSizesFromIosApp(String appPath) async {
    // Thin the binary to only contain one architecture.
    final String xcodeBackend = path.join(flutterDirectory.path, 'packages', 'flutter_tools', 'bin', 'xcode_backend.sh');
    await exec(xcodeBackend, <String>['thin'], environment: <String, String>{
      'ARCHS': 'arm64',
      'WRAPPER_NAME': path.basename(appPath),
      'TARGET_BUILD_DIR': path.dirname(appPath),
    });

    final File appFramework = File(path.join(appPath, 'Frameworks', 'App.framework', 'App'));
    final File flutterFramework = File(path.join(appPath, 'Frameworks', 'Flutter.framework', 'Flutter'));

    return <String, dynamic>{
      'app_framework_uncompressed_bytes': await appFramework.length(),
      'flutter_framework_uncompressed_bytes': await flutterFramework.length(),
    };
  }

  static Future<Map<String, dynamic>> getSizesFromApk(String apkPath) async {
    final  String output = await eval('unzip', <String>['-v', apkPath]);
    final List<String> lines = output.split('\n');
    final Map<String, _UnzipListEntry> fileToMetadata = <String, _UnzipListEntry>{};

    // First three lines are header, last two lines are footer.
    for (int i = 3; i < lines.length - 2; i++) {
      final _UnzipListEntry entry = _UnzipListEntry.fromLine(lines[i]);
      fileToMetadata[entry.path] = entry;
    }

    final _UnzipListEntry libflutter = fileToMetadata['lib/armeabi-v7a/libflutter.so'];
    final _UnzipListEntry libapp = fileToMetadata['lib/armeabi-v7a/libapp.so'];
    final _UnzipListEntry license = fileToMetadata['assets/flutter_assets/NOTICES'];

    return <String, dynamic>{
      'libflutter_uncompressed_bytes': libflutter.uncompressedSize,
      'libflutter_compressed_bytes': libflutter.compressedSize,
      'libapp_uncompressed_bytes': libapp.uncompressedSize,
      'libapp_compressed_bytes': libapp.compressedSize,
      'license_uncompressed_bytes': license.uncompressedSize,
      'license_compressed_bytes': license.compressedSize,
    };
  }
}

/// Measure application memory usage.
class MemoryTest {
  MemoryTest(this.project, this.test, this.package);

  final String project;
  final String test;
  final String package;

  /// Completes when the log line specified in the last call to
  /// [prepareForNextMessage] is seen by `adb logcat`.
  Future<void> get receivedNextMessage => _receivedNextMessage?.future;
  Completer<void> _receivedNextMessage;
  String _nextMessage;

  /// Prepares the [receivedNextMessage] future such that it will complete
  /// when `adb logcat` sees a log line with the given `message`.
  void prepareForNextMessage(String message) {
    _nextMessage = message;
    _receivedNextMessage = Completer<void>();
  }

  int get iterationCount => 10;

  Device get device => _device;
  Device _device;

  Future<TaskResult> run() {
    return inDirectory<TaskResult>(project, () async {
      // This test currently only works on Android, because device.logcat,
      // device.getMemoryStats, etc, aren't implemented for iOS.

      _device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);

      final StreamSubscription<String> adb = device.logcat.listen(
        (String data) {
          if (data.contains('==== MEMORY BENCHMARK ==== $_nextMessage ===='))
            _receivedNextMessage.complete();
        },
      );

      for (int iteration = 0; iteration < iterationCount; iteration += 1) {
        print('running memory test iteration $iteration...');
        _startMemoryUsage = null;
        await useMemory();
        assert(_startMemoryUsage != null);
        assert(_startMemory.length == iteration + 1);
        assert(_endMemory.length == iteration + 1);
        assert(_diffMemory.length == iteration + 1);
        print('terminating...');
        await device.stop(package);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await adb.cancel();

      final ListStatistics startMemoryStatistics = ListStatistics(_startMemory);
      final ListStatistics endMemoryStatistics = ListStatistics(_endMemory);
      final ListStatistics diffMemoryStatistics = ListStatistics(_diffMemory);

      final Map<String, dynamic> memoryUsage = <String, dynamic>{
        ...startMemoryStatistics.asMap('start'),
        ...endMemoryStatistics.asMap('end'),
        ...diffMemoryStatistics.asMap('diff'),
      };

      _device = null;
      _startMemory.clear();
      _endMemory.clear();
      _diffMemory.clear();

      return TaskResult.success(memoryUsage, benchmarkScoreKeys: memoryUsage.keys.toList());
    });
  }

  /// Starts the app specified by [test] on the [device].
  ///
  /// The [run] method will terminate it by its package name ([package]).
  Future<void> launchApp() async {
    prepareForNextMessage('READY');
    print('launching $project$test on device...');
    await flutter('run', options: <String>[
      '--verbose',
      '--release',
      '--no-resident',
      '-d', device.deviceId,
      test,
    ]);
    print('awaiting "ready" message...');
    await receivedNextMessage;
  }

  /// To change the behavior of the test, override this.
  ///
  /// Make sure to call recordStart() and recordEnd() once each in that order.
  ///
  /// By default it just launches the app, records memory usage, taps the device,
  /// awaits a DONE notification, and records memory usage again.
  Future<void> useMemory() async {
    await launchApp();
    await recordStart();

    prepareForNextMessage('DONE');
    print('tapping device...');
    await device.tap(100, 100);
    print('awaiting "done" message...');
    await receivedNextMessage;

    await recordEnd();
  }

  final List<int> _startMemory = <int>[];
  final List<int> _endMemory = <int>[];
  final List<int> _diffMemory = <int>[];

  Map<String, dynamic> _startMemoryUsage;

  @protected
  Future<void> recordStart() async {
    assert(_startMemoryUsage == null);
    print('snapshotting memory usage...');
    _startMemoryUsage = await device.getMemoryStats(package);
  }

  @protected
  Future<void> recordEnd() async {
    assert(_startMemoryUsage != null);
    print('snapshotting memory usage...');
    final Map<String, dynamic> endMemoryUsage = await device.getMemoryStats(package);
    _startMemory.add(_startMemoryUsage['total_kb'] as int);
    _endMemory.add(endMemoryUsage['total_kb'] as int);
    _diffMemory.add((endMemoryUsage['total_kb'] as int) - (_startMemoryUsage['total_kb'] as int));
  }
}

class DevToolsMemoryTest {
  DevToolsMemoryTest(this.project, this.driverTest);

  final String project;
  final String driverTest;

  Future<TaskResult> run() {
    return inDirectory<TaskResult>(project, () async {
      _device = await devices.workingDevice;
      await _device.unlock();
      await flutter('packages', options: <String>['get']);

      await _launchApp();
      if (_observatoryUri == null) {
        return  TaskResult.failure('Observatory URI not found.');
      }

      await _launchDevTools();

      await flutter(
        'drive',
        options: <String>[
          '--use-existing-app', _observatoryUri,
          '-d', _device.deviceId,
          '--profile',
          driverTest,
        ],
      );

      _devToolsProcess.kill();
      await _devToolsProcess.exitCode;

      _runProcess.kill();
      await _runProcess.exitCode;

      final Map<String, dynamic> data = json.decode(
        file('$project/$_kJsonFileName').readAsStringSync(),
      ) as Map<String, dynamic>;
      final List<dynamic> samples = data['samples']['data'] as List<dynamic>;
      int maxRss = 0;
      int maxAdbTotal = 0;
      for (final dynamic sample in samples) {
        maxRss = math.max(maxRss, sample['rss'] as int);
        if (sample['adb_memoryInfo'] != null) {
          maxAdbTotal = math.max(maxAdbTotal, sample['adb_memoryInfo']['Total'] as int);
        }
      }
      return TaskResult.success(
          <String, dynamic>{'maxRss': maxRss, 'maxAdbTotal': maxAdbTotal},
          benchmarkScoreKeys: <String>['maxRss', 'maxAdbTotal'],
      );
    });
  }

  Future<void> _launchApp() async {
    print('launching $project$driverTest on device...');
    final String flutterPath = path.join(flutterDirectory.path, 'bin', 'flutter');
    _runProcess = await startProcess(
      flutterPath,
      <String>[
        'run',
        '--verbose',
        '--profile',
        '-d', _device.deviceId,
        driverTest,
      ],
    );

    // Listen for Observatory URI and forward stdout/stderr
    final Completer<String> observatoryUri = Completer<String>();
    _runProcess.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          print('run stdout: $line');
          final RegExpMatch match = RegExp(r'An Observatory debugger and profiler on .+ is available at: ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)').firstMatch(line);
          if (match != null) {
            observatoryUri.complete(match[1]);
            _observatoryUri = match[1];
          }
        }, onDone: () { observatoryUri.complete(null); });
    _forwardStream(_runProcess.stderr, 'run stderr');

    _observatoryUri = await observatoryUri.future;
  }

  Future<void> _launchDevTools() async {
    await exec(pubBin, <String>[
      'global',
      'activate',
      'devtools',
      '0.2.5',
    ]);
    _devToolsProcess = await startProcess(
      pubBin,
      <String>[
        'global',
        'run',
        'devtools',
        '--vm-uri', _observatoryUri,
        '--profile-memory', _kJsonFileName,
      ],
    );
    _forwardStream(_devToolsProcess.stdout, 'devtools stdout');
    _forwardStream(_devToolsProcess.stderr, 'devtools stderr');
  }

  void _forwardStream(Stream<List<int>> stream, String label) {
    stream
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
          print('$label: $line');
        });
  }

  Device _device;
  String _observatoryUri;
  Process _runProcess;
  Process _devToolsProcess;

  static const String _kJsonFileName = 'devtools_memory.json';
}

enum ReportedDurationTestFlavor {
  debug, profile, release
}

String _reportedDurationTestToString(ReportedDurationTestFlavor flavor) {
  switch (flavor) {
    case ReportedDurationTestFlavor.debug:
      return 'debug';
    case ReportedDurationTestFlavor.profile:
      return 'profile';
    case ReportedDurationTestFlavor.release:
      return 'release';
  }
  throw ArgumentError('Unexpected value for enum $flavor');
}

class ReportedDurationTest {
  ReportedDurationTest(this.flavor, this.project, this.test, this.package, this.durationPattern);

  final ReportedDurationTestFlavor flavor;
  final String project;
  final String test;
  final String package;
  final RegExp durationPattern;

  final Completer<int> durationCompleter = Completer<int>();

  int get iterationCount => 10;

  Device get device => _device;
  Device _device;

  Future<TaskResult> run() {
    return inDirectory<TaskResult>(project, () async {
      // This test currently only works on Android, because device.logcat,
      // device.getMemoryStats, etc, aren't implemented for iOS.

      _device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);

      final StreamSubscription<String> adb = device.logcat.listen(
        (String data) {
          if (durationPattern.hasMatch(data))
            durationCompleter.complete(int.parse(durationPattern.firstMatch(data).group(1)));
        },
      );
      print('launching $project$test on device...');
      await flutter('run', options: <String>[
        '--verbose',
        '--no-fast-start',
        '--${_reportedDurationTestToString(flavor)}',
        '--no-resident',
        '-d', device.deviceId,
        test,
      ]);

      final int duration = await durationCompleter.future;
      print('terminating...');
      await device.stop(package);
      await adb.cancel();

      _device = null;

      final Map<String, dynamic> reportedDuration = <String, dynamic>{
        'duration': duration,
      };
      _device = null;

      return TaskResult.success(reportedDuration, benchmarkScoreKeys: reportedDuration.keys.toList());
    });
  }
}

/// Holds simple statistics of an odd-lengthed list of integers.
class ListStatistics {
  factory ListStatistics(Iterable<int> data) {
    assert(data.isNotEmpty);
    assert(data.length % 2 == 1);
    final List<int> sortedData = data.toList()..sort();
    return ListStatistics._(
      sortedData.first,
      sortedData.last,
      sortedData[(sortedData.length - 1) ~/ 2],
    );
  }

  const ListStatistics._(this.min, this.max, this.median);

  final int min;
  final int max;
  final int median;

  Map<String, int> asMap(String prefix) {
    return <String, int>{
      '$prefix-min': min,
      '$prefix-max': max,
      '$prefix-median': median,
    };
  }
}

class _UnzipListEntry {
  factory _UnzipListEntry.fromLine(String line) {
    final List<String> data = line.trim().split(RegExp(r'\s+'));
    assert(data.length == 8);
    return _UnzipListEntry._(
      uncompressedSize:  int.parse(data[0]),
      compressedSize: int.parse(data[2]),
      path: data[7],
    );
  }

  _UnzipListEntry._({
    @required this.uncompressedSize,
    @required this.compressedSize,
    @required this.path,
  }) : assert(uncompressedSize != null),
       assert(compressedSize != null),
       assert(compressedSize <= uncompressedSize),
       assert(path != null);

  final int uncompressedSize;
  final int compressedSize;
  final String path;
}

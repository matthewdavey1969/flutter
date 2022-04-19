// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Directory;

import 'package:file/file.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;
  Process daemonProcess;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('daemon_mode_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
    daemonProcess?.kill();
  });

  testWithoutContext('device.getDevices', () async {
    final BasicProject project = BasicProject();
    await project.setUpIn(tempDir);

    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    const ProcessManager processManager = LocalProcessManager();
    daemonProcess = await processManager.start(
      <String>[flutterBin, ...getLocalEngineArguments(), '--show-test-device', 'daemon'],
      workingDirectory: tempDir.path,
    );

    final StreamController<String> stdout = StreamController<String>.broadcast();
    transformToLines(daemonProcess.stdout).listen((String line) => stdout.add(line));
    final Stream<Map<String, dynamic>> stream = stdout
      .stream
      .map<Map<String, dynamic>>(parseFlutterResponse)
      .where((Map<String, dynamic> value) => value != null);

    Map<String, dynamic> response = await stream.first;
    expect(response['event'], 'daemon.connected');

    // start listening for devices
    daemonProcess.stdin.writeln('[${jsonEncode(<String, dynamic>{
      'id': 1,
      'method': 'device.enable',
    })}]');
    response = await stream.firstWhere((Map<String, Object> json) => json['id'] == 1);
    expect(response['id'], 1);
    expect(response['error'], isNull);

    // [{"event":"device.added","params":{"id":"flutter-tester","name":
    //   "Flutter test device","platform":"flutter-tester","emulator":false}}]
    response = await stream.first;
    expect(response['event'], 'device.added');

    // get the list of all devices
    daemonProcess.stdin.writeln('[${jsonEncode(<String, dynamic>{
      'id': 2,
      'method': 'device.getDevices',
    })}]');
    // Skip other device.added events that may fire (desktop/web devices).
    response = await stream.firstWhere((Map<String, dynamic> response) => response['event'] != 'device.added');
    expect(response['id'], 2);
    expect(response['error'], isNull);

    final dynamic result = response['result'];
    expect(result, isList);
    expect(result, isNotEmpty);
  });
}

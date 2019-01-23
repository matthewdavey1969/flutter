// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/base/context.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(MacOSDevice, () {
    final MockPlatform notMac = MockPlatform();
    final MacOSDevice device = MacOSDevice();
    final MockProcessManager mockProcessManager = MockProcessManager();
    when(notMac.isMacOS).thenReturn(false);
    when(notMac.environment).thenReturn(const <String, String>{});
    when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
      return ProcessResult(0, 1, '', '');
    });

    testUsingContext('defaults', () async {
      final MockMacOSApp mockMacOSApp = MockMacOSApp();
      when(mockMacOSApp.executable).thenReturn('foo');
      expect(await device.targetPlatform, TargetPlatform.darwin_x64);
      expect(device.name, 'macOS');
      expect(await device.installApp(mockMacOSApp), true);
      expect(await device.uninstallApp(mockMacOSApp), true);
      expect(await device.isLatestBuildInstalled(mockMacOSApp), true);
      expect(await device.isAppInstalled(mockMacOSApp), true);
      expect(await device.stopApp(mockMacOSApp), false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });


    group('startApp', () {
      final MockMacOSApp macOSApp = MockMacOSApp();
      final MockFileSystem mockFileSystem = MockFileSystem();
      final MockProcessManager mockProcessManager = MockProcessManager();
      final MockFile mockFile = MockFile();
      final MockProcess mockProcess = MockProcess();
      when(macOSApp.executable).thenReturn('test');
      when(mockFileSystem.file('test')).thenReturn(mockFile);
      when(mockFile.existsSync()).thenReturn(true);
      when(mockProcessManager.start(<String>['test'])).thenAnswer((Invocation invocation) async {
        return mockProcess;
      });
      when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
        return ProcessResult(0, 1, '', '');
      });
      when(mockProcess.stdout).thenAnswer((Invocation invocation) {
        return Stream<List<int>>.fromIterable(<List<int>>[
          utf8.encode('Observatory listening on http://127.0.0.1/0'),
        ]);
      });

      test('fails without a prebuilt application', () async {
        final LaunchResult result = await device.startApp(macOSApp, prebuiltApplication: false);
        expect(result.started, false);
      });

      testUsingContext('Can run from prebuilt application', () async {
        final LaunchResult result = await device.startApp(macOSApp, prebuiltApplication: true);
        expect(result.started, true);
        expect(result.observatoryUri, Uri.parse('http://127.0.0.1/0'));
      }, overrides: <Type, Generator>{
        FileSystem: () => mockFileSystem,
        ProcessManager: () => mockProcessManager,
      });
    });

    test('noop port forwarding', () async {
      final MacOSDevice device = MacOSDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await MacOSDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notMac,
    });
  });
}

class MockPlatform extends Mock implements Platform {}

class MockMacOSApp extends Mock implements MacOSApp {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}

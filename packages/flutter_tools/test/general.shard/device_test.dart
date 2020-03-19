// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_devices.dart';

void main() {
  group('DeviceManager', () {
    testUsingContext('getDevices', () async {
      // Test that DeviceManager.getDevices() doesn't throw.
      final DeviceManager deviceManager = DeviceManager();
      final List<Device> devices = await deviceManager.getDevices();
      expect(devices, isList);
    });

    testUsingContext('getDeviceById', () async {
      final FakeDevice device1 = FakeDevice('Nexus 5', '0553790d0a4e726f');
      final FakeDevice device2 = FakeDevice('Nexus 5X', '01abfc49119c410e');
      final FakeDevice device3 = FakeDevice('iPod touch', '82564b38861a9a5');
      final List<Device> devices = <Device>[device1, device2, device3];
      final DeviceManager deviceManager = TestDeviceManager(devices);

      Future<void> expectDevice(String id, List<Device> expected) async {
        expect(await deviceManager.getDevicesById(id), expected);
      }
      await expectDevice('01abfc49119c410e', <Device>[device2]);
      await expectDevice('Nexus 5X', <Device>[device2]);
      await expectDevice('0553790d0a4e726f', <Device>[device1]);
      await expectDevice('Nexus 5', <Device>[device1]);
      await expectDevice('0553790', <Device>[device1]);
      await expectDevice('Nexus', <Device>[device1, device2]);
    });
  });

  group('Filter devices', () {
    FakeDevice ephemeral;
    FakeDevice nonEphemeralOne;
    FakeDevice nonEphemeralTwo;
    FakeDevice unsupported;
    FakeDevice webDevice;
    FakeDevice fuchsiaDevice;

    setUp(() {
      ephemeral = FakeDevice('ephemeral', 'ephemeral', true);
      nonEphemeralOne = FakeDevice('nonEphemeralOne', 'nonEphemeralOne', false);
      nonEphemeralTwo = FakeDevice('nonEphemeralTwo', 'nonEphemeralTwo', false);
      unsupported = FakeDevice('unsupported', 'unsupported', true, false);
      webDevice = FakeDevice('webby', 'webby')
        ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.web_javascript);
      fuchsiaDevice = FakeDevice('fuchsiay', 'fuchsiay')
        ..targetPlatform = Future<TargetPlatform>.value(TargetPlatform.fuchsia_x64);
    });

    testUsingContext('chooses ephemeral device', () async {
      final List<Device> devices = <Device>[
        ephemeral,
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered.single, ephemeral);
    });

    testUsingContext('does not remove all non-ephemeral', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ]);
    });

    testUsingContext('Removes a single unsupported device', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];

      final DeviceManager deviceManager = TestDeviceManager(devices);
      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[]);
    });

    testUsingContext('Removes web and fuchsia from --all', () async {
      final List<Device> devices = <Device>[
        webDevice,
        fuchsiaDevice,
      ];
      final DeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[]);
    });

    testUsingContext('Removes unsupported devices from --all', () async {
      final List<Device> devices = <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
        unsupported,
      ];
      final DeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.specifiedDeviceId = 'all';

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        nonEphemeralOne,
        nonEphemeralTwo,
      ]);
    });

    testUsingContext('uses DeviceManager.isDeviceSupportedForProject instead of device.isSupportedForProject', () async {
      final List<Device> devices = <Device>[
        unsupported,
      ];
      final TestDeviceManager deviceManager = TestDeviceManager(devices);
      deviceManager.isAlwaysSupportedOverride = true;

      final List<Device> filtered = await deviceManager.findTargetDevices(FlutterProject.current());

      expect(filtered, <Device>[
        unsupported,
      ]);
    });
  });
  group('ForwardedPort', () {
    group('dispose()', () {
      testUsingContext('does not throw exception if no process is present', () {
        final ForwardedPort forwardedPort = ForwardedPort(123, 456);
        expect(forwardedPort.context, isNull);
        forwardedPort.dispose();
      });

      testUsingContext('kills process if process was available', () {
        final MockProcess mockProcess = MockProcess();
        final ForwardedPort forwardedPort = ForwardedPort.withContext(123, 456, mockProcess);
        forwardedPort.dispose();
        expect(forwardedPort.context, isNotNull);
        verify(mockProcess.kill());
      });
    });
  });

  group('JSON encode devices', () {
    testUsingContext('Consistency of JSON representation', () async {
      expect(
        await Future.wait(fakeDevices.map((FakeDeviceJsonData d) => d.dev.toJson())),
        fakeDevices.map((FakeDeviceJsonData d) => d.json)
      );
    });
  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager(this.allDevices);

  final List<Device> allDevices;
  bool isAlwaysSupportedOverride;

  @override
  Future<List<Device>> getAllConnectedDevices() async => allDevices;

  @override
  bool isDeviceSupportedForProject(Device device, FlutterProject flutterProject) {
    if (isAlwaysSupportedOverride != null) {
      return isAlwaysSupportedOverride;
    }
    return super.isDeviceSupportedForProject(device, flutterProject);
  }
}

class MockProcess extends Mock implements Process {}

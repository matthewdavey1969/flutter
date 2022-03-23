// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/test/integration_test_device.dart';
import 'package:flutter_tools/src/test/test_device.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_devices.dart';
import '../src/fake_vm_services.dart';

final Map<String, Object> vm = <String, dynamic>{
  'isolates': <dynamic>[
    <String, dynamic>{
      'type': '@Isolate',
      'fixedId': true,
      'id': 'isolates/242098474',
      'name': 'main.dart:main()',
      'number': 242098474,
    },
  ],
};

final vm_service.Isolate isolate = vm_service.Isolate(
  id: '1',
  pauseEvent:
      vm_service.Event(kind: vm_service.EventKind.kResume, timestamp: 0),
  breakpoints: <vm_service.Breakpoint>[],
  exceptionPauseMode: null,
  libraries: <vm_service.LibraryRef>[
    vm_service.LibraryRef(
      id: '1',
      uri: 'file:///hello_world/main.dart',
      name: '',
    ),
  ],
  livePorts: 0,
  name: 'test',
  number: '1',
  pauseOnExit: false,
  runnable: true,
  startTime: 0,
  isSystemIsolate: false,
  isolateFlags: <vm_service.IsolateFlag>[],
  extensionRPCs: <String>[kIntegrationTestMethod],
);

final FlutterView fakeFlutterView = FlutterView(
  id: 'a',
  uiIsolate: isolate,
);

final FakeVmServiceRequest listViewsRequest = FakeVmServiceRequest(
  method: kListViewsMethod,
  jsonResponse: <String, Object>{
    'views': <Object>[
      fakeFlutterView.toJson(),
    ],
  },
);

final Uri observatoryUri = Uri.parse('http://localhost:1234');

void main() {
  FakeVmServiceHost fakeVmServiceHost;
  TestDevice testDevice;

  setUp(() {
    testDevice = IntegrationTestTestDevice(
      id: 1,
      device: FakeDevice(
        'ephemeral',
        'ephemeral',
        type: PlatformType.android,
        launchResult: LaunchResult.succeeded(observatoryUri: observatoryUri),
      ),
      debuggingOptions: DebuggingOptions.enabled(
        BuildInfo.debug,
      ),
      userIdentifier: '',
    );

    fakeVmServiceHost = FakeVmServiceHost(requests: <VmServiceExpectation>[
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      listViewsRequest,
      FakeVmServiceRequest(
        method: 'getIsolate',
        jsonResponse: isolate.toJson(),
        args: <String, Object>{
          'isolateId': '1',
        },
      ),
      const FakeVmServiceRequest(
        method: 'streamCancel',
        args: <String, Object>{
          'streamId': 'Isolate',
        },
      ),
      const FakeVmServiceRequest(
        method: 'streamListen',
        args: <String, Object>{
          'streamId': 'Extension',
        },
      ),
    ]);
  });

  testUsingContext('will not start when package missing', () async {
    await expectLater(
      testDevice.start('entrypointPath'),
      throwsA(
        isA<TestDeviceException>().having(
          (Exception e) => e.toString(),
          'description',
          contains('No application found for TargetPlatform.android_arm'),
        ),
      ),
    );
  });

  testUsingContext('Can start the entrypoint', () async {
    await testDevice.start('entrypointPath');

    expect(await testDevice.observatoryUri, observatoryUri);
    expect(testDevice.finished, doesNotComplete);
  }, overrides: <Type, Generator>{
    ApplicationPackageFactory: () => FakeApplicationPackageFactory(),
    VMServiceConnector: () => (
          Uri httpUri, {
          ReloadSources reloadSources,
          Restart restart,
          CompileExpression compileExpression,
          GetSkSLMethod getSkSLMethod,
          PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
          io.CompressionOptions compression,
          Device device,
          Logger logger,
        }) async =>
            fakeVmServiceHost.vmService,
  });

  testUsingContext('Can kill the started device', () async {
    await testDevice.start('entrypointPath');
    await testDevice.kill();

    expect(testDevice.finished, completes);
  }, overrides: <Type, Generator>{
    ApplicationPackageFactory: () => FakeApplicationPackageFactory(),
    VMServiceConnector: () => (
          Uri httpUri, {
          ReloadSources reloadSources,
          Restart restart,
          CompileExpression compileExpression,
          GetSkSLMethod getSkSLMethod,
          PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
          io.CompressionOptions compression,
          Device device,
          Logger logger,
        }) async =>
            fakeVmServiceHost.vmService,
  });

  testUsingContext(
      'when the device starts without providing an observatory URI', () async {
    final TestDevice testDevice = IntegrationTestTestDevice(
      id: 1,
      device: FakeDevice(
        'ephemeral',
        'ephemeral',
        type: PlatformType.android,
        launchResult: LaunchResult.succeeded(),
      ),
      debuggingOptions: DebuggingOptions.enabled(
        BuildInfo.debug,
      ),
      userIdentifier: '',
    );

    expect(() => testDevice.start('entrypointPath'),
        throwsA(isA<TestDeviceException>()));
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (
          Uri httpUri, {
          ReloadSources reloadSources,
          Restart restart,
          CompileExpression compileExpression,
          GetSkSLMethod getSkSLMethod,
          PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
          io.CompressionOptions compression,
          Device device,
        }) async =>
            fakeVmServiceHost.vmService,
  });

  testUsingContext('when the device fails to start', () async {
    final TestDevice testDevice = IntegrationTestTestDevice(
      id: 1,
      device: FakeDevice(
        'ephemeral',
        'ephemeral',
        type: PlatformType.android,
        launchResult: LaunchResult.failed(),
      ),
      debuggingOptions: DebuggingOptions.enabled(
        BuildInfo.debug,
      ),
      userIdentifier: '',
    );

    expect(() => testDevice.start('entrypointPath'),
        throwsA(isA<TestDeviceException>()));
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (
          Uri httpUri, {
          ReloadSources reloadSources,
          Restart restart,
          CompileExpression compileExpression,
          GetSkSLMethod getSkSLMethod,
          PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
          io.CompressionOptions compression,
          Device device,
        }) async =>
            fakeVmServiceHost.vmService,
  });

  testUsingContext('Can handle closing of the VM service', () async {
    final StreamChannel<String> channel =
        await testDevice.start('entrypointPath');
    await fakeVmServiceHost.vmService.dispose();
    expect(await channel.stream.isEmpty, true);
  }, overrides: <Type, Generator>{
    ApplicationPackageFactory: () => FakeApplicationPackageFactory(),
    VMServiceConnector: () => (
          Uri httpUri, {
          ReloadSources reloadSources,
          Restart restart,
          CompileExpression compileExpression,
          GetSkSLMethod getSkSLMethod,
          PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
          io.CompressionOptions compression,
          Device device,
          Logger logger,
        }) async =>
            fakeVmServiceHost.vmService,
  });
}

class FakeApplicationPackageFactory extends Fake
    implements ApplicationPackageFactory {
  @override
  Future<ApplicationPackage> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo buildInfo,
    File applicationBinary,
  }) async =>
      FakeApplicationPackage();
}

class FakeApplicationPackage extends Fake implements ApplicationPackage {}

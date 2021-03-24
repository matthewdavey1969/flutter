// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/io.dart' as io;
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/test/integration_test_device.dart';
import 'package:flutter_tools/src/test/test_device.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_devices.dart';

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
  pauseEvent: vm_service.Event(
      kind: vm_service.EventKind.kResume,
      timestamp: 0
  ),
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

  testUsingContext('Can start the entrypoint', () async {
    await testDevice.start('entrypointPath');

    expect(await testDevice.observatoryUri, observatoryUri);
    expect(testDevice.finished, doesNotComplete);
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      GetSkSLMethod getSkSLMethod,
      PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
      io.CompressionOptions compression,
      Device device,
    }) async => fakeVmServiceHost.vmService,
  });

  testUsingContext('Can kill the started device', () async {
    await testDevice.start('entrypointPath');
    await testDevice.kill();

    expect(testDevice.finished, completes);
  }, overrides: <Type, Generator>{
    VMServiceConnector: () => (Uri httpUri, {
      ReloadSources reloadSources,
      Restart restart,
      CompileExpression compileExpression,
      GetSkSLMethod getSkSLMethod,
      PrintStructuredErrorLogMethod printStructuredErrorLogMethod,
      io.CompressionOptions compression,
      Device device,
    }) async => fakeVmServiceHost.vmService,
  });
}

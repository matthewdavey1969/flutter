// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/web/devfs_web.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/discovery.dart';
import 'package:package_config/packages.dart';
import 'package:platform/platform.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/testbed.dart';

const List<int> kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
];

void main() {
  MockHttpServer mockHttpServer;
  StreamController<HttpRequest> requestController;
  Testbed testbed;
  MockHttpRequest request;
  MockHttpResponse response;
  MockHttpHeaders headers;
  Completer<void> closeCompleter;
  WebAssetServer webAssetServer;
  MockPlatform linux;
  Packages packages;
  MockPlatform windows;

  setUpAll(() async {
    packages = await loadPackagesFile(Uri.base.resolve('.packages'), loader: (Uri uri) async {
      return utf8.encode('\n');
    });
  });

  setUp(() {
    linux = MockPlatform();
    windows = MockPlatform();
    when(linux.isWindows).thenReturn(false);
    when(linux.environment).thenReturn(const <String, String>{});
    when(windows.environment).thenReturn(const <String, String>{});
    when(windows.isWindows).thenReturn(true);
    testbed = Testbed(setup: () {
      mockHttpServer = MockHttpServer();
      requestController = StreamController<HttpRequest>.broadcast();
      request = MockHttpRequest();
      response = MockHttpResponse();
      headers = MockHttpHeaders();
      closeCompleter = Completer<void>();
      when(mockHttpServer.listen(any, onError: anyNamed('onError'))).thenAnswer((Invocation invocation) {
        final void Function(HttpRequest) callback = invocation.positionalArguments.first as void Function(HttpRequest);
        return requestController.stream.listen(callback);
      });
      when(request.response).thenReturn(response);
      when(response.headers).thenReturn(headers);
      when(response.close()).thenAnswer((Invocation invocation) async {
        closeCompleter.complete();
      });
      webAssetServer = WebAssetServer(mockHttpServer, packages, InternetAddress.loopbackIPv4);
    });
  });

  tearDown(() async {
    await webAssetServer.dispose();
    await requestController.close();
  });

  test('Throws a tool exit if bind fails with a SocketException', () => testbed.run(() async {
    expect(WebAssetServer.start('hello', 1234, null), throwsToolExit());
  }));

  test('Can catch exceptions through the onError callback', () => testbed.run(() async {
    when(response.close()).thenAnswer((Invocation invocation) {
      throw StateError('Something bad');
    });
    webAssetServer.writeFile('/foo.js', 'main() {}');

    when(request.uri).thenReturn(Uri.parse('http://foobar/foo.js'));
    requestController.add(request);

    expect(closeCompleter.future, throwsStateError);
  }));

  test('Handles against malformed manifest', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');

    // Missing ending offset.
    final File manifestMissingOffset = globals.fs.file('manifestA')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0],
        'sourcemap': <int>[0],
      }}));
    final File manifestOutOfBounds = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, 100],
        'sourcemap': <int>[0],
      }}));

    expect(webAssetServer.write(source, manifestMissingOffset, sourcemap), isEmpty);
    expect(webAssetServer.write(source, manifestOutOfBounds, sourcemap), isEmpty);
  }));

  test('serves JavaScript files from in memory cache', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');
    final File manifest = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap);

    when(request.uri).thenReturn(Uri.parse('http://foobar/foo.js'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(headers.add('Content-Type', 'application/javascript')).called(1);
    verify(response.add(source.readAsBytesSync())).called(1);
  }, overrides: <Type, Generator>{
    Platform: () => linux,
  }));

  test('serves JavaScript files from in memory cache not from manifest', () => testbed.run(() async {
    webAssetServer.writeFile('/foo.js', 'main() {}');

    when(request.uri).thenReturn(Uri.parse('http://foobar/foo.js'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', 9)).called(1);
    verify(headers.add('Content-Type', 'application/javascript')).called(1);
    verify(response.add(any)).called(1);
  }));

  test('handles missing JavaScript files from in memory cache', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');
    final File manifest = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap);

    when(request.uri).thenReturn(Uri.parse('http://foobar/bar.js'));
    requestController.add(request);
    await closeCompleter.future;

    verify(response.statusCode = 404).called(1);
  }));

  test('serves JavaScript files from in memory cache on Windows', () => testbed.run(() async {
    final File source = globals.fs.file('source')
      ..writeAsStringSync('main() {}');
    final File sourcemap = globals.fs.file('sourcemap')
      ..writeAsStringSync('{}');
    final File manifest = globals.fs.file('manifest')
      ..writeAsStringSync(json.encode(<String, Object>{'/C:/foo.js': <String, Object>{
        'code': <int>[0, source.lengthSync()],
        'sourcemap': <int>[0, 2],
      }}));
    webAssetServer.write(source, manifest, sourcemap);

    when(request.uri).thenReturn(Uri.parse('http://foobar/C:/foo.js'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(headers.add('Content-Type', 'application/javascript')).called(1);
    verify(response.add(source.readAsBytesSync())).called(1);
  }, overrides: <Type, Generator>{
    Platform: () => windows,
  }));

   test('serves Dart files from in filesystem on Windows', () => testbed.run(() async {
    final File source = globals.fs.file('foo.dart').absolute
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');

    when(request.uri).thenReturn(Uri.parse('http://foobar/C:/foo.dart'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(response.addStream(any)).called(1);
  }, overrides: <Type,  Generator>{
    Platform: () => windows,
  }));

   test('serves asset files from in filesystem with known mime type on Windows', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);

    when(request.uri).thenReturn(Uri.parse('http://foobar/assets/foo.png'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(headers.add('Content-Type', 'image/png')).called(1);
    verify(response.addStream(any)).called(1);
  }, overrides: <Type,  Generator>{
    Platform: () => windows,
  }));

  test('serves Dart files from in filesystem on Linux/macOS', () => testbed.run(() async {
    final File source = globals.fs.file('foo.dart').absolute
      ..createSync(recursive: true)
      ..writeAsStringSync('void main() {}');

    when(request.uri).thenReturn(Uri.parse('http://foobar/foo.dart'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(response.addStream(any)).called(1);
  }, overrides: <Type,  Generator>{
    Platform: () => linux,
  }));

  test('Handles missing Dart files from filesystem', () => testbed.run(() async {
    when(request.uri).thenReturn(Uri.parse('http://foobar/foo.dart'));
    requestController.add(request);
    await closeCompleter.future;

    verify(response.statusCode = 404).called(1);
  }));

  test('serves asset files from in filesystem with known mime type', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo.png'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(kTransparentImage);

    when(request.uri).thenReturn(Uri.parse('http://foobar/assets/foo.png'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(headers.add('Content-Type', 'image/png')).called(1);
    verify(response.addStream(any)).called(1);
  }));

  test('serves asset files files from in filesystem with unknown mime type and length > 12', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(List<int>.filled(100, 0));

    when(request.uri).thenReturn(Uri.parse('http://foobar/assets/foo'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(headers.add('Content-Type', 'application/octet-stream')).called(1);
    verify(response.addStream(any)).called(1);
  }));

  test('serves asset files files from in filesystem with unknown mime type and length < 12', () => testbed.run(() async {
    final File source = globals.fs.file(globals.fs.path.join('build', 'flutter_assets', 'foo'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);

    when(request.uri).thenReturn(Uri.parse('http://foobar/assets/foo'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(headers.add('Content-Type', 'application/octet-stream')).called(1);
    verify(response.addStream(any)).called(1);
  }));

  test('handles serving missing asset file', () => testbed.run(() async {
    when(request.uri).thenReturn(Uri.parse('http://foobar/assets/foo'));
    requestController.add(request);
    await closeCompleter.future;

    verify(response.statusCode = HttpStatus.notFound).called(1);
  }));

  test('serves /packages/<package>/<path> files as if they were '
       'package:<package>/<path> uris', () => testbed.run(() async {
    final Uri expectedUri = packages.resolve(
        Uri.parse('package:flutter_tools/foo.dart'));
    final File source = globals.fs.file(globals.fs.path.fromUri(expectedUri))
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[1, 2, 3]);
    when(request.uri).thenReturn(
        Uri.parse('http:///packages/flutter_tools/foo.dart'));
    requestController.add(request);
    await closeCompleter.future;

    verify(headers.add('Content-Length', source.lengthSync())).called(1);
    verify(headers.add('Content-Type', 'application/octet-stream')).called(1);
    verify(response.addStream(any)).called(1);
  }));

  test('calling dispose closes the http server', () => testbed.run(() async {
    await webAssetServer.dispose();

    verify(mockHttpServer.close()).called(1);
  }));

  test('Can start web server with specified assets', () => testbed.run(() async {
    globals.fs.file('a.sources').writeAsStringSync('');
    globals.fs.file('a.json').writeAsStringSync('{}');
    globals.fs.file('a.map').writeAsStringSync('{}');
    globals.fs.file('.packages').writeAsStringSync('\n');

    final ResidentCompiler residentCompiler = MockResidentCompiler();
    when(residentCompiler.recompile(
      any,
      any,
      outputPath: anyNamed('outputPath'),
      packagesFilePath: anyNamed('packagesFilePath'),
    )).thenAnswer((Invocation invocation) async {
      return const CompilerOutput('a', 0, <Uri>[]);
    });

    final WebDevFS webDevFS = WebDevFS('localhost', 0, '.packages', null);
    webDevFS.requireJS.createSync(recursive: true);
    webDevFS.dartSdk.createSync(recursive: true);
    webDevFS.dartSdkSourcemap.createSync(recursive: true);
    webDevFS.stackTraceMapper.createSync(recursive: true);

    await webDevFS.create();
    await webDevFS.update(
      mainPath: globals.fs.path.join('lib', 'main.dart'),
      generator: residentCompiler,
      trackWidgetCreation: true,
      bundleFirstUpload: true,
      invalidatedFiles: <Uri>[],
    );

    expect(webDevFS.webAssetServer.getFile('/manifest.json'), isNotNull);
    expect(webDevFS.webAssetServer.getFile('/flutter_service_worker.js'), isNotNull);

    await webDevFS.destroy();
  }));
}

class MockHttpServer extends Mock implements HttpServer {}
class MockHttpRequest extends Mock implements HttpRequest {}
class MockHttpResponse extends Mock implements HttpResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}
class MockPlatform extends Mock implements Platform {}
class MockResidentCompiler extends Mock implements ResidentCompiler {}

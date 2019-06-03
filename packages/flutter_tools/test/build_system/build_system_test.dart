// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:crypto/crypto.dart' show md5;

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/file_cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/testbed.dart';

void main() {
  group(Target, () {
    Testbed testbed;
    MockPlatform mockPlatform;
    Environment environment;
    Target fooTarget;
    Target barTarget;
    BuildSystem buildSystem;
    int fooInvocations;
    int barInvocations;

    setUp(() {
      fooInvocations = 0;
      barInvocations = 0;
      mockPlatform = MockPlatform();
      // Keep file paths the same.
      when(mockPlatform.isWindows).thenReturn(false);
      testbed = Testbed(
        setup: () {
          environment = Environment(
            projectDir: fs.currentDirectory,
            targetPlatform: TargetPlatform.android_arm,
            buildMode: BuildMode.debug,
          );
          fs.file('foo.dart').createSync(recursive: true);
          fs.file('pubspec.yaml').createSync();
          fooTarget = Target(
            name: 'foo',
            inputs: const <Source>[
              Source.pattern('{PROJECT_DIR}/foo.dart'),
            ],
            outputs: const <Source>[
              Source.pattern('{BUILD_DIR}/out'),
            ],
            dependencies: <Target>[],
            modes: <BuildMode>[BuildMode.debug],
            invocation: (Map<String, ChangeType> updates, Environment environment) {
              environment.buildDir.childFile('out')
                ..createSync(recursive: true)
                ..writeAsStringSync('hey');
              fooInvocations++;
            }
          );
          barTarget = Target(
            name: 'bar',
            inputs: const <Source>[
              Source.pattern('{BUILD_DIR}/out'),
            ],
            outputs: const <Source>[
              Source.pattern('{BUILD_DIR}/bar'),
            ],
            dependencies: <Target>[fooTarget],
            invocation: (Map<String, ChangeType> updates, Environment environment) {
              environment.buildDir.childFile('bar')
                ..createSync(recursive: true)
                ..writeAsStringSync('there');
              barInvocations++;
            }
          );
          buildSystem = BuildSystem(<Target>[
            fooTarget,
            barTarget,
          ]);
        },
        overrides: <Type, Generator>{
          Platform: () => mockPlatform,
        }
      );
    });

    test('Throws exception if asked to build non-existent target', () => testbed.run(() {
      expect(buildSystem.build('not_real', environment), throwsA(isInstanceOf<Exception>()));
    }));

    test('Throws exception if asked to build with unsupported environment', () => testbed.run(() {
      final Environment environment = Environment(projectDir: fs.currentDirectory, buildMode: BuildMode.release);

      expect(buildSystem.build('foo', environment), throwsA(isInstanceOf<InvalidBuildException>()));
    }));

    test('Throws exception if asked to build with missing inputs', () => testbed.run(() {
      // Delete required input file.
      fs.file('foo.dart').deleteSync();

      expect(buildSystem.build('foo', environment), throwsA(isInstanceOf<MissingInputException>()));
    }));

    test('Saves a stamp file with inputs and outputs', () => testbed.run(() async {
      await buildSystem.build('foo', environment);

      final File stampFile = fs.file('build/foo.debug.android-arm.none');
      expect(stampFile.existsSync(), true);

      final Map<String, Object> stampContents = json.decode(stampFile.readAsStringSync());
      expect(stampContents['inputs'], <Object>['/foo.dart']);
    }));

    test('Does not re-invoke build if stamp is valid', () => testbed.run(() async {
      await buildSystem.build('foo', environment);
      await buildSystem.build('foo', environment);

      expect(fooInvocations, 1);
    }));

    test('Re-invoke build if input is modified', () => testbed.run(() async {
      await buildSystem.build('foo', environment);

      fs.file('foo.dart').writeAsStringSync('new contents');

      await buildSystem.build('foo', environment);
      expect(fooInvocations, 2);
    }));

    test('Runs dependencies of targets', () => testbed.run(() async {
      await buildSystem.build('bar', environment);

      expect(fs.file('build/bar').existsSync(), true);
      expect(fooInvocations, 1);
      expect(barInvocations, 1);
    }));

    test('Can describe itself with JSON output', () => testbed.run(() {
      expect(fooTarget.toJson(environment), <String, dynamic>{
        'inputs':  <Object>[
          '/foo.dart'
        ],
        'dependencies': <Object>[],
        'name':  'foo'
      });
    }));

    test('Compute update recognizes added files', () => testbed.run(() async {
      fs.directory('build').createSync();
      final FileCache fileCache = FileCache(environment);
      fileCache.initialize();
      final List<FileSystemEntity> inputs = fooTarget.resolveInputs(environment);
      final Map<String, ChangeType> changes = await fooTarget.computeChanges(inputs, environment, fileCache);
      fileCache.persist();

      expect(changes, <String, ChangeType>{
        '/foo.dart': ChangeType.Added
      });

      await buildSystem.build('foo', environment);
      final Map<String, ChangeType> secondChanges = await fooTarget.computeChanges(inputs, environment, fileCache);

      expect(secondChanges, <String, ChangeType>{});
    }));
  });

  group('FileCache', () {
    Testbed testbed;
    Environment environment;

    setUp(() {
      testbed = Testbed(setup: () {
        fs.directory('build').createSync();
        environment = Environment(projectDir: fs.currentDirectory);
      });
    });

    test('Initializes file cache', () => testbed.run(() {
      final FileCache fileCache = FileCache(environment);
      fileCache.initialize();
      fileCache.persist();

      expect(fs.file('build/.filecache').existsSync(), true);
      expect(fs.file('build/.filecache').readAsStringSync(), '');
      expect(fs.file('build/.filecache_version').existsSync(), true);
      expect(fs.file('build/.filecache_version').readAsStringSync(), '1');
    }));

    test('saves and restores to file cache', () => testbed.run(() {
      final File file = fs.file('foo.dart')
        ..createSync()
        ..writeAsStringSync('hello');
      final FileCache fileCache = FileCache(environment);
      fileCache.initialize();
      fileCache.hashFiles(<File>[file]);
      fileCache.persist();

      final List<int> bytes = file.readAsBytesSync();
      final String currentHash = md5.convert(bytes).toString();

      expect(fs.file('build/.filecache').readAsStringSync(), '/foo.dart : $currentHash');
      expect(fs.file('build/.filecache_version').readAsStringSync(), '1');

      final FileCache newFileCache = FileCache(environment);
      newFileCache.initialize();
      expect(newFileCache.currentHashes, isEmpty);
      expect(newFileCache.previousHashes['/foo.dart'],  currentHash);
      newFileCache.persist();

      // Still persisted correctly.
      expect(fs.file('build/.filecache').readAsStringSync(), '/foo.dart : $currentHash');
      expect(fs.file('build/.filecache_version').readAsStringSync(), '1');
    }));
  });

  group(Target, () {
    Testbed testbed;
    MockPlatform mockPlatform;
    Environment environment;
    Target sharedTarget;
    BuildSystem buildSystem;
    int shared;

    setUp(() {
      shared = 0;
      mockPlatform = MockPlatform();
      // Keep file paths the same.
      when(mockPlatform.isWindows).thenReturn(false);
      testbed = Testbed(
          setup: () {
            environment = Environment(
              projectDir: fs.currentDirectory,
              targetPlatform: TargetPlatform.android_arm,
              buildMode: BuildMode.debug,
            );
            fs.file('foo.dart').createSync(recursive: true);
            fs.file('pubspec.yaml').createSync();
            sharedTarget = Target(
              name: 'shared',
              inputs: const <Source>[
                Source.pattern('{PROJECT_DIR}/foo.dart'),
              ],
              outputs: const <Source>[],
              dependencies: <Target>[],
              invocation: (Map<String, ChangeType> updates, Environment environment) {
                shared += 1;
              }
            );
            final Target fooTarget = Target(
                name: 'foo',
                inputs: const <Source>[
                  Source.pattern('{PROJECT_DIR}/foo.dart'),
                ],
                outputs: const <Source>[
                  Source.pattern('{BUILD_DIR}/out'),
                ],
                dependencies: <Target>[sharedTarget],
                invocation: (Map<String, ChangeType> updates, Environment environment) {
                  environment.buildDir.childFile('out')
                    ..createSync(recursive: true)
                    ..writeAsStringSync('hey');
                }
            );
            final Target barTarget = Target(
                name: 'bar',
                inputs: const <Source>[
                  Source.pattern('{BUILD_DIR}/out'),
                ],
                outputs: const <Source>[
                  Source.pattern('{BUILD_DIR}/bar'),
                ],
                dependencies: <Target>[fooTarget, sharedTarget],
                invocation: (Map<String, ChangeType> updates, Environment environment) {
                  environment.buildDir.childFile('bar')
                    ..createSync(recursive: true)
                    ..writeAsStringSync('there');
                }
            );
            buildSystem = BuildSystem(<Target>[
              fooTarget,
              barTarget,
              sharedTarget,
            ]);
          },
          overrides: <Type, Generator>{
            Platform: () => mockPlatform,
          }
      );
    });

    test('Only invokes shared target once', () => testbed.run(() async {
      await buildSystem.build('bar', environment);

      expect(shared, 1);
    }));
  });


  group('Patterns', () {
    Testbed testbed;
    SourceVisitor visitor;

    setUp(() {
      testbed = Testbed(setup: () {
        fs.directory('cache').createSync();
        fs.directory('build').createSync();
        final Environment environment = Environment(
          projectDir: fs.currentDirectory,
          cacheDir: fs.directory('cache'),
          buildDir: fs.directory('build'),
          targetPlatform: TargetPlatform.android_arm,
          buildMode: BuildMode.debug,
          flavor: 'flavor_town',
        );
        visitor = SourceVisitor(environment);
      });
    });

    test('can substitute {PROJECT_DIR}/foo', () => testbed.run(() {
      const Source fooSource = Source.pattern('{PROJECT_DIR}/foo');
      fooSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute('foo'));
    }));

    test('can substitute {BUILD_DIR}/bar', () => testbed.run(() {
      const Source barSource = Source.pattern('{BUILD_DIR}/bar');
      barSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute(fs.path.join('build', 'bar')));
    }));

    test('can substitute {CACHE_DIR}/fizz', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{CACHE_DIR}/fizz');
      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute(fs.path.join('cache', 'fizz')));
    }));

    test('can substitute {PROJECT_DIR}/{mode}/{flavor}/{platform}/fizz', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{PROJECT_DIR}/{mode}/{flavor}/{platform}/fizz');
      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute(fs.path.join('debug', 'flavor_town', 'android-arm', 'fizz')));
    }));

    test('can substitute {PROJECT_DIR}/{mode}.{flavor}.{platform}.fizz', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{PROJECT_DIR}/{mode}.{flavor}.{platform}.fizz');
      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute(fs.path.join('debug.flavor_town.android-arm.fizz')));
    }));

    test('can substitute {PROJECT_DIR}/*.fizz', () => testbed.run(() {
      const Source fizzSource = Source.pattern('{PROJECT_DIR}/*.fizz');
      fizzSource.accept(visitor);

      expect(visitor.sources, isEmpty);

      fs.file('foo.fizz').createSync();
      fs.file('foofizz').createSync();


      fizzSource.accept(visitor);

      expect(visitor.sources.single.path, fs.path.absolute('foo.fizz'));
    }));


    test('can\'t substitute foo', () => testbed.run(() {
      const Source invalidBase = Source.pattern('foo');

      expect(() => invalidBase.accept(visitor), throwsA(isInstanceOf<InvalidPatternException>()));
    }));

  });

  test('Can find dependency cycles', () {
    final Target barTarget = Target(
      name: 'bar',
      inputs: <Source>[],
      outputs: <Source>[],
      invocation: null,
      dependencies: nonconst(<Target>[])
    );
    final Target fooTarget = Target(
      name: 'foo',
      inputs: <Source>[],
      outputs: <Source>[],
      invocation: null,
      dependencies: nonconst(<Target>[])
    );
    barTarget.dependencies.add(fooTarget);
    fooTarget.dependencies.add(barTarget);
    expect(() => checkCycles(barTarget), throwsA(isInstanceOf<CycleException>()));
  });
}

class MockPlatform extends Mock implements Platform {}

// Work-around for silly lint check.
T nonconst<T>(T input) => input;
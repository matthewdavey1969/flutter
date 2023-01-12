// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device_port_forwarder.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/mdns_discovery.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:test/fake.dart';

import '../src/common.dart';

void main() {
  group('mDNS Discovery', () {
    final int year3000 = DateTime(3000).millisecondsSinceEpoch;

    setUp(() {
      setNetworkInterfaceLister(
        ({
          bool? includeLoopback,
          bool? includeLinkLocal,
          InternetAddressType? type,
        }) async => <NetworkInterface>[],
      );
    });

    tearDown(() {
      resetNetworkInterfaceLister();
    });

    group('for attach', () {
      late MDnsClient emptyClient;

      setUp(() {
        emptyClient = FakeMDnsClient(<PtrResourceRecord>[], <String, List<SrvResourceRecord>>{});
      });

      testWithoutContext('Find result in preliminary client', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
          },
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: emptyClient,
          preliminaryMDnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );

        final MDnsObservatoryDiscoveryResult? result = await portDiscovery.queryForAttach();
        expect(result, isNotNull);
      });

      testWithoutContext('Do not find result in preliminary client, but find in main client', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
          },
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );

        final MDnsObservatoryDiscoveryResult? result = await portDiscovery.queryForAttach();
        expect(result, isNotNull);
      });

      testWithoutContext('Find multiple in preliminary client', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
            PtrResourceRecord('baz', year3000, domainName: 'fiz'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
            'fiz': <SrvResourceRecord>[
              SrvResourceRecord('fiz', year3000, port: 321, weight: 1, priority: 1, target: 'local'),
            ],
          },
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: emptyClient,
          preliminaryMDnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );

        expect(portDiscovery.queryForAttach, throwsToolExit());
      });

      testWithoutContext('No ports available', () async {
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: emptyClient,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );

        final int? port = (await portDiscovery.queryForAttach())?.port;
        expect(port, isNull);
      });

      testWithoutContext('Prints helpful message when there is no ipv4 link local address.', () async {
        final BufferLogger logger = BufferLogger.test();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: emptyClient,
          preliminaryMDnsClient: emptyClient,
          logger: logger,
          flutterUsage: TestUsage(),
        );
        final Uri? uri = await portDiscovery.getObservatoryUriForAttach(
          '',
          FakeIOSDevice(),
        );
        expect(uri, isNull);
        expect(logger.errorText, contains('Personal Hotspot'));
      });

      testWithoutContext('One port available, no appId', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
          },
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final int? port = (await portDiscovery.queryForAttach())?.port;
        expect(port, 123);
      });

      testWithoutContext('One port available, no appId, with authCode', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
          },
          txtResponse: <String, List<TxtResourceRecord>>{
            'bar': <TxtResourceRecord>[
              TxtResourceRecord('bar', year3000, text: 'authCode=xyz\n'),
            ],
          },
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final MDnsObservatoryDiscoveryResult? result = await portDiscovery.queryForAttach();
        expect(result?.port, 123);
        expect(result?.authCode, 'xyz/');
      });

      testWithoutContext('Multiple ports available, with appId', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
            PtrResourceRecord('baz', year3000, domainName: 'fiz'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
            'fiz': <SrvResourceRecord>[
              SrvResourceRecord('fiz', year3000, port: 321, weight: 1, priority: 1, target: 'local'),
            ],
          },
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final int? port = (await portDiscovery.queryForAttach(applicationId: 'fiz'))?.port;
        expect(port, 321);
      });

      testWithoutContext('Multiple ports available per process, with appId', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
            PtrResourceRecord('baz', year3000, domainName: 'fiz'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 1234, weight: 1, priority: 1, target: 'appId'),
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
            'fiz': <SrvResourceRecord>[
              SrvResourceRecord('fiz', year3000, port: 4321, weight: 1, priority: 1, target: 'local'),
              SrvResourceRecord('fiz', year3000, port: 321, weight: 1, priority: 1, target: 'local'),
            ],
          },
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final int? port = (await portDiscovery.queryForAttach(applicationId: 'bar'))?.port;
        expect(port, 1234);
      });

      testWithoutContext('Throws Exception when client throws OSError on start', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[], <String, List<SrvResourceRecord>>{},
          osErrorOnStart: true,
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        expect(
          () async => portDiscovery.queryForAttach(),
          throwsException,
        );
      });

      testWithoutContext('Correctly builds Observatory URI with hostVmservicePort == 0', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
          },
        );

        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final Uri? uri = await portDiscovery.getObservatoryUriForAttach('bar', device, hostVmservicePort: 0);
        expect(uri.toString(), 'http://127.0.0.1:123/');
      });

      testWithoutContext('Get network device IP (iPv4)', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 1234, weight: 1, priority: 1, target: 'appId'),
            ],
          },
          ipResponse: <String, List<IPAddressResourceRecord>>{
            'appId': <IPAddressResourceRecord>[
              IPAddressResourceRecord('Device IP', 0, address: InternetAddress.tryParse('111.111.111.111')!),
            ],
          },
          txtResponse: <String, List<TxtResourceRecord>>{
            'bar': <TxtResourceRecord>[
              TxtResourceRecord('bar', year3000, text: 'authCode=xyz\n'),
            ],
          },
        );

        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final Uri? uri = await portDiscovery.getObservatoryUriForAttach(
          'bar',
          device,
          isNetworkDevice: true,
        );
        expect(uri.toString(), 'http://111.111.111.111:1234/xyz/');
      });

      testWithoutContext('Get network device IP (iPv6)', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 1234, weight: 1, priority: 1, target: 'appId'),
            ],
          },
          ipResponse: <String, List<IPAddressResourceRecord>>{
            'appId': <IPAddressResourceRecord>[
              IPAddressResourceRecord('Device IP', 0, address: InternetAddress.tryParse('1111:1111:1111:1111:1111:1111:1111:1111')!),
            ],
          },
          txtResponse: <String, List<TxtResourceRecord>>{
            'bar': <TxtResourceRecord>[
              TxtResourceRecord('bar', year3000, text: 'authCode=xyz\n'),
            ],
          },
        );

        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final Uri? uri = await portDiscovery.getObservatoryUriForAttach(
          'bar',
          device,
          isNetworkDevice: true,
        );
        expect(uri.toString(), 'http://[1111:1111:1111:1111:1111:1111:1111:1111]:1234/xyz/');
      });

      testWithoutContext('Throw error if unable to find observatory with app id and device port', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'srv-foo'),
            PtrResourceRecord('bar', year3000, domainName: 'srv-bar'),
            PtrResourceRecord('baz', year3000, domainName: 'srv-boo'),
          ],
          <String, List<SrvResourceRecord>>{
            'srv-foo': <SrvResourceRecord>[
              SrvResourceRecord('srv-foo', year3000, port: 123, weight: 1, priority: 1, target: 'target-foo'),
            ],
            'srv-bar': <SrvResourceRecord>[
              SrvResourceRecord('srv-bar', year3000, port: 123, weight: 1, priority: 1, target: 'target-bar'),
            ],
            'srv-baz': <SrvResourceRecord>[
              SrvResourceRecord('srv-baz', year3000, port: 123, weight: 1, priority: 1, target: 'target-baz'),
            ],
          },
        );
        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        expect(
          portDiscovery.getObservatoryUriForAttach(
            'srv-bar',
            device,
            deviceVmservicePort: 321,
          ),
          throwsToolExit(
            message: 'Did not find an observatory advertised for srv-bar on port 321.'
          ),
        );
      });

      testWithoutContext('Throw error if unable to find observatory with app id', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'srv-foo'),
          ],
          <String, List<SrvResourceRecord>>{
            'srv-foo': <SrvResourceRecord>[
              SrvResourceRecord('srv-foo', year3000, port: 123, weight: 1, priority: 1, target: 'target-foo'),
            ],
          },
        );
        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          preliminaryMDnsClient: emptyClient,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        expect(
          portDiscovery.getObservatoryUriForAttach(
            'srv-asdf',
            device,
          ),
          throwsToolExit(
            message: 'Did not find an observatory advertised for srv-asdf.'
          ),
        );
      });
    });

    group('for launch', () {
      testWithoutContext('No ports available', () async {
        final MDnsClient client = FakeMDnsClient(<PtrResourceRecord>[], <String, List<SrvResourceRecord>>{});

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );

        final MDnsObservatoryDiscoveryResult? result = await portDiscovery.queryForLaunch(
          applicationId: 'app-id',
          deviceVmservicePort: 123,
        );

        expect(result, null);
      });

      testWithoutContext('Prints helpful message when there is no ipv4 link local address.', () async {
        final MDnsClient client = FakeMDnsClient(<PtrResourceRecord>[], <String, List<SrvResourceRecord>>{});
        final BufferLogger logger = BufferLogger.test();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          logger: logger,
          flutterUsage: TestUsage(),
        );

        final Uri? uri = await portDiscovery.getObservatoryUriForLaunch(
          '',
          FakeIOSDevice(),
          deviceVmservicePort: 0,
        );
        expect(uri, isNull);
        expect(logger.errorText, contains('Personal Hotspot'));
      });

      testWithoutContext('Throws Exception when client throws OSError on start', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[], <String, List<SrvResourceRecord>>{},
          osErrorOnStart: true,
        );

        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        expect(
          () async => portDiscovery.queryForLaunch(applicationId: 'app-id', deviceVmservicePort: 123),
          throwsException,
        );
      });

      testWithoutContext('Correctly builds Observatory URI with hostVmservicePort == 0', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 123, weight: 1, priority: 1, target: 'appId'),
            ],
          },
        );

        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final Uri? uri = await portDiscovery.getObservatoryUriForLaunch(
          'bar',
          device,
          hostVmservicePort: 0,
          deviceVmservicePort: 123,
        );
        expect(uri.toString(), 'http://127.0.0.1:123/');
      });

      testWithoutContext('Get network device IP (iPv4)', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 1234, weight: 1, priority: 1, target: 'appId'),
            ],
          },
          ipResponse: <String, List<IPAddressResourceRecord>>{
            'appId': <IPAddressResourceRecord>[
              IPAddressResourceRecord('Device IP', 0, address: InternetAddress.tryParse('111.111.111.111')!),
            ],
          },
          txtResponse: <String, List<TxtResourceRecord>>{
            'bar': <TxtResourceRecord>[
              TxtResourceRecord('bar', year3000, text: 'authCode=xyz\n'),
            ],
          },
        );

        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final Uri? uri = await portDiscovery.getObservatoryUriForLaunch(
          'bar',
          device,
          isNetworkDevice: true,
          deviceVmservicePort: 1234,
        );
        expect(uri.toString(), 'http://111.111.111.111:1234/xyz/');
      });

      testWithoutContext('Get network device IP (iPv6)', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'bar'),
          ],
          <String, List<SrvResourceRecord>>{
            'bar': <SrvResourceRecord>[
              SrvResourceRecord('bar', year3000, port: 1234, weight: 1, priority: 1, target: 'appId'),
            ],
          },
          ipResponse: <String, List<IPAddressResourceRecord>>{
            'appId': <IPAddressResourceRecord>[
              IPAddressResourceRecord('Device IP', 0, address: InternetAddress.tryParse('1111:1111:1111:1111:1111:1111:1111:1111')!),
            ],
          },
          txtResponse: <String, List<TxtResourceRecord>>{
            'bar': <TxtResourceRecord>[
              TxtResourceRecord('bar', year3000, text: 'authCode=xyz\n'),
            ],
          },
        );

        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        final Uri? uri = await portDiscovery.getObservatoryUriForLaunch(
          'bar',
          device,
          isNetworkDevice: true,
          deviceVmservicePort: 1234,
        );
        expect(uri.toString(), 'http://[1111:1111:1111:1111:1111:1111:1111:1111]:1234/xyz/');
      });

      testWithoutContext('Throw error if unable to find observatory with app id and device port', () async {
        final MDnsClient client = FakeMDnsClient(
          <PtrResourceRecord>[
            PtrResourceRecord('foo', year3000, domainName: 'srv-foo'),
            PtrResourceRecord('bar', year3000, domainName: 'srv-bar'),
            PtrResourceRecord('baz', year3000, domainName: 'srv-boo'),
          ],
          <String, List<SrvResourceRecord>>{
            'srv-foo': <SrvResourceRecord>[
              SrvResourceRecord('srv-foo', year3000, port: 123, weight: 1, priority: 1, target: 'target-foo'),
            ],
            'srv-bar': <SrvResourceRecord>[
              SrvResourceRecord('srv-bar', year3000, port: 123, weight: 1, priority: 1, target: 'target-bar'),
            ],
            'srv-baz': <SrvResourceRecord>[
              SrvResourceRecord('srv-baz', year3000, port: 123, weight: 1, priority: 1, target: 'target-baz'),
            ],
          },
        );
        final FakeIOSDevice device = FakeIOSDevice();
        final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
          mdnsClient: client,
          logger: BufferLogger.test(),
          flutterUsage: TestUsage(),
        );
        expect(
          portDiscovery.getObservatoryUriForLaunch(
            'srv-bar',
            device,
            deviceVmservicePort: 321,
          ),
          throwsToolExit(
              message:'Did not find an observatory advertised for srv-bar on port 321.'),
        );
      });
    });

    testWithoutContext('Find firstMatchingObservatory with many available and no application id', () async {
      final MDnsClient client = FakeMDnsClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'srv-foo'),
          PtrResourceRecord('bar', year3000, domainName: 'srv-bar'),
          PtrResourceRecord('baz', year3000, domainName: 'srv-boo'),
        ],
        <String, List<SrvResourceRecord>>{
          'srv-foo': <SrvResourceRecord>[
            SrvResourceRecord('srv-foo', year3000, port: 123, weight: 1, priority: 1, target: 'target-foo'),
          ],
          'srv-bar': <SrvResourceRecord>[
            SrvResourceRecord('srv-bar', year3000, port: 123, weight: 1, priority: 1, target: 'target-bar'),
          ],
          'srv-baz': <SrvResourceRecord>[
            SrvResourceRecord('srv-baz', year3000, port: 123, weight: 1, priority: 1, target: 'target-baz'),
          ],
        },
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
        mdnsClient: client,
        logger: BufferLogger.test(),
        flutterUsage: TestUsage(),
      );
      final MDnsObservatoryDiscoveryResult? result = await portDiscovery.firstMatchingObservatory(client);
      expect(result?.domainName, 'srv-foo');
    });

    testWithoutContext('Find firstMatchingObservatory app id', () async {
      final MDnsClient client = FakeMDnsClient(
        <PtrResourceRecord>[
          PtrResourceRecord('foo', year3000, domainName: 'srv-foo'),
          PtrResourceRecord('bar', year3000, domainName: 'srv-bar'),
          PtrResourceRecord('baz', year3000, domainName: 'srv-boo'),
        ],
        <String, List<SrvResourceRecord>>{
          'srv-foo': <SrvResourceRecord>[
            SrvResourceRecord('srv-foo', year3000, port: 111, weight: 1, priority: 1, target: 'target-foo'),
          ],
          'srv-bar': <SrvResourceRecord>[
            SrvResourceRecord('srv-bar', year3000, port: 222, weight: 1, priority: 1, target: 'target-bar'),
            SrvResourceRecord('srv-bar', year3000, port: 333, weight: 1, priority: 1, target: 'target-bar-2'),
          ],
          'srv-baz': <SrvResourceRecord>[
            SrvResourceRecord('srv-baz', year3000, port: 444, weight: 1, priority: 1, target: 'target-baz'),
          ],
        },
      );

      final MDnsObservatoryDiscovery portDiscovery = MDnsObservatoryDiscovery(
        mdnsClient: client,
        logger: BufferLogger.test(),
        flutterUsage: TestUsage(),
      );
      final MDnsObservatoryDiscoveryResult? result = await portDiscovery.firstMatchingObservatory(
        client,
        applicationId: 'srv-bar'
      );
      expect(result?.domainName, 'srv-bar');
      expect(result?.port, 222);
    });
  });
}

class FakeMDnsClient extends Fake implements MDnsClient {
  FakeMDnsClient(this.ptrRecords, this.srvResponse, {
    this.txtResponse = const <String, List<TxtResourceRecord>>{},
    this.ipResponse = const <String, List<IPAddressResourceRecord>>{},
    this.osErrorOnStart = false,
  });

  final List<PtrResourceRecord> ptrRecords;
  final Map<String, List<SrvResourceRecord>> srvResponse;
  final Map<String, List<TxtResourceRecord>> txtResponse;
  final Map<String, List<IPAddressResourceRecord>> ipResponse;
  final bool osErrorOnStart;

  @override
  Future<void> start({
    InternetAddress? listenAddress,
    NetworkInterfacesFactory? interfacesFactory,
    int mDnsPort = 5353,
    InternetAddress? mDnsAddress,
  }) async {
    if (osErrorOnStart) {
      throw const OSError('Operation not supported on socket', 102);
    }
  }

  @override
  Stream<T> lookup<T extends ResourceRecord>(
    ResourceRecordQuery query, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    if (T == PtrResourceRecord && query.fullyQualifiedName == MDnsObservatoryDiscovery.dartObservatoryName) {
      return Stream<PtrResourceRecord>.fromIterable(ptrRecords) as Stream<T>;
    }
    if (T == SrvResourceRecord) {
      final String key = query.fullyQualifiedName;
      return Stream<SrvResourceRecord>.fromIterable(srvResponse[key] ?? <SrvResourceRecord>[]) as Stream<T>;
    }
    if (T == TxtResourceRecord) {
      final String key = query.fullyQualifiedName;
      return Stream<TxtResourceRecord>.fromIterable(txtResponse[key] ?? <TxtResourceRecord>[]) as Stream<T>;
    }
    if (T == IPAddressResourceRecord) {
      final String key = query.fullyQualifiedName;
      return Stream<IPAddressResourceRecord>.fromIterable(ipResponse[key] ?? <IPAddressResourceRecord>[]) as Stream<T>;
    }
    throw UnsupportedError('Unsupported query type $T');
  }

  @override
  void stop() {}
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeIOSDevice extends Fake implements IOSDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  DevicePortForwarder get portForwarder => const NoOpDevicePortForwarder();
}

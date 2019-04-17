// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import '../flutter_test_alternative.dart';
import 'gesture_tester.dart';

class TestGestureArenaMember extends GestureArenaMember {
  @override
  void acceptGesture(int key) { }

  @override
  void rejectGesture(int key) { }
}

void main() {
  setUp(ensureGestureBinding);

  // Down/up pair 1: normal tap sequence
  const PointerDownEvent down1 = PointerDownEvent(
    pointer: 1,
    buttons: kPrimaryMouseButton,
    position: Offset(10.0, 10.0),
  );

  const PointerUpEvent up1 = PointerUpEvent(
    pointer: 1,
    buttons: 0,
    position: Offset(11.0, 9.0),
  );

  // Down/up pair 2: normal tap sequence far away from pair 1
  const PointerDownEvent down2 = PointerDownEvent(
    pointer: 2,
    buttons: kPrimaryMouseButton,
    position: Offset(30.0, 30.0),
  );

  const PointerUpEvent up2 = PointerUpEvent(
    pointer: 2,
    buttons: 0,
    position: Offset(31.0, 29.0),
  );

  // Down/move/up sequence 3: intervening motion, more than kTouchSlop. (~21px)
  const PointerDownEvent down3 = PointerDownEvent(
    pointer: 3,
    buttons: kPrimaryMouseButton,
    position: Offset(10.0, 10.0),
  );

  const PointerMoveEvent move3 = PointerMoveEvent(
    pointer: 3,
    buttons: kPrimaryMouseButton,
    position: Offset(25.0, 25.0),
  );

  const PointerUpEvent up3 = PointerUpEvent(
    pointer: 3,
    buttons: 0,
    position: Offset(25.0, 25.0),
  );

  // Down/move/up sequence 4: intervening motion, less than kTouchSlop. (~17px)
  const PointerDownEvent down4 = PointerDownEvent(
    pointer: 4,
    buttons: kPrimaryMouseButton,
    position: Offset(10.0, 10.0),
  );

  const PointerMoveEvent move4 = PointerMoveEvent(
    pointer: 4,
    buttons: kPrimaryMouseButton,
    position: Offset(22.0, 22.0),
  );

  const PointerUpEvent up4 = PointerUpEvent(
    pointer: 4,
    buttons: 0,
    position: Offset(22.0, 22.0),
  );

  testGesture('Should recognize tap', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.route(up1);
    expect(tapRecognized, isTrue);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

  testGesture('No duplicate tap events', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    int tapsRecognized = 0;
    tap.onTap = () {
      tapsRecognized++;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapsRecognized, 0);
    tester.route(down1);
    expect(tapsRecognized, 0);

    tester.route(up1);
    expect(tapsRecognized, 1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapsRecognized, 1);

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapsRecognized, 1);
    tester.route(down1);
    expect(tapsRecognized, 1);

    tester.route(up1);
    expect(tapsRecognized, 2);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapsRecognized, 2);

    tap.dispose();
  });

  testGesture('Should not recognize two overlapping taps', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    int tapsRecognized = 0;
    tap.onTap = () {
      tapsRecognized++;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapsRecognized, 0);
    tester.route(down1);
    expect(tapsRecognized, 0);

    tap.addPointer(down2);
    tester.closeArena(2);
    expect(tapsRecognized, 0);
    tester.route(down1);
    expect(tapsRecognized, 0);


    tester.route(up1);
    expect(tapsRecognized, 1);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapsRecognized, 1);

    tester.route(up2);
    expect(tapsRecognized, 1);
    GestureBinding.instance.gestureArena.sweep(2);
    expect(tapsRecognized, 1);

    tap.dispose();
  });

  testGesture('Distance cancels tap', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };
    bool tapCanceled = false;
    tap.onTapCancel = () {
      tapCanceled = true;
    };

    tap.addPointer(down3);
    tester.closeArena(3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);
    tester.route(down3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);

    tester.route(move3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);
    tester.route(up3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);
    GestureBinding.instance.gestureArena.sweep(3);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isTrue);

    tap.dispose();
  });

  testGesture('Short distance does not cancel tap', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };
    bool tapCanceled = false;
    tap.onTapCancel = () {
      tapCanceled = true;
    };

    tap.addPointer(down4);
    tester.closeArena(4);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);
    tester.route(down4);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);

    tester.route(move4);
    expect(tapRecognized, isFalse);
    expect(tapCanceled, isFalse);
    tester.route(up4);
    expect(tapRecognized, isTrue);
    expect(tapCanceled, isFalse);
    GestureBinding.instance.gestureArena.sweep(4);
    expect(tapRecognized, isTrue);
    expect(tapCanceled, isFalse);

    tap.dispose();
  });

  testGesture('Timeout does not cancel tap', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.async.elapse(const Duration(milliseconds: 500));
    expect(tapRecognized, isFalse);
    tester.route(up1);
    expect(tapRecognized, isTrue);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

  testGesture('Should yield to other arena members', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    final TestGestureArenaMember member = TestGestureArenaMember();
    final GestureArenaEntry entry = GestureBinding.instance.gestureArena.add(1, member);
    GestureBinding.instance.gestureArena.hold(1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.route(up1);
    expect(tapRecognized, isFalse);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isFalse);

    entry.resolve(GestureDisposition.accepted);
    expect(tapRecognized, isFalse);

    tap.dispose();
  });

  testGesture('Should trigger on release of held arena', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    bool tapRecognized = false;
    tap.onTap = () {
      tapRecognized = true;
    };

    tap.addPointer(down1);
    final TestGestureArenaMember member = TestGestureArenaMember();
    final GestureArenaEntry entry = GestureBinding.instance.gestureArena.add(1, member);
    GestureBinding.instance.gestureArena.hold(1);
    tester.closeArena(1);
    expect(tapRecognized, isFalse);
    tester.route(down1);
    expect(tapRecognized, isFalse);

    tester.route(up1);
    expect(tapRecognized, isFalse);
    GestureBinding.instance.gestureArena.sweep(1);
    expect(tapRecognized, isFalse);

    entry.resolve(GestureDisposition.rejected);
    tester.async.flushMicrotasks();
    expect(tapRecognized, isTrue);

    tap.dispose();
  });

  testGesture('Should log exceptions from callbacks', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();

    tap.onTap = () {
      throw Exception(test);
    };

    final FlutterExceptionHandler previousErrorHandler = FlutterError.onError;
    bool gotError = false;
    FlutterError.onError = (FlutterErrorDetails details) {
      gotError = true;
    };

    tap.addPointer(down1);
    tester.closeArena(1);
    tester.route(down1);
    expect(gotError, isFalse);

    tester.route(up1);
    expect(gotError, isTrue);

    FlutterError.onError = previousErrorHandler;
    tap.dispose();
  });

  testGesture('No duplicate tap events', (GestureTester tester) {
    final TapGestureRecognizer tapA = TapGestureRecognizer();
    final TapGestureRecognizer tapB = TapGestureRecognizer();

    final List<String> log = <String>[];
    tapA.onTapDown = (TapDownDetails details) { log.add('tapA onTapDown'); };
    tapA.onTapUp = (TapUpDetails details) { log.add('tapA onTapUp'); };
    tapA.onTap = () { log.add('tapA onTap'); };
    tapA.onTapCancel = () { log.add('tapA onTapCancel'); };
    tapB.onTapDown = (TapDownDetails details) { log.add('tapB onTapDown'); };
    tapB.onTapUp = (TapUpDetails details) { log.add('tapB onTapUp'); };
    tapB.onTap = () { log.add('tapB onTap'); };
    tapB.onTapCancel = () { log.add('tapB onTapCancel'); };

    log.add('start');
    tapA.addPointer(down1);
    log.add('added 1 to A');
    tapB.addPointer(down1);
    log.add('added 1 to B');
    tester.closeArena(1);
    log.add('closed 1');
    tester.route(down1);
    log.add('routed 1 down');
    tester.route(up1);
    log.add('routed 1 up');
    GestureBinding.instance.gestureArena.sweep(1);
    log.add('swept 1');
    tapA.addPointer(down2);
    log.add('down 2 to A');
    tapB.addPointer(down2);
    log.add('down 2 to B');
    tester.closeArena(2);
    log.add('closed 2');
    tester.route(down2);
    log.add('routed 2 down');
    tester.route(up2);
    log.add('routed 2 up');
    GestureBinding.instance.gestureArena.sweep(2);
    log.add('swept 2');
    tapA.dispose();
    log.add('disposed A');
    tapB.dispose();
    log.add('disposed B');

    expect(log, <String>[
      'start',
      'added 1 to A',
      'added 1 to B',
      'closed 1',
      'routed 1 down',
      'routed 1 up',
      'tapA onTapDown',
      'tapA onTapUp',
      'tapA onTap',
      'swept 1',
      'down 2 to A',
      'down 2 to B',
      'closed 2',
      'routed 2 down',
      'routed 2 up',
      'tapA onTapDown',
      'tapA onTapUp',
      'tapA onTap',
      'swept 2',
      'disposed A',
      'disposed B',
    ]);
  });

  testGesture('PointerCancelEvent cancels tap', (GestureTester tester) {
    const PointerDownEvent down = PointerDownEvent(
        pointer: 5,
        buttons: kPrimaryMouseButton,
        position: Offset(10.0, 10.0),
    );
    const PointerCancelEvent cancel = PointerCancelEvent(
        pointer: 5,
        position: Offset(10.0, 10.0),
    );

    final TapGestureRecognizer tap = TapGestureRecognizer();

    final List<String> recognized = <String>[];
    tap.onTapDown = (_) {
      recognized.add('down');
    };
    tap.onTapUp = (_) {
      recognized.add('up');
    };
    tap.onTap = () {
      recognized.add('tap');
    };
    tap.onTapCancel = () {
      recognized.add('cancel');
    };

    tap.addPointer(down);
    tester.closeArena(5);
    tester.async.elapse(const Duration(milliseconds: 5000));
    expect(recognized, <String>['down']);
    tester.route(cancel);
    expect(recognized, <String>['down', 'cancel']);

    tap.dispose();
  });

  testGesture('losing tap gesture recognizer does not send onTapCancel', (GestureTester tester) {
    final TapGestureRecognizer tap = TapGestureRecognizer();
    final HorizontalDragGestureRecognizer drag = HorizontalDragGestureRecognizer();

    final List<String> recognized = <String>[];
    tap.onTapDown = (_) {
      recognized.add('down');
    };
    tap.onTapUp = (_) {
      recognized.add('up');
    };
    tap.onTap = () {
      recognized.add('tap');
    };
    tap.onTapCancel = () {
      recognized.add('cancel');
    };

    tap.addPointer(down3);
    drag.addPointer(down3);
    tester.closeArena(3);
    tester.route(move3);
    GestureBinding.instance.gestureArena.sweep(3);
    expect(recognized, isEmpty);

    tap.dispose();
    drag.dispose();
  });

  group('Enforce consistent-button restriction for onAnyTap:', () {
    // Down/move/up sequence 5: tap sequence with left or right mouse button
    const PointerDownEvent down5l = PointerDownEvent(
      pointer: 5,
      position: Offset(20.0, 20.0),
      buttons: kPrimaryMouseButton,
    );
    const PointerMoveEvent move5lr = PointerMoveEvent(
      pointer: 5,
      position: Offset(20.0, 20.0),
      buttons: kPrimaryMouseButton | kSecondaryMouseButton,
    );
    const PointerMoveEvent move5r = PointerMoveEvent(
      pointer: 5,
      position: Offset(20.0, 20.0),
      buttons: kSecondaryMouseButton,
    );
    const PointerUpEvent up5 = PointerUpEvent(
      pointer: 5,
      position: Offset(20.0, 20.0),
      buttons: 0,
    );

    final List<String> recognized = <String>[];
    TapGestureRecognizer tap;
    setUp(() {
      recognized.clear();
      tap = TapGestureRecognizer()
        ..onAnyTapDown = (TapDownDetails details) {
          recognized.add('down ${details.buttons}');
        }
        ..onAnyTapUp = (TapUpDetails details) {
          recognized.add('up');
        }
        ..onAnyTapCancel = () {
          recognized.add('cancel');
        };
    });

    testGesture('changing buttons before TapDown should terminate gesture without sending cancel', (GestureTester tester) {
      tap.addPointer(down5l);
      tester.closeArena(5);
      expect(recognized, <String>[]);

      tester.route(move5lr);
      expect(recognized, <String>[]);

      tester.route(move5r);
      expect(recognized, <String>[]);

      tester.route(up5);
      expect(recognized, <String>[]);

      tap.dispose();
    });

    testGesture('changing buttons before TapDown should not prevent the next tap', (GestureTester tester) {
      tap.addPointer(down5l);
      tester.closeArena(5);

      tester.route(move5lr);
      tester.route(move5r);
      tester.route(up5);
      expect(recognized, <String>[]);

      tap.addPointer(down1);
      tester.closeArena(1);
      tester.async.elapse(const Duration(milliseconds: 1000));
      tester.route(up1);
      expect(recognized, <String>['down 1', 'up']);

      tap.dispose();
    });

    testGesture('changing buttons after TapDown should terminate gesture and send cancel', (GestureTester tester) {
      tap.addPointer(down5l);
      tester.closeArena(5);
      expect(recognized, <String>[]);
      tester.async.elapse(const Duration(milliseconds: 1000));
      expect(recognized, <String>['down 1']);

      tester.route(move5lr);
      expect(recognized, <String>['down 1', 'cancel']);

      tester.route(move5r);
      expect(recognized, <String>['down 1', 'cancel']);

      tester.route(up5);
      expect(recognized, <String>['down 1', 'cancel']);

      tap.dispose();
    });

    testGesture('changing buttons after TapDown should not prevent the next tap', (GestureTester tester) {
      tap.addPointer(down5l);
      tester.closeArena(5);
      tester.async.elapse(const Duration(milliseconds: 1000));

      tester.route(move5lr);
      tester.route(move5r);
      tester.route(up5);
      GestureBinding.instance.gestureArena.sweep(5);
      expect(recognized, <String>['down 1', 'cancel']);

      tap.addPointer(down1);
      tester.closeArena(1);
      tester.async.elapse(const Duration(milliseconds: 1000));
      tester.route(up1);
      GestureBinding.instance.gestureArena.sweep(1);
      expect(recognized, <String>['down 1', 'cancel', 'down 1', 'up']);

      tap.dispose();
    });
  });

  group('Dispatch to different callbacks per buttons:', () {
    final List<String> recognized = <String>[];
    TapGestureRecognizer tap;
    setUp(() {
      tap = TapGestureRecognizer()
        ..onAnyTapDown = (TapDownDetails details) {
          recognized.add('anyDown ${details.buttons}');
        }
        ..onAnyTapUp = (TapUpDetails details) {
          recognized.add('anyUp');
        }
        ..onAnyTapCancel = () {
          recognized.add('anyCancel');
        }
        ..onTapDown = (TapDownDetails details) {
          recognized.add('primaryDown ${details.buttons}');
        }
        ..onTapUp = (TapUpDetails details) {
          recognized.add('primaryUp');
        }
        ..onTap = () {
          recognized.add('primary');
        }
        ..onTapCancel = () {
          recognized.add('primaryCancel');
        }
        ..onSecondaryTapDown = (TapDownDetails details) {
          recognized.add('secondaryDown ${details.buttons}');
        }
        ..onSecondaryTapUp = (TapUpDetails details) {
          recognized.add('secondaryUp');
        }
        ..onSecondaryTapCancel = () {
          recognized.add('secondaryCancel');
        };
    });

    tearDown(() {
      recognized.clear();
      tap.dispose();
    });

    testGesture('A primary tap should trigger any and primary', (GestureTester tester) {
      const PointerDownEvent down = PointerDownEvent(
        pointer: 1,
        buttons: kPrimaryButton,
        position: Offset(30.0, 30.0),
      );

      const PointerUpEvent up = PointerUpEvent(
        pointer: 1,
        position: Offset(31.0, 29.0),
      );

      tap.addPointer(down);
      tester.closeArena(1);
      expect(recognized, <String>[]);

      tester.async.elapse(const Duration(milliseconds: 500));
      expect(recognized, <String>['anyDown 1', 'primaryDown 1']);
      recognized.clear();

      tester.route(up);
      GestureBinding.instance.gestureArena.sweep(1);
      expect(recognized, <String>['anyUp', 'primaryUp', 'primary']);
    });

    testGesture('A secondary tap should trigger any and secondary', (GestureTester tester) {
      const PointerDownEvent down = PointerDownEvent(
        pointer: 1,
        buttons: kSecondaryButton,
        position: Offset(30.0, 30.0),
      );

      const PointerUpEvent up = PointerUpEvent(
        pointer: 1,
        position: Offset(31.0, 29.0),
      );

      tap.addPointer(down);
      tester.closeArena(1);
      expect(recognized, <String>[]);

      tester.async.elapse(const Duration(milliseconds: 500));
      expect(recognized, <String>['anyDown 2', 'secondaryDown 2']);
      recognized.clear();

      tester.route(up);
      GestureBinding.instance.gestureArena.sweep(1);
      expect(recognized, <String>['anyUp', 'secondaryUp']);
    });

    testGesture('A tap with 0 buttons should trigger nothing', (GestureTester tester) {
      const PointerDownEvent down = PointerDownEvent(
        pointer: 1,
        buttons: 0,
        position: Offset(30.0, 30.0),
      );

      const PointerUpEvent up = PointerUpEvent(
        pointer: 1,
        position: Offset(31.0, 29.0),
      );

      tap.addPointer(down);
      tester.closeArena(1);
      tester.route(up);
      GestureBinding.instance.gestureArena.sweep(1);
      expect(recognized, <String>[]);
    });

    testGesture('A tap with 2 buttons should trigger nothing', (GestureTester tester) {
      const PointerDownEvent down = PointerDownEvent(
        pointer: 1,
        buttons: kPrimaryButton | kSecondaryButton,
        position: Offset(30.0, 30.0),
      );

      const PointerUpEvent up = PointerUpEvent(
        pointer: 1,
        position: Offset(31.0, 29.0),
      );

      tap.addPointer(down);
      tester.closeArena(1);
      tester.route(up);
      GestureBinding.instance.gestureArena.sweep(1);
      expect(recognized, <String>[]);
    });
  });
}

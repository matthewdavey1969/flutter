// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgetsWithLeakTracking('shows title', (WidgetTester tester) async {
    const Widget title = Text('CupertinoListTile');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoListTile(
            title: title,
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.byType(Text)), title);
    expect(find.text('CupertinoListTile'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('shows subtitle', (WidgetTester tester) async {
    const Widget subtitle = Text('CupertinoListTile subtitle');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoListTile(
            title: Icon(CupertinoIcons.add),
            subtitle: subtitle,
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.byType(Text)), subtitle);
    expect(find.text('CupertinoListTile subtitle'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('shows additionalInfo', (WidgetTester tester) async {
    const Widget additionalInfo = Text('Not Connected');

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoListTile(
            title: Icon(CupertinoIcons.add),
            additionalInfo: additionalInfo,
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.byType(Text)), additionalInfo);
    expect(find.text('Not Connected'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('shows trailing', (WidgetTester tester) async {
    const Widget trailing = CupertinoListTileChevron();

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoListTile(
            title: Icon(CupertinoIcons.add),
            trailing: trailing,
          ),
        ),
      ),
    );

    expect(tester.widget<CupertinoListTileChevron>(find.byType(CupertinoListTileChevron)), trailing);
  });

  testWidgetsWithLeakTracking('shows leading', (WidgetTester tester) async {
    const Widget leading = Icon(CupertinoIcons.add);

    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoListTile(
            leading: leading,
            title: Text('CupertinoListTile'),
          ),
        ),
      ),
    );

    expect(tester.widget<Icon>(find.byType(Icon)), leading);
  });

  testWidgetsWithLeakTracking('sets backgroundColor', (WidgetTester tester) async {
    const Color backgroundColor = CupertinoColors.systemRed;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoListSection(
            children: const <Widget>[
              CupertinoListTile(
                title: Text('CupertinoListTile'),
                backgroundColor: backgroundColor,
              ),
            ],
          ),
        ),
      ),
    );

    // Container inside CupertinoListTile is the second one in row.
    final Container container = tester.widgetList<Container>(find.byType(Container)).elementAt(1);
    expect(container.color, backgroundColor);
  });

  testWidgetsWithLeakTracking('does not change backgroundColor when tapped if onTap is not provided', (WidgetTester tester) async {
    const Color backgroundColor = CupertinoColors.systemBlue;
    const Color backgroundColorActivated = CupertinoColors.systemRed;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoListSection(
            children: const <Widget>[
              CupertinoListTile(
                title: Text('CupertinoListTile'),
                backgroundColor: backgroundColor,
                backgroundColorActivated: backgroundColorActivated,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CupertinoListTile));
    await tester.pump();

    // Container inside CupertinoListTile is the second one in row.
    final Container container = tester.widgetList<Container>(find.byType(Container)).elementAt(1);
    expect(container.color, backgroundColor);
  });

  testWidgetsWithLeakTracking('changes backgroundColor when tapped if onTap is provided', (WidgetTester tester) async {
    const Color backgroundColor = CupertinoColors.systemBlue;
    const Color backgroundColorActivated = CupertinoColors.systemRed;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoListSection(
            children: <Widget>[
              CupertinoListTile(
                title: const Text('CupertinoListTile'),
                backgroundColor: backgroundColor,
                backgroundColorActivated: backgroundColorActivated,
                onTap: () async { await Future<void>.delayed(const Duration(milliseconds: 1), () {}); },
              ),
            ],
          ),
        ),
      ),
    );

    // Container inside CupertinoListTile is the second one in row.
    Container container = tester.widgetList<Container>(find.byType(Container)).elementAt(1);
    expect(container.color, backgroundColor);

    // Pump only one frame so the color change persists.
    await tester.tap(find.byType(CupertinoListTile));
    await tester.pump();

    // Container inside CupertinoListTile is the second one in row.
    container = tester.widgetList<Container>(find.byType(Container)).elementAt(1);
    expect(container.color, backgroundColorActivated);

    // Pump the rest of the frames to complete the test.
    await tester.pumpAndSettle();
  });

  testWidgetsWithLeakTracking('does not contain GestureDetector if onTap is not provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoListSection(
            children: const <Widget>[
              CupertinoListTile(
                title: Text('CupertinoListTile'),
              ),
            ],
          ),
        ),
      ),
    );

    // Container inside CupertinoListTile is the second one in row.
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgetsWithLeakTracking('contains GestureDetector if onTap is provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoListSection(
            children: <Widget>[
              CupertinoListTile(
                title: const Text('CupertinoListTile'),
                onTap: () async {},
              ),
            ],
          ),
        ),
      ),
    );

    // Container inside CupertinoListTile is the second one in row.
    expect(find.byType(GestureDetector), findsOneWidget);
  });

  testWidgetsWithLeakTracking('resets the background color when navigated back', (WidgetTester tester) async {
    const Color backgroundColor = CupertinoColors.systemBlue;
    const Color backgroundColorActivated = CupertinoColors.systemRed;

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (BuildContext context) {
             final Widget secondPage = Center(
              child: CupertinoButton(
                child: const Text('Go back'),
                onPressed: () => Navigator.of(context).pop<void>(),
              ),
            );
            return Center(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: MediaQuery(
                  data: const MediaQueryData(),
                  child:CupertinoListTile(
                    title: const Text('CupertinoListTile'),
                    backgroundColor: backgroundColor,
                    backgroundColorActivated: backgroundColorActivated,
                    onTap: () => Navigator.of(context).push(CupertinoPageRoute<Widget>(
                      builder: (BuildContext context) => secondPage,
                    )),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Navigate to second page.
    await tester.tap(find.byType(CupertinoListTile));
    await tester.pumpAndSettle();

    // Go back to first page.
    await tester.tap(find.byType(CupertinoButton));
    await tester.pumpAndSettle();

    // Container inside CupertinoListTile is the second one in row.
    final Container container = tester.widget<Container>(find.byType(Container));
    expect(container.color, backgroundColor);
  });

  group('alignment of widgets for left-to-right', () {
    testWidgetsWithLeakTracking('leading is on the left of title', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile');
      const Widget leading = Icon(CupertinoIcons.add);

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: CupertinoListTile(
                title: title,
                leading: leading,
              ),
            ),
          ),
        ),
      );

      final Offset foundTitle = tester.getTopLeft(find.byType(Text));
      final Offset foundLeading = tester.getTopRight(find.byType(Icon));

      expect(foundTitle.dx > foundLeading.dx, true);
    });

    testWidgetsWithLeakTracking('subtitle is placed below title and aligned on left', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile title');
      const Widget subtitle = Text('CupertinoListTile subtitle');

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: CupertinoListTile(
                title: title,
                subtitle: subtitle,
              ),
            ),
          ),
        ),
      );

      final Offset foundTitle = tester.getBottomLeft(find.text('CupertinoListTile title'));
      final Offset foundSubtitle = tester.getTopLeft(find.text('CupertinoListTile subtitle'));

      expect(foundTitle.dx, equals(foundSubtitle.dx));
      expect(foundTitle.dy < foundSubtitle.dy, isTrue);
    });

    testWidgetsWithLeakTracking('additionalInfo is on the right of title', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile');
      const Widget additionalInfo = Text('Not Connected');

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: CupertinoListTile(
                title: title,
                additionalInfo: additionalInfo,
              ),
            ),
          ),
        ),
      );

      final Offset foundTitle = tester.getTopRight(find.text('CupertinoListTile'));
      final Offset foundInfo = tester.getTopLeft(find.text('Not Connected'));

      expect(foundTitle.dx < foundInfo.dx, isTrue);
    });

    testWidgetsWithLeakTracking('trailing is on the right of additionalInfo', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile');
      const Widget additionalInfo = Text('Not Connected');
      const Widget trailing = CupertinoListTileChevron();

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: CupertinoListTile(
                title: title,
                additionalInfo: additionalInfo,
                trailing: trailing,
              ),
            ),
          ),
        ),
      );

      final Offset foundInfo = tester.getTopRight(find.text('Not Connected'));
      final Offset foundTrailing = tester.getTopLeft(find.byType(CupertinoListTileChevron));

      expect(foundInfo.dx < foundTrailing.dx, isTrue);
    });
  });

  group('alignment of widgets for right-to-left', () {
    testWidgetsWithLeakTracking('leading is on the right of title', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile');
      const Widget leading = Icon(CupertinoIcons.add);

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoListTile(
                title: title,
                leading: leading,
              ),
            ),
          ),
        ),
      );

      final Offset foundTitle = tester.getTopRight(find.byType(Text));
      final Offset foundLeading = tester.getTopLeft(find.byType(Icon));

      expect(foundTitle.dx < foundLeading.dx, true);
    });

    testWidgetsWithLeakTracking('subtitle is placed below title and aligned on right', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile title');
      const Widget subtitle = Text('CupertinoListTile subtitle');

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoListTile(
                title: title,
                subtitle: subtitle,
              ),
            ),
          ),
        ),
      );

      final Offset foundTitle = tester.getBottomRight(find.text('CupertinoListTile title'));
      final Offset foundSubtitle = tester.getTopRight(find.text('CupertinoListTile subtitle'));

      expect(foundTitle.dx, equals(foundSubtitle.dx));
      expect(foundTitle.dy < foundSubtitle.dy, isTrue);
    });

    testWidgetsWithLeakTracking('additionalInfo is on the left of title', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile');
      const Widget additionalInfo = Text('Not Connected');

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoListTile(
                title: title,
                additionalInfo: additionalInfo,
              ),
            ),
          ),
        ),
      );

      final Offset foundTitle = tester.getTopLeft(find.text('CupertinoListTile'));
      final Offset foundInfo = tester.getTopRight(find.text('Not Connected'));

      expect(foundTitle.dx > foundInfo.dx, isTrue);
    });

    testWidgetsWithLeakTracking('trailing is on the left of additionalInfo', (WidgetTester tester) async {
      const Widget title = Text('CupertinoListTile');
      const Widget additionalInfo = Text('Not Connected');
      const Widget trailing = CupertinoListTileChevron();

      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CupertinoListTile(
                title: title,
                additionalInfo: additionalInfo,
                trailing: trailing,
              ),
            ),
          ),
        ),
      );

      final Offset foundInfo = tester.getTopLeft(find.text('Not Connected'));
      final Offset foundTrailing = tester.getTopRight(find.byType(CupertinoListTileChevron));

      expect(foundInfo.dx > foundTrailing.dx, isTrue);
    });
  });

  testWidgetsWithLeakTracking('onTap with delay does not throw an exception', (WidgetTester tester) async {
    const Widget title = Text('CupertinoListTile');
    bool showTile = true;

    Future<void> onTap() async {
      showTile = false;
      await Future<void>.delayed(
        const Duration(seconds: 1),
        () => showTile = true,
      );
    }

    Widget buildCupertinoListTile() {
      return CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (showTile)
                  CupertinoListTile(
                    onTap: onTap,
                    title: title,
                  ),
               ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildCupertinoListTile());
    expect(showTile, isTrue);
    await tester.tap(find.byType(CupertinoListTile));
    expect(showTile, isFalse);
    await tester.pumpWidget(buildCupertinoListTile());
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(tester.takeException(), null);
  });

  testWidgetsWithLeakTracking('title does not overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoListTile(
            title: Text('CupertinoListTile' * 10),
          ),
        ),
      ),
    );

    expect(tester.takeException(), null);
  });

  testWidgetsWithLeakTracking('subtitle does not overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoListTile(
            title: const Text(''),
            subtitle: Text('CupertinoListTile' * 10),
          ),
        ),
      ),
    );

    expect(tester.takeException(), null);
  });
}

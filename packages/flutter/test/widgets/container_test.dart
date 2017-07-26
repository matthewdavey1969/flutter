// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Container control test', (WidgetTester tester) async {
    final Container container = new Container(
      alignment: FractionalOffset.bottomRight,
      padding: const EdgeInsets.all(7.0),
      // uses color, not decoration:
      color: const Color(0xFF00FF00),
      foregroundDecoration: const BoxDecoration(color: const Color(0x7F0000FF)),
      width: 53.0,
      height: 76.0,
      constraints: const BoxConstraints(
        minWidth: 50.0,
        maxWidth: 55.0,
        minHeight: 78.0,
        maxHeight: 82.0,
      ),
      margin: const EdgeInsets.all(5.0),
      child: const SizedBox(
        width: 25.0,
        height: 33.0,
        child: const DecoratedBox(
          // uses decoration, not color:
          decoration: const BoxDecoration(color: const Color(0xFFFFFF00)),
        ),
      ),
    );

    expect(container, hasOneLineDescription);

    await tester.pumpWidget(new Align(
      alignment: FractionalOffset.topLeft,
      child: container
    ));

    final RenderBox box = tester.renderObject(find.byType(Container));
    expect(box, isNotNull);

    expect(box, paints
      ..rect(rect: new Rect.fromLTWH(5.0, 5.0, 53.0, 78.0), color: const Color(0xFF00FF00))
      ..rect(rect: new Rect.fromLTWH(26.0, 43.0, 25.0, 33.0), color: const Color(0xFFFFFF00))
      ..rect(rect: new Rect.fromLTWH(5.0, 5.0, 53.0, 78.0), color: const Color(0x7F0000FF))
    );

    expect(box, hasAGoodToStringDeep);
    expect(
      box.toStringDeep(),
      equalsIgnoringHashCodes(
        'RenderPadding#00000 relayoutBoundary=up1\n'
        ' │ creator: Padding ← Container ← Align ← [root]\n'
        ' │ parentData: offset=Offset(0.0, 0.0) (can use size)\n'
        ' │ constraints: BoxConstraints(0.0<=w<=800.0, 0.0<=h<=600.0)\n'
        ' │ size: Size(63.0, 88.0)\n'
        ' │ padding: EdgeInsets(5.0, 5.0, 5.0, 5.0)\n'
        ' │\n'
        ' └─child: RenderConstrainedBox#00000 relayoutBoundary=up2\n'
        '   │ creator: ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '   │ parentData: offset=Offset(5.0, 5.0) (can use size)\n'
        '   │ constraints: BoxConstraints(0.0<=w<=790.0, 0.0<=h<=590.0)\n'
        '   │ size: Size(53.0, 78.0)\n'
        '   │ additionalConstraints: BoxConstraints(w=53.0, h=78.0)\n'
        '   │\n'
        '   └─child: RenderDecoratedBox#00000\n'
        '     │ creator: DecoratedBox ← ConstrainedBox ← Padding ← Container ←\n'
        '     │   Align ← [root]\n'
        '     │ parentData: <none> (can use size)\n'
        '     │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '     │ size: Size(53.0, 78.0)\n'
        '     │ decoration: BoxDecoration:\n'
        '     │   color: Color(0x7f0000ff)\n'
        '     │ configuration: ImageConfiguration(bundle:\n'
        '     │   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '     │   android)\n'
        '     │\n'
        '     └─child: RenderDecoratedBox#00000\n'
        '       │ creator: DecoratedBox ← DecoratedBox ← ConstrainedBox ← Padding ←\n'
        '       │   Container ← Align ← [root]\n'
        '       │ parentData: <none> (can use size)\n'
        '       │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '       │ size: Size(53.0, 78.0)\n'
        '       │ decoration: BoxDecoration:\n'
        '       │   color: Color(0xff00ff00)\n'
        '       │ configuration: ImageConfiguration(bundle:\n'
        '       │   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '       │   android)\n'
        '       │\n'
        '       └─child: RenderPadding#00000\n'
        '         │ creator: Padding ← DecoratedBox ← DecoratedBox ← ConstrainedBox ←\n'
        '         │   Padding ← Container ← Align ← [root]\n'
        '         │ parentData: <none> (can use size)\n'
        '         │ constraints: BoxConstraints(w=53.0, h=78.0)\n'
        '         │ size: Size(53.0, 78.0)\n'
        '         │ padding: EdgeInsets(7.0, 7.0, 7.0, 7.0)\n'
        '         │\n'
        '         └─child: RenderPositionedBox#00000\n'
        '           │ creator: Align ← Padding ← DecoratedBox ← DecoratedBox ←\n'
        '           │   ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '           │ parentData: offset=Offset(7.0, 7.0) (can use size)\n'
        '           │ constraints: BoxConstraints(w=39.0, h=64.0)\n'
        '           │ size: Size(39.0, 64.0)\n'
        '           │ alignment: FractionalOffset(1.0, 1.0)\n'
        '           │ widthFactor: expand\n'
        '           │ heightFactor: expand\n'
        '           │\n'
        '           └─child: RenderConstrainedBox#00000 relayoutBoundary=up1\n'
        '             │ creator: SizedBox ← Align ← Padding ← DecoratedBox ← DecoratedBox\n'
        '             │   ← ConstrainedBox ← Padding ← Container ← Align ← [root]\n'
        '             │ parentData: offset=Offset(14.0, 31.0) (can use size)\n'
        '             │ constraints: BoxConstraints(0.0<=w<=39.0, 0.0<=h<=64.0)\n'
        '             │ size: Size(25.0, 33.0)\n'
        '             │ additionalConstraints: BoxConstraints(w=25.0, h=33.0)\n'
        '             │\n'
        '             └─child: RenderDecoratedBox#00000\n'
        '                 creator: DecoratedBox ← SizedBox ← Align ← Padding ← DecoratedBox\n'
        '                   ← DecoratedBox ← ConstrainedBox ← Padding ← Container ← Align ←\n'
        '                   [root]\n'
        '                 parentData: <none> (can use size)\n'
        '                 constraints: BoxConstraints(w=25.0, h=33.0)\n'
        '                 size: Size(25.0, 33.0)\n'
        '                 decoration: BoxDecoration:\n'
        '                   color: Color(0xffffff00)\n'
        '                 configuration: ImageConfiguration(bundle:\n'
        '                   PlatformAssetBundle#00000(), devicePixelRatio: 1.0, platform:\n'
        '                   android)\n',
      ),
    );
  });

  testWidgets('Can be placed in an infinite box', (WidgetTester tester) async {
    await tester.pumpWidget(new ListView(children: <Widget>[new Container()]));
  });
}

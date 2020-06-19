// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Texture with default FilterQuality', (WidgetTester tester) async {
    await tester.pumpWidget(
        const Center(child: Texture(textureId: 1,))
    );

    Texture texture = tester.firstWidget(find.byType(Texture));
    expect(texture, isNotNull);
    expect(texture.textureId, 1);
    expect(texture.filterQuality, FilterQuality.low);

    final RenderObject renderObject = tester.firstRenderObject(find.byType(Texture));
    expect(renderObject, isNotNull);
    final TextureBox textureBox = renderObject as TextureBox;
    expect(textureBox, isNotNull);
    expect(textureBox.textureId, 1);
    expect(textureBox.filterQuality, FilterQuality.low);

    final ContainerLayer containerLayer = ContainerLayer();
    final PaintingContext paintingContext = PaintingContext(containerLayer, Rect.zero);
    textureBox.paint(paintingContext, Offset.zero);
    final Layer layer = containerLayer.lastChild;
    expect(layer, isNotNull);
    final TextureLayer textureLayer = layer as TextureLayer;
    expect(textureLayer, isNotNull);
    expect(textureLayer.textureId, 1);
    expect(textureLayer.filterQuality, FilterQuality.low);
  });


  testWidgets('Texture with FilterQuality.none', (WidgetTester tester) async {
    await tester.pumpWidget(
        const Center(child: Texture(textureId: 1, filterQuality: FilterQuality.none))
    );

    final Texture texture = tester.firstWidget(find.byType(Texture));
    expect(texture, isNotNull);
    expect(texture.textureId, 1);
    expect(texture.filterQuality, FilterQuality.none);

    final RenderObject renderObject = tester.firstRenderObject(find.byType(Texture));
    expect(renderObject, isNotNull);
    final TextureBox textureBox = renderObject as TextureBox;
    expect(textureBox, isNotNull);
    expect(textureBox.textureId, 1);
    expect(textureBox.filterQuality, FilterQuality.none);

    final ContainerLayer containerLayer = ContainerLayer();
    final PaintingContext paintingContext = PaintingContext(containerLayer, Rect.zero);
    textureBox.paint(paintingContext, Offset.zero);
    final Layer layer = containerLayer.lastChild;
    expect(layer, isNotNull);
    final TextureLayer textureLayer = layer as TextureLayer;
    expect(textureLayer, isNotNull);
    expect(textureLayer.textureId, 1);
    expect(textureLayer.filterQuality, FilterQuality.none);
  });

  testWidgets('Texture with FilterQuality.low', (WidgetTester tester) async {
    await tester.pumpWidget(
        const Center(child: Texture(textureId: 1, filterQuality: FilterQuality.low))
    );

    final Texture texture = tester.firstWidget(find.byType(Texture));
    expect(texture, isNotNull);
    expect(texture.textureId, 1);
    expect(texture.filterQuality, FilterQuality.low);

    final RenderObject renderObject = tester.firstRenderObject(find.byType(Texture));
    expect(renderObject, isNotNull);
    final TextureBox textureBox = renderObject as TextureBox;
    expect(textureBox, isNotNull);
    expect(textureBox.textureId, 1);
    expect(textureBox.filterQuality, FilterQuality.low);

    final ContainerLayer containerLayer = ContainerLayer();
    final PaintingContext paintingContext = PaintingContext(containerLayer, Rect.zero);
    textureBox.paint(paintingContext, Offset.zero);
    final Layer layer = containerLayer.lastChild;
    expect(layer, isNotNull);
    final TextureLayer textureLayer = layer as TextureLayer;
    expect(textureLayer, isNotNull);
    expect(textureLayer.textureId, 1);
    expect(textureLayer.filterQuality, FilterQuality.low);
  });
}

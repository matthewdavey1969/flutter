// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to use the ui.Canvas interface to draw various shapes
// with gradients and transforms.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

ui.Picture paint(ui.Rect paintBounds) {
  // First we create a PictureRecorder to record the commands we're going to
  // feed in the canvas. The PictureRecorder will eventually produce a Picture,
  // which is an immutable record of those commands.
  final ui.PictureRecorder recorder = ui.PictureRecorder();

  // Next, we create a canvas from the recorder. The canvas is an interface
  // which can receive drawing commands. The canvas interface is modeled after
  // the SkCanvas interface from Skia. The paintBounds establishes a "cull rect"
  // for the canvas, which lets the implementation discard any commands that
  // are entirely outside this rectangle.
  final ui.Canvas canvas = ui.Canvas(recorder, paintBounds);

  final ui.Paint paint = ui.Paint();
  canvas.drawPaint(ui.Paint()..color = const ui.Color(0xFFFFFFFF));

  final ui.Size size = paintBounds.size;
  final ui.Offset mid = size.center(ui.Offset.zero);
  final double radius = size.shortestSide / 2.0;

  final double devicePixelRatio = ui.window.devicePixelRatio;
  final ui.Size logicalSize = ui.window.physicalSize / devicePixelRatio;

  // Saves a copy of current transform onto the save stack
  canvas.save();

  // Note that transforms that occur after this point apply only to the
  // yellow-bluish rectangle

  // Clips the current transform
  canvas.clipRect(
    ui.Rect.fromLTRB(0, radius + 50, logicalSize.width, logicalSize.height),
    clipOp: ui.ClipOp.difference
  );

  // Shifts the coordinate space of and rotates the current transform
  canvas.translate(mid.dx, mid.dy);
  canvas.rotate(math.pi/4);

  final ui.Gradient yellowBlue = ui.Gradient.linear(
    ui.Offset(-radius, -radius),
    const ui.Offset(0.0, 0.0),
    <ui.Color>[const ui.Color(0xFFFFFF00), const ui.Color(0xFF0000FF)],
  );

  // Draws a yellow-bluish rectangle
  canvas.drawRect(
    ui.Rect.fromLTRB(-radius, -radius, radius, radius),
    ui.Paint()..shader = yellowBlue,
  );

  // Note that transforms that occur after this point apply only to the
  // yellow circle

  // Scale x and y by 0.5.
  final Float64List scaleMatrix = Float64List.fromList(<double>[
      0.5, 0.0, 0.0, 0.0,
      0.0, 0.5, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0,
  ]);
  canvas.transform(scaleMatrix);

  // Sets paint to half-transparent yellow
  paint.color = const ui.Color.fromARGB(128, 0, 255, 0);

  // Draws a yellow circle
  canvas.drawCircle(ui.Offset.zero, radius, paint);

  // Restores the transform from before `save` was called
  canvas.restore();

  // Sets paint to half-transparent red
  paint.color = const ui.Color.fromARGB(128, 255, 0, 0);

  // Note that this circle is drawn on top of the previous layer
  canvas.drawCircle(const ui.Offset(150.0, 300.0), radius, paint);

  // When we're done issuing painting commands, we end the recording an receive
  // a Picture, which is an immutable record of the commands we've issued. You
  // can draw a Picture into another canvas or include it as part of a
  // composited scene.
  return recorder.endRecording();
}

ui.Scene composite(ui.Picture picture, ui.Rect paintBounds) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  final Float64List deviceTransform = Float64List(16)
    ..[0] = devicePixelRatio
    ..[5] = devicePixelRatio
    ..[10] = 1.0
    ..[15] = 1.0;
  final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
    ..pushTransform(deviceTransform)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();
  return sceneBuilder.build();
}

void beginFrame(Duration timeStamp) {
  final ui.Rect paintBounds = ui.Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio);
  final ui.Picture picture = paint(paintBounds);
  final ui.Scene scene = composite(picture, paintBounds);
  ui.window.render(scene);
}

void main() {
  ui.window.onBeginFrame = beginFrame;
  ui.window.scheduleFrame();
}

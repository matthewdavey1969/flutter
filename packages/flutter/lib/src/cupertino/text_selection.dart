// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'button.dart';
import 'colors.dart';
import 'localizations.dart';


const Color _kHandlesColor = Color(0xFF136FE0);
const double _kSelectionHandleOverlap = 1.5;
// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const double _kSelectionHandleRadius = 5.5;

// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;
// Minimal padding from tip of the selection toolbar arrow to horizontal edges of the
// screen. Eyeballed value.
const double _kArrowScreenPadding = 16.0;

// Vertical distance between the tip of the arrow and the line of text the arrow
// is pointing to. The value used here is eyeballed.
const double _kToolbarContentDistance = 8.0;
// Values derived from https://developer.apple.com/design/resources/.
// 92% Opacity ~= 0xEB

// The height of the toolbar, including the arrow.
const double _kToolbarHeight = 43.0;
const Color _kToolbarBackgroundColor = Color(0xEB202020);
const Color _kToolbarDividerColor = Color(0xFF808080);
const Size _kToolbarArrowSize = Size(14.0, 7.0);
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);
const Radius _kToolbarBorderRadius = Radius.circular(8);

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.white,
);

class _Toolbar extends SingleChildRenderObjectWidget {
  const _Toolbar({
    Key key,
    this.barTopY,
    this.arrowTipX,
    this.isArrowPointingDown,
    Widget child,
  }) : super(key: key, child: child);

  /// The y-coordinate of toolbar's top edge, in global coordinate system.
  final double barTopY;

  /// The y-coordinate of the tip of the arrow, in global coordinate system.
  final double arrowTipX;

  /// Whether the arrow should point down and be attached to the bottom
  /// of the toolbar, or point up and be attached to the top of the toolbar.
  final bool isArrowPointingDown;

  @override
  _ToolbarRenderBox createRenderObject(BuildContext context) => _ToolbarRenderBox(barTopY, arrowTipX, isArrowPointingDown, null);

  @override
  void updateRenderObject(BuildContext context, _ToolbarRenderBox renderObject) {
    renderObject
      ..barTopY = barTopY
      ..arrowTipX = arrowTipX
      ..isArrowPointingDown = isArrowPointingDown;
  }
}

class _ToolbarParentData extends BoxParentData {
  // The x offset from the center of the toolbar to the tip of the arrow.
  double arrowXOffsetFromCenter;
  @override
  String toString() => 'offset=$offset, arrowXOffsetFromCenter=$arrowXOffsetFromCenter';
}

class _ToolbarRenderBox extends RenderShiftedBox {
  _ToolbarRenderBox(
      this._barTopY,
      this._arrowTipX,
      this._isArrowPointingDown,
      RenderBox child,
  ) : super(child);

  double _barTopY;
  set barTopY(double value) {
    if (_barTopY == value) {
      return;
    }
    _barTopY = value;
    markNeedsLayout();
  }

  double _arrowTipX;
  set arrowTipX(double value) {
    if (_arrowTipX == value) {
      return;
    }
    _arrowTipX = value;
    markNeedsLayout();
  }

  bool _isArrowPointingDown;
  set isArrowPointingDown(bool value) {
    if (_isArrowPointingDown == value) {
      return;
    }
    _isArrowPointingDown = value;
    markNeedsLayout();
  }

  final BoxConstraints heightConstraint = const BoxConstraints.tightFor(height: _kToolbarHeight);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  void performLayout() {
    assert(child != null);
    size = constraints.biggest;
    child.layout(heightConstraint.enforce(constraints.loosen()), parentUsesSize: true);
    final _ToolbarParentData childParentData = child.parentData;
    final Offset localBarTopCenter = globalToLocal(Offset(_arrowTipX, _barTopY));

    // The local x-coordinate of the center of the toolbar.
    final double adjustedCenterX = localBarTopCenter.dx
      .clamp(
        child.size.width/2 + _kToolbarScreenPadding,
        size.width - child.size.width/2 - _kToolbarScreenPadding,
      );

    childParentData.offset = Offset(adjustedCenterX - child.size.width / 2, localBarTopCenter.dy);
    childParentData.arrowXOffsetFromCenter = localBarTopCenter.dx - adjustedCenterX;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final _ToolbarParentData childParentData = child.parentData;

    final Path rrect = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset(0, _isArrowPointingDown ? 0 : _kToolbarArrowSize.height,)
          & Size(child.size.width, child.size.height - _kToolbarArrowSize.height),
          _kToolbarBorderRadius,
        ),
      );

    final double arrowTipX = child.size.width / 2 + childParentData.arrowXOffsetFromCenter;

    final double arrowBottomY = _isArrowPointingDown
      ? child.size.height - _kToolbarArrowSize.height
      : _kToolbarArrowSize.height;

    final double arrowTipY = _isArrowPointingDown ? child.size.height : 0;

    final Path arrow = Path()
      ..moveTo(arrowTipX, arrowTipY)
      ..lineTo(arrowTipX - _kToolbarArrowSize.width / 2, arrowBottomY)
      ..lineTo(arrowTipX + _kToolbarArrowSize.width / 2, arrowBottomY)
      ..close();

    context.pushClipPath(
      needsCompositing,
      offset + childParentData.offset,
      Offset.zero & child.size,
      Path.combine(PathOperation.union, rrect, arrow),
      (PaintingContext innerContext, Offset innerOffset) => context.paintChild(child, innerOffset),
    );
  }
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatelessWidget {
  const _TextSelectionToolbar({
    Key key,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.isArrowPointingDown,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;
  final bool isArrowPointingDown;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    final Widget onePhysicalPixelVerticalDivider =
    SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);

    if (handleCut != null)
      items.add(_buildToolbarButton(localizations.cutButtonLabel, handleCut));

    if (handleCopy != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton(localizations.copyButtonLabel, handleCopy));
    }

    if (handlePaste != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton(localizations.pasteButtonLabel, handlePaste));
    }

    if (handleSelectAll != null) {
      if (items.isNotEmpty)
        items.add(onePhysicalPixelVerticalDivider);
      items.add(_buildToolbarButton(localizations.selectAllButtonLabel, handleSelectAll));
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: _kToolbarDividerColor),
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }

  /// Builds a themed [CupertinoButton] for the toolbar.
  CupertinoButton _buildToolbarButton(String text, VoidCallback onPressed) {
    final EdgeInsets arrowPadding = isArrowPointingDown
      ? EdgeInsets.only(bottom: _kToolbarArrowSize.height)
      : EdgeInsets.only(top: _kToolbarArrowSize.height);

    return CupertinoButton(
      child: Text(text, style: _kToolbarButtonFontStyle),
      color: _kToolbarBackgroundColor,
      minSize: _kToolbarHeight + _kToolbarArrowSize.height,
      padding: _kToolbarButtonPadding.add(arrowPadding),
      borderRadius: null,
      pressedOpacity: 0.7,
      onPressed: onPressed,
    );
  }
}


/// Draws a single text selection handle with a bar and a ball.
class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
        ..color = _kHandlesColor
        ..strokeWidth = 2.0;
    canvas.drawCircle(
      const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      _kSelectionHandleRadius,
      paint,
    );
    // Draw line so it slightly overlaps the circle.
    canvas.drawLine(
      const Offset(
        _kSelectionHandleRadius,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(
        _kSelectionHandleRadius,
        size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) => false;
}

class _CupertinoTextSelectionControls extends TextSelectionControls {
  /// Returns the size of the Cupertino handle.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  /// Builder for iOS-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // The toolbar should appear below the TextField when there is not enough
    // space above the TextField to show it. Assuming there's always enough space
    // at the bottom when this happens.
    final bool isArrowPointingDown =
      mediaQuery.padding.top
      + _kToolbarScreenPadding
      + _kToolbarHeight
      + _kToolbarContentDistance <= globalEditableRegion.top;

    // We cannot trust postion.dy, since the caller (TextSelectionOverlay._buildToolbar)
    // does not know whether the toolbar is going to be facing up or down.
    final double localArrowTipX = position.dx.clamp(_kArrowScreenPadding, mediaQuery.size.width - _kArrowScreenPadding);

    // The height of the toolbar is fixed hence we can decide its vertical
    // position.
    final double localBarTopY = isArrowPointingDown
      ? endpoints.first.point.dy - textLineHeight - _kToolbarContentDistance - _kToolbarHeight
      : endpoints.last.point.dy + _kToolbarContentDistance;

    final Widget toolbarContent = _TextSelectionToolbar(
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      isArrowPointingDown: isArrowPointingDown,
    );

    return ConstrainedBox(
      constraints: BoxConstraints.tight(mediaQuery.size),
      child: _Toolbar(
        barTopY: localBarTopY + globalEditableRegion.top,
        arrowTipX: localArrowTipX + globalEditableRegion.left,
        isArrowPointingDown: isArrowPointingDown,
        child: toolbarContent,
      ),
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = getHandleSize(textLineHeight);

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: const CustomPaint(
        painter: _TextSelectionHandlePainter(),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left:
        return handle;
      case TextSelectionHandleType.right:
        // Right handle is a vertical mirror of the left.
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(math.pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );
      // iOS doesn't draw anything for collapsed selections.
      case TextSelectionHandleType.collapsed:
        return Container();
    }
    assert(type != null);
    return null;
  }

  /// Gets anchor for cupertino-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    final Size handleSize = getHandleSize(textLineHeight);
    switch (type) {
      // The circle is at the top for the left handle, and the anchor point is
      // all the way at the bottom of the line.
      case TextSelectionHandleType.left:
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );
      // The right handle is vertically flipped, and the anchor point is near
      // the top of the circle to give slight overlap.
      case TextSelectionHandleType.right:
        return Offset(
          handleSize.width / 2,
          handleSize.height - 2 * _kSelectionHandleRadius + _kSelectionHandleOverlap,
        );
      // A collapsed handle anchors itself so that it's centered.
      default:
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}

/// Text selection controls that follows iOS design conventions.
final TextSelectionControls cupertinoTextSelectionControls = _CupertinoTextSelectionControls();

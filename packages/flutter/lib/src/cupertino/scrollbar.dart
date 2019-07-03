// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// All values eyeballed.
const Color _kScrollbarColor = Color(0x99777777);
const double _kScrollbarMinLength = 36.0;
const double _kScrollbarMinOverscrollLength = 8.0;
const Radius _kScrollbarRadius = Radius.circular(1.5);
const Radius _kScrollbarRadiusDragging = Radius.circular(4.0);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);
const Duration _kScrollbarResizeDuration = Duration(milliseconds: 150);

// These values are measured using screenshots from an iPhone XR 13.0 simulator.
const double _kScrollbarThickness = 2.5;
const double _kScrollbarThicknessDragging = 8.0;
// This is the amount of space from the top of a vertical scrollbar to the
// top edge of the scrollable, measured when the vertical scrollbar overscrolls
// to the top.
// TODO(LongCatIsLooong): fix https://github.com/flutter/flutter/issues/32175
const double _kScrollbarMainAxisMargin = 3.0;
const double _kScrollbarCrossAxisMargin = 3.0;

/// An iOS style scrollbar.
///
/// A scrollbar indicates which portion of a [Scrollable] widget is actually
/// visible.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [CupertinoScrollbar] widget.
///
/// See also:
///
///  * [ListView], which display a linear, scrollable list of children.
///  * [GridView], which display a 2 dimensional, scrollable array of children.
///  * [Scrollbar], a Material Design scrollbar that dynamically adapts to the
///    platform showing either an Android style or iOS style scrollbar.
class CupertinoScrollbar extends StatefulWidget {
  /// Creates an iOS style scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const CupertinoScrollbar({
    Key key,
    // TODO(justinmc): When drag-in-from-side is implemented, might have to
    // change the type of this callback.
    GestureLongPressMoveUpdateCallback this.onDragScroll,
    @required this.child,
  }) : super(key: key);

  /// The subtree to place inside the [CupertinoScrollbar].
  ///
  /// This should include a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  final Widget child;

  /// Called when the user scrolls by dragging the scrollbar.
  ///
  /// Starting in iOS13, a long press on the scroll bar or a drag in from the
  /// side enlarges the scrollbar thumb and makes it interactive. Dragging it
  /// then causes the view to scroll.
  ///
  /// See also:
  ///
  ///   * [CupertinoPageScaffold], which uses the callback to implement the
  ///     scrolling.
  final GestureLongPressMoveUpdateCallback onDragScroll;

  @override
  _CupertinoScrollbarState createState() => _CupertinoScrollbarState();
}

class _CupertinoScrollbarState extends State<CupertinoScrollbar> with TickerProviderStateMixin {
  final GlobalKey _customPaintKey = GlobalKey();
  ScrollbarPainter _painter;
  TextDirection _textDirection;

  AnimationController _fadeoutAnimationController;
  Animation<double> _fadeoutOpacityAnimation;
  AnimationController _thicknessAnimationController;
  Animation<double> _thicknessAnimation;
  Timer _fadeoutTimer;
  ScrollMetrics lastMetrics;
  AxisDirection lastAxisDirection;

  double get _thickness {
    return _kScrollbarThickness + _thicknessAnimation.value * (_kScrollbarThicknessDragging - _kScrollbarThickness);
  }

  Radius get _radius {
    return Radius.lerp(_kScrollbarRadius, _kScrollbarRadiusDragging, _thicknessAnimation.value);
  }

  @override
  void initState() {
    super.initState();
    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _thicknessAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarResizeDuration,
    );
    _thicknessAnimation = _thicknessAnimationController.drive(
      Tween<double>(
        begin: 0.0,
        end: 1.0,
      ),
    );
    _thicknessAnimation.addListener(() {
      _painter.updateThickness(_thickness, _radius);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.of(context);
    _painter = _buildCupertinoScrollbarPainter();
  }

  /// Returns a [ScrollbarPainter] visually styled like the iOS scrollbar.
  ScrollbarPainter _buildCupertinoScrollbarPainter() {
    return ScrollbarPainter(
      color: _kScrollbarColor,
      textDirection: _textDirection,
      thickness: _thickness,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      mainAxisMargin: _kScrollbarMainAxisMargin,
      crossAxisMargin: _kScrollbarCrossAxisMargin,
      radius: _radius,
      padding: MediaQuery.of(context).padding,
      minLength: _kScrollbarMinLength,
      minOverscrollLength: _kScrollbarMinOverscrollLength,
    );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _fadeoutTimer?.cancel();
  }

  void _handleLongPressUp() {
    _startFadeoutTimer();
    setState(() {
      _thicknessAnimationController.reverse();
    });
  }

  void _handleLongPress() {
    setState(() {
      _thicknessAnimationController.forward();
    });
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    widget.onDragScroll(details);
  }

  void _startFadeoutTimer() {
    _fadeoutTimer = Timer(_kScrollbarTimeToFade, () {
      _fadeoutAnimationController.reverse();
      _fadeoutTimer = null;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      return false;
    }

    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      // Any movements always makes the scrollbar start showing up.
      if (_fadeoutAnimationController.status != AnimationStatus.forward) {
        _fadeoutAnimationController.forward();
      }

      _fadeoutTimer?.cancel();
      _painter.update(notification.metrics, notification.metrics.axisDirection);
      lastMetrics = notification.metrics;
      lastAxisDirection = notification.metrics.axisDirection;
    } else if (notification is ScrollEndNotification) {
      // On iOS, the scrollbar can only go away once the user lifted the finger.

      _fadeoutTimer?.cancel();
      _startFadeoutTimer();
    }
    return false;
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _fadeoutTimer?.cancel();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures =
      <Type, GestureRecognizerFactory>{};
    gestures[_ThumbLongPressGestureRecognizer] =
      GestureRecognizerFactoryWithHandlers<_ThumbLongPressGestureRecognizer>(
        () => _ThumbLongPressGestureRecognizer(
          debugOwner: this,
          kind: PointerDeviceKind.touch,
          customPaintKey: _customPaintKey,
        ),
        (_ThumbLongPressGestureRecognizer instance) {
          instance
            ..onLongPress = _handleLongPress
            ..onLongPressStart = _handleLongPressStart
            ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
            ..onLongPressUp = _handleLongPressUp;
        },
      );
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: gestures,
          child: CustomPaint(
            key: _customPaintKey,
            foregroundPainter: _painter,
            child: RepaintBoundary(
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// A longpress gesture detector that only responds to events on the scrollbar's
// thumb and ignores everything else.
class _ThumbLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _ThumbLongPressGestureRecognizer({
    double postAcceptSlopTolerance,
    PointerDeviceKind kind,
    Object debugOwner,
    GlobalKey customPaintKey,
  }) :  _customPaintKey = customPaintKey,
        super(
          postAcceptSlopTolerance: postAcceptSlopTolerance,
          kind: kind,
          debugOwner: debugOwner,
        );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    // foregroundPainter also hit tests its children by default, but the
    // scrollbar should only respond to a longpress directly on its thumb, so
    // manually check for a hit on the thumb here.
    if (_customPaintKey.currentContext == null) {
      return false;
    }
    final CustomPaint customPaint = _customPaintKey.currentContext.widget;
    final ScrollbarPainter painter = customPaint.foregroundPainter;
    final RenderBox renderBox = _customPaintKey.currentContext.findRenderObject();
    final Offset localOffset = renderBox.globalToLocal(event.position);
    if (!painter.hitTestInteractive(localOffset)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}

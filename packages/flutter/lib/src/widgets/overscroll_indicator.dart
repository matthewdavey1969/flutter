// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show Timer;
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';
import 'ticker_provider.dart';

/// A visual indication that a scroll view has overscrolled.
///
/// A [GlowingOverscrollIndicator] listens for [ScrollNotification]s in order
/// to control the overscroll indication. These notifications are typically
/// generated by a [ScrollView], such as a [ListView] or a [GridView].
///
/// [GlowingOverscrollIndicator] generates [OverscrollIndicatorNotification]
/// before showing an overscroll indication. To prevent the indicator from
/// showing the indication, call [OverscrollIndicatorNotification.disallowGlow]
/// on the notification.
///
/// Created automatically by [ScrollBehavior.buildViewportChrome] on platforms
/// (e.g., Android) that commonly use this type of overscroll indication.
///
/// In a [MaterialApp], the edge glow color is the [ThemeData.accentColor].
///
/// ## Customizing the Glow Position for Advanced Scroll Views
///
/// When building a [CustomScrollView] with a [GlowingOverscrollIndicator], the
/// indicator will apply to the entire scrollable area, regardless of what
/// slivers the CustomScrollView contains.
///
/// For example, if your CustomScrollView contains a SliverAppBar in the first
/// position, the GlowingOverscrollIndicator will overlay the SliverAppBar. To
/// manipulate the position of the GlowingOverscrollIndicator in this case,
/// you can either make use of a [NotificationListener] and provide a
/// [OverscrollIndicatorNotification.paintOffset] to the
/// notification, or use a [NestedScrollView].
///
/// {@tool dartpad --template=stateless_widget_scaffold}
///
/// This example demonstrates how to use a [NotificationListener] to manipulate
/// the placement of a [GlowingOverscrollIndicator] when building a
/// [CustomScrollView]. Drag the scrollable to see the bounds of the overscroll
/// indicator.
///
/// ```dart
/// Widget build(BuildContext context) {
///   double leadingPaintOffset = MediaQuery.of(context).padding.top + AppBar().preferredSize.height;
///   return NotificationListener<OverscrollIndicatorNotification>(
///     onNotification: (notification) {
///       if (notification.leading) {
///         notification.paintOffset = leadingPaintOffset;
///       }
///       return false;
///     },
///     child: CustomScrollView(
///       slivers: [
///         SliverAppBar(title: Text('Custom PaintOffset')),
///         SliverToBoxAdapter(
///           child: Container(
///             color: Colors.amberAccent,
///             height: 100,
///             child: Center(child: Text('Glow all day!')),
///           ),
///         ),
///         SliverFillRemaining(child: FlutterLogo()),
///       ],
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool dartpad --template=stateless_widget_scaffold}
///
/// This example demonstrates how to use a [NestedScrollView] to manipulate the
/// placement of a [GlowingOverscrollIndicator] when building a
/// [CustomScrollView]. Drag the scrollable to see the bounds of the overscroll
/// indicator.
///
/// ```dart
/// Widget build(BuildContext context) {
///   return NestedScrollView(
///     headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
///       return <Widget>[
///         SliverAppBar(title: Text('Custom NestedScrollViews')),
///       ];
///     },
///     body: CustomScrollView(
///       slivers: <Widget>[
///         SliverToBoxAdapter(
///           child: Container(
///             color: Colors.amberAccent,
///             height: 100,
///             child: Center(child: Text('Glow all day!')),
///           ),
///         ),
///         SliverFillRemaining(child: FlutterLogo()),
///       ],
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [OverscrollIndicatorNotification], which can be used to manipulate the
///    glow position or prevent the glow from being painted at all
///  * [NotificationListener], to listen for the
///    [OverscrollIndicatorNotification]
class GlowingOverscrollIndicator extends StatefulWidget {
  /// Creates a visual indication that a scroll view has overscrolled.
  ///
  /// In order for this widget to display an overscroll indication, the [child]
  /// widget must contain a widget that generates a [ScrollNotification], such
  /// as a [ListView] or a [GridView].
  ///
  /// The [showLeading], [showTrailing], [axisDirection], [color], and
  /// [notificationPredicate] arguments must not be null.
  const GlowingOverscrollIndicator({
    Key? key,
    this.showLeading = true,
    this.showTrailing = true,
    required this.axisDirection,
    required this.color,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.child,
  }) : assert(showLeading != null),
       assert(showTrailing != null),
       assert(axisDirection != null),
       assert(color != null),
       assert(notificationPredicate != null),
       super(key: key);

  /// Whether to show the overscroll glow on the side with negative scroll
  /// offsets.
  ///
  /// For a vertical downwards viewport, this is the top side.
  ///
  /// Defaults to true.
  ///
  /// See [showTrailing] for the corresponding control on the other side of the
  /// viewport.
  final bool showLeading;

  /// Whether to show the overscroll glow on the side with positive scroll
  /// offsets.
  ///
  /// For a vertical downwards viewport, this is the bottom side.
  ///
  /// Defaults to true.
  ///
  /// See [showLeading] for the corresponding control on the other side of the
  /// viewport.
  final bool showTrailing;

  /// The direction of positive scroll offsets in the [Scrollable] whose
  /// overscrolls are to be visualized.
  final AxisDirection axisDirection;

  /// The axis along which scrolling occurs in the [Scrollable] whose
  /// overscrolls are to be visualized.
  Axis get axis => axisDirectionToAxis(axisDirection);

  /// The color of the glow. The alpha channel is ignored.
  final Color color;

  /// A check that specifies whether a [ScrollNotification] should be
  /// handled by this widget.
  ///
  /// By default, checks whether `notification.depth == 0`. Set it to something
  /// else for more complicated layouts.
  final ScrollNotificationPredicate notificationPredicate;

  /// The widget below this widget in the tree.
  ///
  /// The overscroll indicator will paint on top of this child. This child (and its
  /// subtree) should include a source of [ScrollNotification] notifications.
  ///
  /// Typically a [GlowingOverscrollIndicator] is created by a
  /// [ScrollBehavior.buildViewportChrome] method, in which case
  /// the child is usually the one provided as an argument to that method.
  final Widget? child;

  @override
  _GlowingOverscrollIndicatorState createState() => _GlowingOverscrollIndicatorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    String showDescription;
    if (showLeading && showTrailing) {
      showDescription = 'both sides';
    } else if (showLeading) {
      showDescription = 'leading side only';
    } else if (showTrailing) {
      showDescription = 'trailing side only';
    } else {
      showDescription = 'neither side (!)';
    }
    properties.add(MessageProperty('show', showDescription));
    properties.add(ColorProperty('color', color, showName: false));
  }
}

class _GlowingOverscrollIndicatorState extends State<GlowingOverscrollIndicator> with TickerProviderStateMixin {
  _GlowController? _leadingController;
  _GlowController? _trailingController;
  Listenable? _leadingAndTrailingListener;

  @override
  void initState() {
    super.initState();
    _leadingController = _GlowController(vsync: this, color: widget.color, axis: widget.axis);
    _trailingController = _GlowController(vsync: this, color: widget.color, axis: widget.axis);
    _leadingAndTrailingListener = Listenable.merge(<Listenable>[_leadingController!, _trailingController!]);
  }

  @override
  void didUpdateWidget(GlowingOverscrollIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color || oldWidget.axis != widget.axis) {
      _leadingController!.color = widget.color;
      _leadingController!.axis = widget.axis;
      _trailingController!.color = widget.color;
      _trailingController!.axis = widget.axis;
    }
  }

  Type? _lastNotificationType;
  final Map<bool, bool> _accepted = <bool, bool>{false: true, true: true};

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification))
      return false;

    // Update the paint offset with the current scroll position. This makes
    // sure that the glow effect correctly scrolls in line with the current
    // scroll, e.g. when scrolling in the opposite direction again to hide
    // the glow. Otherwise, the glow would always stay in a fixed position,
    // even if the top of the content already scrolled away.
    // For example (CustomScrollView with sliver before center), the scroll
    // extent is [-200.0, 300.0], scroll in the opposite direction with 10.0 pixels
    // before glow disappears, so the current pixels is -190.0,
    // in this case, we should move the glow up 10.0 pixels and should not
    // overflow the scrollable widget's edge. https://github.com/flutter/flutter/issues/64149.
    _leadingController!._paintOffsetScrollPixels =
      -math.min(notification.metrics.pixels - notification.metrics.minScrollExtent!, _leadingController!._paintOffset);
    _trailingController!._paintOffsetScrollPixels =
      -math.min(notification.metrics.maxScrollExtent! - notification.metrics.pixels, _trailingController!._paintOffset);

    if (notification is OverscrollNotification) {
      _GlowController? controller;
      if (notification.overscroll < 0.0) {
        controller = _leadingController;
      } else if (notification.overscroll > 0.0) {
        controller = _trailingController;
      } else {
        assert(false);
      }
      final bool isLeading = controller == _leadingController;
      if (_lastNotificationType != OverscrollNotification) {
        final OverscrollIndicatorNotification confirmationNotification = OverscrollIndicatorNotification(leading: isLeading);
        confirmationNotification.dispatch(context);
        _accepted[isLeading] = confirmationNotification._accepted;
        if (_accepted[isLeading]!) {
          controller!._paintOffset = confirmationNotification.paintOffset;
        }
      }
      assert(controller != null);
      assert(notification.metrics.axis == widget.axis);
      if (_accepted[isLeading]!) {
        if (notification.velocity != 0.0) {
          assert(notification.dragDetails == null);
          controller!.absorbImpact(notification.velocity.abs());
        } else {
          assert(notification.overscroll != 0.0);
          if (notification.dragDetails != null) {
            assert(notification.dragDetails!.globalPosition != null);
            final RenderBox renderer = notification.context!.findRenderObject() as RenderBox;
            assert(renderer != null);
            assert(renderer.hasSize);
            final Size size = renderer.size;
            final Offset position = renderer.globalToLocal(notification.dragDetails!.globalPosition);
            switch (notification.metrics.axis) {
              case Axis.horizontal:
                controller!.pull(notification.overscroll.abs(), size.width, position.dy.clamp(0.0, size.height), size.height);
                break;
              case Axis.vertical:
                controller!.pull(notification.overscroll.abs(), size.height, position.dx.clamp(0.0, size.width), size.width);
                break;
            }
          }
        }
      }
    } else if (notification is ScrollEndNotification || notification is ScrollUpdateNotification) {
      if ((notification as dynamic).dragDetails != null) {
        _leadingController!.scrollEnd();
        _trailingController!.scrollEnd();
      }
    }
    _lastNotificationType = notification.runtimeType;
    return false;
  }

  @override
  void dispose() {
    _leadingController!.dispose();
    _trailingController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RepaintBoundary(
        child: CustomPaint(
          foregroundPainter: _GlowingOverscrollIndicatorPainter(
            leadingController: widget.showLeading ? _leadingController : null,
            trailingController: widget.showTrailing ? _trailingController : null,
            axisDirection: widget.axisDirection,
            repaint: _leadingAndTrailingListener,
          ),
          child: RepaintBoundary(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// The Glow logic is a port of the logic in the following file:
// https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/widget/EdgeEffect.java
// as of December 2016.

enum _GlowState { idle, absorb, pull, recede }

class _GlowController extends ChangeNotifier {
  _GlowController({
    required TickerProvider vsync,
    required Color color,
    required Axis axis,
  }) : assert(vsync != null),
       assert(color != null),
       assert(axis != null),
       _color = color,
       _axis = axis {
    _glowController = AnimationController(vsync: vsync)
      ..addStatusListener(_changePhase);
    final Animation<double> decelerator = CurvedAnimation(
      parent: _glowController,
      curve: Curves.decelerate,
    )..addListener(notifyListeners);
    _glowOpacity = decelerator.drive(_glowOpacityTween);
    _glowSize = decelerator.drive(_glowSizeTween);
    _displacementTicker = vsync.createTicker(_tickDisplacement);
  }

  // animation of the main axis direction
  _GlowState _state = _GlowState.idle;
  late final AnimationController _glowController;
  Timer? _pullRecedeTimer;
  double _paintOffset = 0.0;
  double _paintOffsetScrollPixels = 0.0;

  // animation values
  final Tween<double> _glowOpacityTween = Tween<double>(begin: 0.0, end: 0.0);
  late final Animation<double> _glowOpacity;
  final Tween<double> _glowSizeTween = Tween<double>(begin: 0.0, end: 0.0);
  late final Animation<double> _glowSize;

  // animation of the cross axis position
  late final Ticker _displacementTicker;
  Duration? _displacementTickerLastElapsed;
  double _displacementTarget = 0.5;
  double _displacement = 0.5;

  // tracking the pull distance
  double _pullDistance = 0.0;

  Color get color => _color;
  Color _color;
  set color(Color value) {
    assert(color != null);
    if (color == value)
      return;
    _color = value;
    notifyListeners();
  }

  Axis get axis => _axis;
  Axis _axis;
  set axis(Axis value) {
    assert(axis != null);
    if (axis == value)
      return;
    _axis = value;
    notifyListeners();
  }

  static const Duration _recedeTime = Duration(milliseconds: 600);
  static const Duration _pullTime = Duration(milliseconds: 167);
  static const Duration _pullHoldTime = Duration(milliseconds: 167);
  static const Duration _pullDecayTime = Duration(milliseconds: 2000);
  static final Duration _crossAxisHalfTime = Duration(microseconds: (Duration.microsecondsPerSecond / 60.0).round());

  static const double _maxOpacity = 0.5;
  static const double _pullOpacityGlowFactor = 0.8;
  static const double _velocityGlowFactor = 0.00006;
  static const double _sqrt3 = 1.73205080757; // const math.sqrt(3)
  static const double _widthToHeightFactor = (3.0 / 4.0) * (2.0 - _sqrt3);

  // absorbed velocities are clamped to the range _minVelocity.._maxVelocity
  static const double _minVelocity = 100.0; // logical pixels per second
  static const double _maxVelocity = 10000.0; // logical pixels per second

  @override
  void dispose() {
    _glowController.dispose();
    _displacementTicker.dispose();
    _pullRecedeTimer?.cancel();
    super.dispose();
  }

  /// Handle a scroll slamming into the edge at a particular velocity.
  ///
  /// The velocity must be positive.
  void absorbImpact(double velocity) {
    assert(velocity >= 0.0);
    _pullRecedeTimer?.cancel();
    _pullRecedeTimer = null;
    velocity = velocity.clamp(_minVelocity, _maxVelocity);
    _glowOpacityTween.begin = _state == _GlowState.idle ? 0.3 : _glowOpacity.value;
    _glowOpacityTween.end = (velocity * _velocityGlowFactor).clamp(_glowOpacityTween.begin!, _maxOpacity);
    _glowSizeTween.begin = _glowSize.value;
    _glowSizeTween.end = math.min(0.025 + 7.5e-7 * velocity * velocity, 1.0);
    _glowController.duration = Duration(milliseconds: (0.15 + velocity * 0.02).round());
    _glowController.forward(from: 0.0);
    _displacement = 0.5;
    _state = _GlowState.absorb;
  }

  /// Handle a user-driven overscroll.
  ///
  /// The `overscroll` argument should be the scroll distance in logical pixels,
  /// the `extent` argument should be the total dimension of the viewport in the
  /// main axis in logical pixels, the `crossAxisOffset` argument should be the
  /// distance from the leading (left or top) edge of the cross axis of the
  /// viewport, and the `crossExtent` should be the size of the cross axis. For
  /// example, a pull of 50 pixels up the middle of a 200 pixel high and 100
  /// pixel wide vertical viewport should result in a call of `pull(50.0, 200.0,
  /// 50.0, 100.0)`. The `overscroll` value should be positive regardless of the
  /// direction.
  void pull(double overscroll, double extent, double crossAxisOffset, double crossExtent) {
    _pullRecedeTimer?.cancel();
    _pullDistance += overscroll / 200.0; // This factor is magic. Not clear why we need it to match Android.
    _glowOpacityTween.begin = _glowOpacity.value;
    _glowOpacityTween.end = math.min(_glowOpacity.value + overscroll / extent * _pullOpacityGlowFactor, _maxOpacity);
    final double height = math.min(extent, crossExtent * _widthToHeightFactor);
    _glowSizeTween.begin = _glowSize.value;
    _glowSizeTween.end = math.max(1.0 - 1.0 / (0.7 * math.sqrt(_pullDistance * height)), _glowSize.value);
    _displacementTarget = crossAxisOffset / crossExtent;
    if (_displacementTarget != _displacement) {
      if (!_displacementTicker.isTicking) {
        assert(_displacementTickerLastElapsed == null);
        _displacementTicker.start();
      }
    } else {
      _displacementTicker.stop();
      _displacementTickerLastElapsed = null;
    }
    _glowController.duration = _pullTime;
    if (_state != _GlowState.pull) {
      _glowController.forward(from: 0.0);
      _state = _GlowState.pull;
    } else {
      if (!_glowController.isAnimating) {
        assert(_glowController.value == 1.0);
        notifyListeners();
      }
    }
    _pullRecedeTimer = Timer(_pullHoldTime, () => _recede(_pullDecayTime));
  }

  void scrollEnd() {
    if (_state == _GlowState.pull)
      _recede(_recedeTime);
  }

  void _changePhase(AnimationStatus status) {
    if (status != AnimationStatus.completed)
      return;
    switch (_state) {
      case _GlowState.absorb:
        _recede(_recedeTime);
        break;
      case _GlowState.recede:
        _state = _GlowState.idle;
        _pullDistance = 0.0;
        break;
      case _GlowState.pull:
      case _GlowState.idle:
        break;
    }
  }

  void _recede(Duration duration) {
    if (_state == _GlowState.recede || _state == _GlowState.idle)
      return;
    _pullRecedeTimer?.cancel();
    _pullRecedeTimer = null;
    _glowOpacityTween.begin = _glowOpacity.value;
    _glowOpacityTween.end = 0.0;
    _glowSizeTween.begin = _glowSize.value;
    _glowSizeTween.end = 0.0;
    _glowController.duration = duration;
    _glowController.forward(from: 0.0);
    _state = _GlowState.recede;
  }

  void _tickDisplacement(Duration elapsed) {
    if (_displacementTickerLastElapsed != null) {
      final double t = (elapsed.inMicroseconds - _displacementTickerLastElapsed!.inMicroseconds).toDouble();
      _displacement = _displacementTarget - (_displacementTarget - _displacement) * math.pow(2.0, -t / _crossAxisHalfTime.inMicroseconds);
      notifyListeners();
    }
    if (nearEqual(_displacementTarget, _displacement, Tolerance.defaultTolerance.distance)) {
      _displacementTicker.stop();
      _displacementTickerLastElapsed = null;
    } else {
      _displacementTickerLastElapsed = elapsed;
    }
  }

  void paint(Canvas canvas, Size size) {
    if (_glowOpacity.value == 0.0)
      return;
    final double baseGlowScale = size.width > size.height ? size.height / size.width : 1.0;
    final double radius = size.width * 3.0 / 2.0;
    final double height = math.min(size.height, size.width * _widthToHeightFactor);
    final double scaleY = _glowSize.value * baseGlowScale;
    final Rect rect = Rect.fromLTWH(0.0, 0.0, size.width, height);
    final Offset center = Offset((size.width / 2.0) * (0.5 + _displacement), height - radius);
    final Paint paint = Paint()..color = color.withOpacity(_glowOpacity.value);
    canvas.save();
    canvas.translate(0.0, _paintOffset + _paintOffsetScrollPixels);
    canvas.scale(1.0, scaleY);
    canvas.clipRect(rect);
    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }
}

class _GlowingOverscrollIndicatorPainter extends CustomPainter {
  _GlowingOverscrollIndicatorPainter({
    this.leadingController,
    this.trailingController,
    required this.axisDirection,
    Listenable? repaint,
  }) : super(
    repaint: repaint,
  );

  /// The controller for the overscroll glow on the side with negative scroll offsets.
  ///
  /// For a vertical downwards viewport, this is the top side.
  final _GlowController? leadingController;

  /// The controller for the overscroll glow on the side with positive scroll offsets.
  ///
  /// For a vertical downwards viewport, this is the bottom side.
  final _GlowController? trailingController;

  /// The direction of the viewport.
  final AxisDirection axisDirection;

  static const double piOver2 = math.pi / 2.0;

  void _paintSide(Canvas canvas, Size size, _GlowController? controller, AxisDirection axisDirection, GrowthDirection growthDirection) {
    if (controller == null)
      return;
    switch (applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
      case AxisDirection.up:
        controller.paint(canvas, size);
        break;
      case AxisDirection.down:
        canvas.save();
        canvas.translate(0.0, size.height);
        canvas.scale(1.0, -1.0);
        controller.paint(canvas, size);
        canvas.restore();
        break;
      case AxisDirection.left:
        canvas.save();
        canvas.rotate(piOver2);
        canvas.scale(1.0, -1.0);
        controller.paint(canvas, Size(size.height, size.width));
        canvas.restore();
        break;
      case AxisDirection.right:
        canvas.save();
        canvas.translate(size.width, 0.0);
        canvas.rotate(piOver2);
        controller.paint(canvas, Size(size.height, size.width));
        canvas.restore();
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintSide(canvas, size, leadingController, axisDirection, GrowthDirection.reverse);
    _paintSide(canvas, size, trailingController, axisDirection, GrowthDirection.forward);
  }

  @override
  bool shouldRepaint(_GlowingOverscrollIndicatorPainter oldDelegate) {
    return oldDelegate.leadingController != leadingController
        || oldDelegate.trailingController != trailingController;
  }
}

/// A notification that an [GlowingOverscrollIndicator] will start showing an
/// overscroll indication.
///
/// To prevent the indicator from showing the indication, call [disallowGlow] on
/// the notification.
///
/// See also:
///
///  * [GlowingOverscrollIndicator], which generates this type of notification.
class OverscrollIndicatorNotification extends Notification with ViewportNotificationMixin {
  /// Creates a notification that an [GlowingOverscrollIndicator] will start
  /// showing an overscroll indication.
  ///
  /// The [leading] argument must not be null.
  OverscrollIndicatorNotification({
    required this.leading,
  });

  /// Whether the indication will be shown on the leading edge of the scroll
  /// view.
  final bool leading;

  /// Controls at which offset the glow should be drawn.
  ///
  /// A positive offset will move the glow away from its edge,
  /// i.e. for a vertical, [leading] indicator, a [paintOffset] of 100.0 will
  /// draw the indicator 100.0 pixels from the top of the edge.
  /// For a vertical indicator with [leading] set to `false`, a [paintOffset]
  /// of 100.0 will draw the indicator 100.0 pixels from the bottom instead.
  ///
  /// A negative [paintOffset] is generally not useful, since the glow will be
  /// clipped.
  double paintOffset = 0.0;

  bool _accepted = true;

  /// Call this method if the glow should be prevented.
  void disallowGlow() {
    _accepted = false;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('side: ${leading ? "leading edge" : "trailing edge"}');
  }
}

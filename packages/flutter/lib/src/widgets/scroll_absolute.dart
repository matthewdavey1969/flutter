// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show window;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'overscroll_indicator.dart';
import 'scroll_simulation.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';
import 'scrollable.dart';
import 'viewport.dart';

/// Scrolling logic delegate for lists and other unremarkable scrollable
/// viewports.
///
/// See also:
///
/// * [BouncingAbsoluteScrollPositionMixIn], which is used by this class to
///   implement the scroll behavior for iOS.
/// * [ClampingAbsoluteScrollPositionMixIn] and [GlowingOverscrollIndicator],
///   which are used by this class to implement the scroll behavior for Android.
class ViewportScrollBehavior extends ScrollBehavior2 {
  ViewportScrollBehavior({
    Tolerance scrollTolerances,
  }) : scrollTolerances = scrollTolerances ?? defaultScrollTolerances;

  /// The accuracy to which scrolling is computed.
  ///
  /// Defaults to [defaultScrollTolerances].
  final Tolerance scrollTolerances;

  /// The accuracy to which scrolling is computed by default.
  ///
  /// This is the default value for [scrollTolerances].
  static final Tolerance defaultScrollTolerances = new Tolerance(
    // TODO(ianh): Handle the case of the device pixel ratio changing.
    // TODO(ianh): Get this from the local MediaQuery not dart:ui's window object.
    velocity: 1.0 / (0.050 * ui.window.devicePixelRatio), // logical pixels per second
    distance: 1.0 / ui.window.devicePixelRatio // logical pixels
  );

  /// The platform whose scroll physics should be implemented.
  ///
  /// Defaults to the current platform.
  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  /// The color to use for the glow effect when [platform] indicates a platform
  /// that uses a [GlowingOverscrollIndicator].
  ///
  /// Defaults to white.
  Color getGlowColor(BuildContext context) => const Color(0xFFFFFFFF);

  @override
  Widget wrap(BuildContext context, Widget child, AxisDirection axisDirection) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return new GlowingOverscrollIndicator(
          child: child,
          axisDirection: axisDirection,
          color: getGlowColor(context),
        );
    }
    return null;
  }

  /// The scroll physics to use for the given platform.
  ///
  /// Used by [createScrollPosition] to get the scroll physics for newly created
  /// scroll positions.
  ScrollPhysics getScrollPhysics(TargetPlatform platform) {
    assert(platform != null);
    switch (platform) {
      case TargetPlatform.iOS:
        return const BouncingScrollPhysics();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const ClampingScrollPhysics();
    }
    return null;
  }

  ScrollPhysics _getEffectiveScrollPhysics(BuildContext context, ScrollPhysics physics) {
    final ScrollPhysics defaultPhysics = getScrollPhysics(getPlatform(context));
    if (physics != null)
      return physics.applyTo(defaultPhysics);
    return defaultPhysics;
  }

  @override
  ScrollPosition createScrollPosition(BuildContext context, Scrollable2State state, ScrollPosition oldPosition, ScrollPhysics physics) {
    return new AbsoluteScrollPosition(state, scrollTolerances, oldPosition, _getEffectiveScrollPhysics(context, physics));
  }

  @override
  bool shouldNotify(ViewportScrollBehavior oldDelegate) {
    return scrollTolerances != oldDelegate.scrollTolerances;
  }
}

abstract class ScrollPhysics {
  const ScrollPhysics();

  ScrollPhysicsProxy applyTo(ScrollPhysics parent) => this;

  /// Used by [AbsoluteDragScrollActivity] and other user-driven activities to
  /// convert an offset in logical pixels as provided by the [DragUpdateDetails]
  /// into a delta to apply using [setPixels].
  ///
  /// This is used by some [ScrollPosition] subclasses to apply friction during
  /// overscroll situations.
  double applyPhysicsToUserOffset(AbsoluteScrollPosition position, double offset) => offset;

  /// Determines the overscroll by applying the boundary conditions.
  ///
  /// Called by [AbsoluteScrollPosition.setPixels] just before the [pixels] value is updated, to
  /// determine how much of the offset is to be clamped off and sent to
  /// [AbsoluteScrollPosition.reportOverscroll].
  ///
  /// The `value` argument is guaranteed to not equal [pixels] when this is
  /// called.
  double applyBoundaryConditions(AbsoluteScrollPosition position, double value) => 0.0;

  /// Returns a simulation for ballisitic scrolling starting from the given
  /// position with the given velocity.
  ///
  /// If the result is non-null, the [ScrollPosition] will begin an
  /// [AbsoluteBallisticScrollActivity] with the returned value. Otherwise, the
  /// [ScrollPosition] will begin an idle activity instead.
  Simulation createBallisticSimulation(AbsoluteScrollPosition position, double velocity) => null;

  static final SpringDescription _kDefaultScrollSpring = new SpringDescription.withDampingRatio(
    mass: 0.5,
    springConstant: 100.0,
    ratio: 1.1,
  );

  SpringDescription get scrollSpring => _kDefaultScrollSpring;
}

abstract class ScrollPhysicsProxy extends ScrollPhysics {
  const ScrollPhysicsProxy(this.parent);

  final ScrollPhysics parent;

  @override
  ScrollPhysicsProxy applyTo(ScrollPhysics parent) {
    throw new FlutterError(
      '$runtimeType must override applyTo.\n'
      'The default implementation of applyTo is not appropriate for subclasses '
      'of ScrollPhysicsProxy because they should return an instance of themselves '
      'with their parent property replaced with the given ScrollPhysics instance.'
    );
  }

  @override
  double applyPhysicsToUserOffset(AbsoluteScrollPosition position, double offset) {
    if (parent == null)
      return super.applyPhysicsToUserOffset(position, offset);
    return parent.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(AbsoluteScrollPosition position, double value) {
    if (parent == null)
      return super.applyBoundaryConditions(position, value);
    return parent.applyBoundaryConditions(position, value);
  }

  @override
  Simulation createBallisticSimulation(AbsoluteScrollPosition position, double velocity) {
    if (parent == null)
      return super.createBallisticSimulation(position, velocity);
    return parent.createBallisticSimulation(position, velocity);
  }

  @override
  SpringDescription get scrollSpring {
    if (parent == null)
      return super.scrollSpring;
    return parent.scrollSpring;
  }
}

class AbsoluteScrollPosition extends ScrollPosition {
  AbsoluteScrollPosition(
    Scrollable2State state,
    Tolerance scrollTolerances,
    ScrollPosition oldPosition,
    this.physics,
  ) : super(state, scrollTolerances, oldPosition);

  final ScrollPhysics physics;

  @override
  double get pixels => _pixels;
  double _pixels = 0.0;

  @override
  double setPixels(double value) {
    assert(SchedulerBinding.instance.schedulerPhase.index <= SchedulerPhase.transientCallbacks.index);
    assert(activity.isScrolling);
    if (value != pixels) {
      final double overScroll = physics.applyBoundaryConditions(this, value);
      assert(() {
        double delta = value - pixels;
        if (overScroll.abs() > delta.abs()) {
          throw new FlutterError(
            '${physics.runtimeType}.applyBoundaryConditions returned invalid overscroll value.\n'
            'setPixels() was called to change the scroll offset from $pixels to $value.\n'
            'That is a delta of $delta units.\n'
            '${physics.runtimeType}.applyBoundaryConditions reported an overscroll of $overScroll units.\n'
            'The scroll extents are $minScrollExtent .. $maxScrollExtent, and the '
            'viewport dimension is $viewportDimension.'
          );
        }
        return true;
      });
      double oldPixels = _pixels;
      _pixels = value - overScroll;
      if (_pixels != oldPixels) {
        notifyListeners();
        dispatchNotification(activity.createScrollUpdateNotification(state, _pixels - oldPixels));
      }
      if (overScroll != 0.0) {
        reportOverscroll(overScroll);
        return overScroll;
      }
    }
    return 0.0;
  }

  @protected
  void reportOverscroll(double value) {
    assert(activity.isScrolling);
    dispatchNotification(activity.createOverscrollNotification(state, value));
  }

  double get viewportDimension => _viewportDimension;
  double _viewportDimension;

  double get minScrollExtent => _minScrollExtent;
  double _minScrollExtent;

  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent;

  bool get outOfRange => pixels < minScrollExtent || pixels > maxScrollExtent;

  bool get atEdge => pixels == minScrollExtent || pixels == maxScrollExtent;

  bool _didChangeViewportDimension = true;

  @override
  void applyViewportDimension(double viewportDimension) {
    if (_viewportDimension != viewportDimension) {
      _viewportDimension = viewportDimension;
      _didChangeViewportDimension = true;
      // If this is called, you can rely on applyContentDimensions being called
      // soon afterwards in the same layout phase. So we put all the logic that
      // relies on both values being computed into applyContentDimensions.
    }
    super.applyViewportDimension(viewportDimension);
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    if (_minScrollExtent != minScrollExtent ||
        _maxScrollExtent != maxScrollExtent ||
        _didChangeViewportDimension) {
      _minScrollExtent = minScrollExtent;
      _maxScrollExtent = maxScrollExtent;
      activity.applyNewDimensions();
      _didChangeViewportDimension = false;
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  ScrollableMetrics getMetrics() {
    return new ScrollableMetrics(
      extentBefore: math.max(pixels - minScrollExtent, 0.0),
      extentInside: math.min(pixels, maxScrollExtent) - math.max(pixels, minScrollExtent) + math.min(viewportDimension, maxScrollExtent - minScrollExtent),
      extentAfter: math.max(maxScrollExtent - pixels, 0.0),
    );
  }

  @override
  bool get canDrag => true;

  @override
  bool get shouldIgnorePointer => activity?.shouldIgnorePointer;

  @override
  void correctBy(double correction) {
    _pixels += correction;
  }

  @override
  void absorb(ScrollPosition other) {
    if (other is AbsoluteScrollPosition) {
      final AbsoluteScrollPosition typedOther = other;
      _pixels = typedOther._pixels;
      _viewportDimension = typedOther.viewportDimension;
      _minScrollExtent = typedOther.minScrollExtent;
      _maxScrollExtent = typedOther.maxScrollExtent;
    }
    super.absorb(other);
  }

  @override
  DragScrollActivity beginDragActivity(DragStartDetails details) {
    beginActivity(new AbsoluteDragScrollActivity(this, details, scrollTolerances));
    return activity;
  }

  @override
  void beginBallisticActivity(double velocity) {
    final Simulation simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      simulation.tolerance = scrollTolerances;
      beginActivity(new AbsoluteBallisticScrollActivity(this, simulation, vsync));
    } else {
      beginIdleActivity();
    }
  }

  /// Animates the position from its current value to the given value `to`.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// The returned [Future] will complete when the animation ends, whether it
  /// completed successfully or whether it was interrupted prematurely.
  ///
  /// An animation will be interrupted whenever the user attempts to scroll
  /// manually, or whenever another activity is started, or whenever the
  /// animation reaches the edge of the viewport and attempts to overscroll. (If
  /// the [ScrollPosition] does not overscroll but instead allows scrolling
  /// beyond the extents, then going beyond the extents will not interrupt the
  /// animation.)
  ///
  /// The animation is indifferent to changes to the viewport or content
  /// dimensions.
  ///
  /// Once the animation has completed, the scroll position will attempt to
  /// begin a ballistic activity in case its value is not stable (for example,
  /// if it is scrolled beyond the extents and in that situation the scroll
  /// position would normally bounce back).
  ///
  /// The duration must not be zero. To jump to a particular value without an
  /// animation, use [setPixels].
  ///
  /// The animation is handled by an [AbsoluteDrivenScrollActivity].
  Future<Null> animate({
    @required double to,
    @required Duration duration,
    @required Curve curve,
  }) {
    final AbsoluteDrivenScrollActivity activity = new AbsoluteDrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: vsync,
    );
    beginActivity(activity);
    return activity.done;
  }

  /// Jumps the scroll position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// If this method changes the scroll position, a sequence of start/update/end
  /// scroll notifications will be dispatched. No overscroll notifications can
  /// be generated by this method.
  ///
  /// Immediately after the jump, a ballistic activity is started, in case the
  /// value was out of range.
  void jumpTo(double value) {
    beginIdleActivity();
    if (_pixels != value) {
      final double oldPixels = _pixels;
      _pixels = value;
      notifyListeners();
      dispatchNotification(activity.createScrollStartNotification(state));
      dispatchNotification(activity.createScrollUpdateNotification(state, _pixels - oldPixels));
      dispatchNotification(activity.createScrollEndNotification(state));
    }
    beginBallisticActivity(0.0);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('range: ${minScrollExtent?.toStringAsFixed(1)}..${maxScrollExtent?.toStringAsFixed(1)}');
    description.add('viewport: ${viewportDimension?.toStringAsFixed(1)}');
  }
}

/// Scroll physics for environments that allow the scroll offset to go beyond
/// the bounds of the content, but then bounce the content back to the edge of
/// those bounds.
///
/// This is the behavior typically seen on iOS.
///
/// See also:
///
/// * [ViewportScrollBehavior], which uses this to provide the iOS component of
///   its scroll behavior.
/// * [ClampingScrollPhysics], which is the analogous physics for Android's
///   clamping behavior.
class BouncingScrollPhysics extends ScrollPhysics {
  const BouncingScrollPhysics();

  /// The multiple applied to overscroll to make it appear that scrolling past
  /// the edge of the scrollable contents is harder than scrolling the list.
  ///
  /// By default this is 0.5, meaning that overscroll is twice as hard as normal
  /// scroll.
  double get frictionFactor => 0.5;

  @override
  double applyPhysicsToUserOffset(AbsoluteScrollPosition position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);
    if (offset > 0.0)
      return _applyFriction(position.pixels, position.minScrollExtent, position.maxScrollExtent, offset, frictionFactor);
    return -_applyFriction(-position.pixels, -position.maxScrollExtent, -position.minScrollExtent, -offset, frictionFactor);
  }

  static double _applyFriction(double start, double lowLimit, double highLimit, double delta, double gamma) {
    assert(lowLimit <= highLimit);
    assert(delta > 0.0);
    double total = 0.0;
    if (start < lowLimit) {
      double distanceToLimit = lowLimit - start;
      double deltaToLimit = distanceToLimit / gamma;
      if (delta < deltaToLimit)
        return total + delta * gamma;
      total += distanceToLimit;
      delta -= deltaToLimit;
    }
    return total + delta;
  }

  @override
  Simulation createBallisticSimulation(AbsoluteScrollPosition position, double velocity) {
    if (velocity.abs() >= position.scrollTolerances.velocity || position.outOfRange) {
      return new BouncingScrollSimulation(
        spring: scrollSpring,
        position: position.pixels,
        velocity: velocity,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
      );
    }
    return null;
  }
}

/// Scroll physics for environments that prevent the scroll offset from reaching
/// beyond the bounds of the content.
///
/// This is the behavior typically seen on Android.
///
/// See also:
///
/// * [ViewportScrollBehavior], which uses this to provide the Android component
///   of its scroll behavior.
/// * [BouncingScrollPhysics], which is the analogous physics for iOS' bouncing
///   behavior.
/// * [GlowingOverscrollIndicator], which is used by [ViewportScrollBehavior] to
///   provide the glowing effect that is usually found with this clamping effect
///   on Android.
class ClampingScrollPhysics extends ScrollPhysics {
  const ClampingScrollPhysics();

  @override
  double applyBoundaryConditions(AbsoluteScrollPosition position, double value) {
    assert(value != position.pixels);
    if (value < position.pixels && position.pixels <= position.minScrollExtent) // underscroll
      return value - position.pixels;
    if (position.maxScrollExtent <= position.pixels && position.pixels < value) // overscroll
      return value - position.pixels;
    if (value < position.minScrollExtent && position.minScrollExtent < position.pixels) // hit top edge
      return value - position.minScrollExtent;
    if (position.pixels < position.maxScrollExtent && position.maxScrollExtent < value) // hit bottom edge
      return value - position.maxScrollExtent;
    return 0.0;
  }

  @override
  Simulation createBallisticSimulation(AbsoluteScrollPosition position, double velocity) {
    if (position.outOfRange) {
      if (position.pixels > position.maxScrollExtent)
        return new ScrollSpringSimulation(scrollSpring, position.pixels, position.maxScrollExtent, math.min(0.0, velocity));
      if (position.pixels < position.minScrollExtent)
        return new ScrollSpringSimulation(scrollSpring, position.pixels, position.minScrollExtent, math.max(0.0, velocity));
      assert(false);
    }
    if (!position.atEdge && velocity.abs() >= position.scrollTolerances.velocity) {
      return new ClampingScrollSimulation(
        position: position.pixels,
        velocity: velocity,
      );
    }
    return null;
  }
}

class AbsoluteDragScrollActivity extends DragScrollActivity {
  AbsoluteDragScrollActivity(
    AbsoluteScrollPosition position,
    DragStartDetails details,
    this.scrollTolerances,
  ) : _lastDetails = details, super(position);

  final Tolerance scrollTolerances;

  @override
  AbsoluteScrollPosition get position => super.position;

  @override
  void update(DragUpdateDetails details, { bool reverse }) {
    assert(details.primaryDelta != null);
    _lastDetails = details;
    double offset = details.primaryDelta;
    if (offset == 0.0)
      return;
    if (reverse) // e.g. an AxisDirection.up scrollable
      offset = -offset;
    position.updateUserScrollDirection(offset > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    position.setPixels(position.pixels - position.physics.applyPhysicsToUserOffset(position, offset));
    // We ignore any reported overscroll returned by setPixels,
    // because it gets reported via the reportOverscroll path.
  }

  @override
  void end(DragEndDetails details, { bool reverse }) {
    assert(details.primaryVelocity != null);
    double velocity = details.primaryVelocity;
    if (reverse) // e.g. an AxisDirection.up scrollable
      velocity = -velocity;
    _lastDetails = details;
    // We negate the velocity here because if the touch is moving downwards,
    // the scroll has to move upwards. It's the same reason that update()
    // above negates the delta before applying it to the scroll offset.
    position.beginBallisticActivity(-velocity);
  }

  @override
  void dispose() {
    _lastDetails = null;
    super.dispose();
  }

  dynamic _lastDetails;

  @override
  Notification createScrollStartNotification(Scrollable2State scrollable) {
    assert(_lastDetails is DragStartDetails);
    return new ScrollStartNotification(scrollable: scrollable, dragDetails: _lastDetails);
  }

  @override
  Notification createScrollUpdateNotification(Scrollable2State scrollable, double scrollDelta) {
    assert(_lastDetails is DragUpdateDetails);
    return new ScrollUpdateNotification(scrollable: scrollable, scrollDelta: scrollDelta, dragDetails: _lastDetails);
  }

  @override
  Notification createOverscrollNotification(Scrollable2State scrollable, double overscroll) {
    assert(_lastDetails is DragUpdateDetails);
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll, dragDetails: _lastDetails);
  }

  @override
  Notification createScrollEndNotification(Scrollable2State scrollable) {
    assert(_lastDetails is DragEndDetails);
    return new ScrollEndNotification(scrollable: scrollable, dragDetails: _lastDetails);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;
}

class AbsoluteBallisticScrollActivity extends ScrollActivity {
  ///
  /// The velocity should be in logical pixels per second.
  AbsoluteBallisticScrollActivity(
    AbsoluteScrollPosition position,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position) {
    _controller = new AnimationController.unbounded(
      value: position.pixels,
      debugLabel: '$runtimeType',
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateWith(simulation)
       .whenComplete(_end);
  }

  @override
  AbsoluteScrollPosition get position => super.position;

  double get velocity => _controller.velocity;

  AnimationController _controller;

  @override
  void resetActivity() {
    position.beginBallisticActivity(velocity);
  }

  @override
  void touched() {
    position.beginIdleActivity();
  }

  @override
  void applyNewDimensions() {
    position.beginBallisticActivity(velocity);
  }

  void _tick() {
    if (position.setPixels(_controller.value) != 0.0)
      position.beginIdleActivity();
  }

  void _end() {
    position?.beginIdleActivity();
  }

  @override
  Notification createOverscrollNotification(Scrollable2State scrollable, double overscroll) {
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll, velocity: velocity);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '$runtimeType($_controller)';
  }
}

class AbsoluteDrivenScrollActivity extends ScrollActivity {
  AbsoluteDrivenScrollActivity(
    ScrollPosition position, {
    @required double from,
    @required double to,
    @required Duration duration,
    @required Curve curve,
    @required TickerProvider vsync,
  }) : super(position) {
    assert(from != null);
    assert(to != null);
    assert(duration != null);
    assert(duration > Duration.ZERO);
    assert(curve != null);
    _completer = new Completer<Null>();
    _controller = new AnimationController.unbounded(
      value: from,
      debugLabel: '$runtimeType',
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateTo(to, duration: duration, curve: curve)
       .whenComplete(_end);
  }

  @override
  AbsoluteScrollPosition get position => super.position;

  Completer<Null> _completer;
  AnimationController _controller;

  Future<Null> get done => _completer.future;

  double get velocity => _controller.velocity;

  @override
  void touched() {
    position.beginIdleActivity();
  }

  void _tick() {
    if (position.setPixels(_controller.value) != 0.0)
      position.beginIdleActivity();
  }

  void _end() {
    position.beginBallisticActivity(velocity);
  }

  @override
  Notification createOverscrollNotification(Scrollable2State scrollable, double overscroll) {
    return new OverscrollNotification(scrollable: scrollable, overscroll: overscroll, velocity: velocity);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _completer.complete();
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '$runtimeType($_controller)';
  }
}

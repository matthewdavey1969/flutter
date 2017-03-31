// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const double _kMinFlingVelocity = 1.0;  // screen width per second.
const Color _kBackgroundColor = const Color(0xFFEFEFF4); // iOS 10 background color.

/// Transitions used for standard iOS full page transitions by bringing coming in from the right on
/// top of the previous screen and by becoming pushed off-screen to the left with a parallax effect
/// below the next screen.
class CupertinoPageTransition extends AnimatedWidget {
  CupertinoPageTransition({
    Key key,
    // Linear route animation from 0.0 to 1.0 when this screen is being pushed.
    @required Animation<double> incomingRouteAnimation,
    // Linear route animation from 0.0 to 1.0 when another screen is being pushed on top of this
    // one.
    @required Animation<double> outgoingRouteAnimation,
    @required this.child,
  })
      : incomingPositionAnimation = _kRightMiddleTween.animate(
          new CurvedAnimation(
            parent: incomingRouteAnimation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          )
        ),
        outgoingPositionAnimation = _kMiddleLeftTween.animate(
          new CurvedAnimation(
            parent: outgoingRouteAnimation,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          )
        ),
        super(
          key: key,
          // Trigger a rebuild whenever any animation route happens. The listenable's value is not
          // used.
          listenable: new AnimationSum(left: incomingRouteAnimation, right: outgoingRouteAnimation),
        );

  // Fractional offset from offscreen to the right to fully on screen.
  static final FractionalOffsetTween _kRightMiddleTween = new FractionalOffsetTween(
    begin: FractionalOffset.topRight,
    end: FractionalOffset.topLeft,
  );

  // Fractional offset from fully on screen to 1/3 offscreen to the left.
  static final FractionalOffsetTween _kMiddleLeftTween = new FractionalOffsetTween(
    begin: FractionalOffset.topLeft,
    end: const FractionalOffset(-0.33, 0.0),
  );

  // When this page is coming in to cover another page.
  final Animation<FractionalOffset> incomingPositionAnimation;
  // When this page is becoming covered by another page.
  final Animation<FractionalOffset> outgoingPositionAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(ianh): tell the transform to be un-transformed for hit testing
    // but not while being controlled by a gesture.
    return new SlideTransition(
      position: outgoingPositionAnimation,
      child: new SlideTransition(
        position: incomingPositionAnimation,
        child: new PhysicalModel(
          shape: BoxShape.rectangle,
          color: _kBackgroundColor,
          elevation: 32,
          child: child,
        ),
      ),
    );
  }
}

/// Transitions used for summoning fullscreen dialogs in iOS such as creating a new
/// calendar event etc by bringing in the next screen from the bottom.
class CupertinoFullscreenDialogTransition extends AnimatedWidget {
  CupertinoFullscreenDialogTransition({
    Key key,
    @required Animation<double> animation,
    @required this.child,
  }) : super(
    key: key,
    listenable: _kBottomUpTween.animate(
      new CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )
    ),
  );

  static final FractionalOffsetTween _kBottomUpTween = new FractionalOffsetTween(
    begin: FractionalOffset.bottomLeft,
    end: FractionalOffset.topLeft,
  );

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new SlideTransition(
      position: listenable,
      child: child,
    );
  }
}

// This class responds to drag gestures to control the route's transition
// animation progress. Used for iOS back gesture.
class CupertinoBackGestureController extends NavigationGestureController {
  CupertinoBackGestureController({
    @required NavigatorState navigator,
    @required this.controller,
  }) : super(navigator) {
    assert(controller != null);
  }

  AnimationController controller;

  @override
  void dispose() {
    controller.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  @override
  void dragUpdate(double delta) {
    // This assert can be triggered the Scaffold is reparented out of the route
    // associated with this gesture controller and continues to feed it events.
    // TODO(abarth): Change the ownership of the gesture controller so that the
    // object feeding it these events (e.g., the Scaffold) is responsible for
    // calling dispose on it as well.
    assert(controller != null);
    controller.value -= delta;
  }

  @override
  bool dragEnd(double velocity) {
    // This assert can be triggered the Scaffold is reparented out of the route
    // associated with this gesture controller and continues to feed it events.
    // TODO(abarth): Change the ownership of the gesture controller so that the
    // object feeding it these events (e.g., the Scaffold) is responsible for
    // calling dispose on it as well.
    assert(controller != null);

    if (velocity.abs() >= _kMinFlingVelocity) {
      controller.fling(velocity: -velocity);
    } else if (controller.value <= 0.5) {
      controller.fling(velocity: -1.0);
    } else {
      controller.fling(velocity: 1.0);
    }

    // Don't end the gesture until the transition completes.
    final AnimationStatus status = controller.status;
    _handleStatusChanged(status);
    controller?.addStatusListener(_handleStatusChanged);

    return (status == AnimationStatus.reverse || status == AnimationStatus.dismissed);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed)
      navigator.pop();
  }
}

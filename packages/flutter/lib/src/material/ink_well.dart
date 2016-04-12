// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'material.dart';
import 'theme.dart';

/// An area of a [Material] that responds to touch. Has a configurable shape and
/// can be configured to clip splashes that extend outside its bounds or not.
///
/// For a variant of this widget that is specialised for rectangular areas that
/// always clip splashes, see [InkWell].
///
/// Must have an ancestor [Material] widget in which to cause ink reactions.
///
/// If a Widget uses this class directly, it should include the following line
/// at the top of its [build] function to call [debugCheckHasMaterial]:
///
///     assert(debugCheckHasMaterial(context));
class InkResponse extends StatefulWidget {
  /// Creates an area of a [Material] that responds to touch.
  ///
  /// Must have an ancestor [Material] widget in which to cause ink reactions.
  InkResponse({
    Key key,
    this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.containedInkWell: false,
    this.highlightShape: BoxShape.circle
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the user taps this part of the material
  final GestureTapCallback onTap;

  /// Called when the user double taps this part of the material.
  final GestureTapCallback onDoubleTap;

  /// Called when the user long-presses on this part of the material.
  final GestureLongPressCallback onLongPress;

  /// Called when this part of the material either becomes highlighted or stops behing highlighted.
  ///
  /// The value passed to the callback is true if this part of the material has
  /// become highlighted and false if this part of the material has stopped
  /// being highlighted.
  final ValueChanged<bool> onHighlightChanged;

  /// Whether this ink response should be clipped its bounds.
  final bool containedInkWell;

  /// The shape (e.g., circle, rectangle) to use for the highlight drawn around this part of the material.
  final BoxShape highlightShape;

  @override
  _InkResponseState<InkResponse> createState() => new _InkResponseState<InkResponse>();
}

class _InkResponseState<T extends InkResponse> extends State<T> {

  Set<InkSplash> _splashes;
  InkSplash _currentSplash;
  InkHighlight _lastHighlight;

  void updateHighlight(bool value) {
    if (value == (_lastHighlight != null && _lastHighlight.active))
      return;
    if (value) {
      if (_lastHighlight == null) {
        RenderBox referenceBox = context.findRenderObject();
        assert(Material.of(context) != null);
        _lastHighlight = Material.of(context).highlightAt(
          referenceBox: referenceBox,
          color: Theme.of(context).highlightColor,
          shape: config.highlightShape,
          onRemoved: () {
            assert(_lastHighlight != null);
            _lastHighlight = null;
          }
        );
      } else {
        _lastHighlight.activate();
      }
    } else {
      _lastHighlight.deactivate();
    }
    assert(value == (_lastHighlight != null && _lastHighlight.active));
    if (config.onHighlightChanged != null)
      config.onHighlightChanged(value);
  }

  void _handleTapDown(Point position) {
    RenderBox referenceBox = context.findRenderObject();
    assert(Material.of(context) != null);
    InkSplash splash;
    splash = Material.of(context).splashAt(
      referenceBox: referenceBox,
      position: referenceBox.globalToLocal(position),
      color: Theme.of(context).splashColor,
      containedInWell: config.containedInkWell,
      onRemoved: () {
        if (_splashes != null) {
          assert(_splashes.contains(splash));
          _splashes.remove(splash);
          if (_currentSplash == splash)
            _currentSplash = null;
        } // else we're probably in deactivate()
      }
    );
    _splashes ??= new HashSet<InkSplash>();
    _splashes.add(splash);
    _currentSplash = splash;
    updateHighlight(true);
  }

  void _handleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(false);
    if (config.onTap != null)
      config.onTap();
  }

  void _handleTapCancel() {
    _currentSplash?.cancel();
    _currentSplash = null;
    updateHighlight(false);
  }

  void _handleDoubleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (config.onDoubleTap != null)
      config.onDoubleTap();
  }

  void _handleLongPress() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (config.onLongPress != null)
      config.onLongPress();
  }

  @override
  void deactivate() {
    if (_splashes != null) {
      Set<InkSplash> splashes = _splashes;
      _splashes = null;
      for (InkSplash splash in splashes)
        splash.dispose();
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    _lastHighlight?.dispose();
    _lastHighlight = null;
    super.deactivate();
  }

  @override
  void dependenciesChanged(Type affectedWidgetType) {
    if (affectedWidgetType == Theme && _lastHighlight != null)
      _lastHighlight.color = Theme.of(context).highlightColor;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final bool enabled = config.onTap != null || config.onDoubleTap != null || config.onLongPress != null;
    return new GestureDetector(
      onTapDown: enabled ? _handleTapDown : null,
      onTap: enabled ? _handleTap : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onDoubleTap: config.onDoubleTap != null ? _handleDoubleTap : null,
      onLongPress: config.onLongPress != null ? _handleLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: config.child
    );
  }

}

/// A rectangular area of a Material that responds to touch.
///
/// Must have an ancestor [Material] widget in which to cause ink reactions.
///
/// If a Widget uses this class directly, it should include the following line
/// at the top of its [build] function to call [debugCheckHasMaterial]:
///
///     assert(debugCheckHasMaterial(context));
class InkWell extends InkResponse {
  /// Creates an ink well.
  ///
  /// Must have an ancestor [Material] widget in which to cause ink reactions.
  InkWell({
    Key key,
    Widget child,
    GestureTapCallback onTap,
    GestureTapCallback onDoubleTap,
    GestureLongPressCallback onLongPress,
    ValueChanged<bool> onHighlightChanged
  }) : super(
    key: key,
    child: child,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onHighlightChanged: onHighlightChanged,
    containedInkWell: true,
    highlightShape: BoxShape.rectangle
  );
}

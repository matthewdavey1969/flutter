// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'raw_keyboard_listener.dart';

typedef FocusableOnKeyCallback = bool Function(FocusNode node, RawKeyEvent event);

/// A widget that manages a [FocusNode] to allow keyboard focus to be given
/// to this widget and its descendants.
///
/// It manages a [FocusNode], managing its lifecycle, and listening for
/// changes in focus.
///
/// It provides [onFocusChange] as a way to be notified when the focus is given
/// to or removed from this widget.
///
/// The [onKey] argument allows specification of a key even handler that should
/// be invoked when this node or one of its children has focus.
///
/// This widget does not provide any visual indication that the focus has
/// changed. To provide that, add a [FocusHighlight] widget as a descendant of
/// this widget.
///
/// To collect nodes into a group, use a [FocusScopeNode].
///
/// To manipulate the focus, use methods on [FocusScopeNode]. For instance,
/// to move the focus to the next node, call
/// `Focusable.of(context).nextFocus()`.
class Focusable extends StatefulWidget {
  /// Creates a widget that manages a [FocusNode]
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus] argument must not be null.
  const Focusable({
    Key key,
    @required this.child,
    this.autofocus = false,
    this.onFocusChange,
    this.onKey,
    this.debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(key: key);

  /// A debug label for this widget.
  final String debugLabel;

  /// The child widget of this [Focusable].
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Handler for keys pressed when this object or one of its children has
  /// focus.
  ///
  /// Key events are first given to the leaf nodes, and if they don't handle
  /// them, then to each node up the widget hierarchy. If they reach the root of
  /// the hierarchy, they are discarded.
  ///
  /// This is not the way to get text input in the manner of a text field: it
  /// leaves out support for input method editors, and doesn't support soft
  /// keyboards in general. For text input, consider [TextField] or
  /// [CupertinoTextField], which do support these things.
  final FocusableOnKeyCallback onKey;

  /// Handler called when the focus of this focusable changes.
  ///
  /// Called with true if this focusable gains focus, and false if it loses
  /// focus.
  final ValueChanged<bool> onFocusChange;

  /// True if this widget will be selected as the initial focus when no other
  /// node in its scope is currently focused.
  ///
  /// There must only be one descendant node in a scope that has `autofocus`
  /// set, unless it is the descendant of another scope.
  final bool autofocus;

  /// Returns the [node] of the [Focusable] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static FocusNode of(BuildContext context) {
    assert(context != null);
    final _FocusableMarker marker = context.inheritFromWidgetOfExactType(_FocusableMarker);
    return marker?.node ?? context.owner.focusManager.rootScope;
  }

  /// A convenience function to allow build functions to write:
  /// `Focusable.at(context)` to get whether or not the nearest Focusable above
  /// them in the widget hierarchy currently has the keyboard focus.
  static bool at(BuildContext context) {
    return Focusable.of(context).hasFocus;
  }

  // Only FocusScopes can handle external nodes.
  FocusScopeNode get _externalNode => null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
    properties.add(FlagProperty('autofocus', value: autofocus, ifTrue: 'AUTOFOCUS', defaultValue: false));
  }

  @override
  _FocusableState createState() => _FocusableState();
}

class _FocusableState extends State<Focusable> {
  FocusNode _internalNode;
  FocusNode get node => widget._externalNode ?? _internalNode;
  bool _hasFocus;
  bool _didAutofocus = false;

  FocusNode _createNode(){
    return FocusNode(
      debugLabel: widget.debugLabel,
      context: context,
    );
  }

  void _initNode() {
    if (widget._externalNode == null) {
      // Only create a new node if the widget doesn't have one.
      _internalNode ??= _createNode();
    }
    _hasFocus = node.hasFocus;
    // Add listener even if the _internalNode existed before, since it should
    // not be listening already if we're re-using a previous one.
    node.addListener(_handleFocusChanged);
  }

  @override
  void initState() {
    super.initState();
    _initNode();
  }

  @override
  void dispose() {
    widget._externalNode?.removeListener(_handleFocusChanged);
    _internalNode?.removeListener(_handleFocusChanged);
    // Don't manage the lifetime of external nodes given to the widget, just the
    // internal node.
    _internalNode?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }
    if (_hasFocus != node.hasFocus) {
      setState(() {
        _hasFocus = node.hasFocus;
      });
      if (widget.onFocusChange != null) {
        widget.onFocusChange(node.hasFocus);
      }
    }
  }

  @override
  void didUpdateWidget(Focusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._externalNode == widget._externalNode) {
      // Nothing we care about changed.
      return;
    }
    if (oldWidget._externalNode == null && widget._externalNode != null) {
      // We're no longer using the node we were managing. We don't stop managing
      // it until dispose, so do nothing yet: we might re-use it eventually, and
      // calling dispose on it here will confuse the raw keyboard handler that
      // hasn't yet been notified of a widget change, but do stop listening.
      _internalNode?.removeListener(_handleFocusChanged);
      widget._externalNode?.addListener(_handleFocusChanged);
    } else if (oldWidget._externalNode != null && widget._externalNode == null) {
      oldWidget._externalNode?.removeListener(_handleFocusChanged);
      // We stopped using the external node, and now we need to manage one.
      _initNode();
    } else {
      // We just switched which node the widget had, so just change what we
      // listen to.
      oldWidget._externalNode?.removeListener(_handleFocusChanged);
      widget._externalNode?.addListener(_handleFocusChanged);
    }
    if (oldWidget.debugLabel != widget.debugLabel) {
      node.debugLabel = widget.debugLabel;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final FocusNode newParent = Focusable.of(context);
    if (!_didAutofocus && widget.autofocus) {
      FocusScope.of(context).setFirstFocus(node, context);
      _didAutofocus = true;
    } else {
      newParent.reparentIfNeeded(node, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Focusable.of(context).reparentIfNeeded(node, context);
    return RawKeyboardListener(
      focusNode: node,
      onKey: (RawKeyEvent event) {
        if (widget.onKey != null) {
          widget.onKey(node, event);
        }
      },
      child: _FocusableMarker(
        node: node,
        child: widget.child,
      ),
    );
  }
}

/// A [FocusScope] is a [Focusable] that serves as a scope for other
/// [Focusable]s.
///
/// It manages a [FocusScopeNode], managing its lifecycle, and listening for
/// changes in focus. Scope nodes provide a scope for their children, using the
/// focus traversal policy defined by the [DefaultFocusTraversal] widget above
/// them to traverse their children.
///
/// Scope nodes remember the last focusable node that was focused within their
/// descendants, and can move that focus to the next/previous node, or a node in
/// a particular direction when the [FocusNode.nextFocus],
/// [FocusNode.previousFocus], or [FocusNode.focusInDirection] are
/// called on a [FocusNode] or [FocusScopeNode] that is a child of this
/// scope, or the node owned by the scope node managed by this widget.
///
/// The selection process of the node to move to is determined by the node
/// traversal policy specified by the nearest enclosing
/// [DefaultFocusTraversal] widget.
///
/// It provides [onFocusChange] as a way to be notified when the focus is given
/// to or removed from this widget, and allows specification of a
/// [focusedDecoration] to be shown when its [child] has focus.
///
/// The [onKey] argument allows specification of a key even handler that should
/// be invoked when this node or one of its children has focus.
///
/// To manipulate the focus, use methods on [FocusScopeNode]. For instance,
/// to move the focus to the next node, call
/// `Focusable.of(context).nextFocus()`.
class FocusScope extends Focusable {
  /// Creates a widget that manages a [FocusScopeNode]
  ///
  /// The [child] argument is required and must not be null.
  ///
  /// The [autofocus], and [showDecorations] arguments must not be null.
  const FocusScope({
    Key key,
    this.node,
    @required Widget child,
    bool autofocus = false,
    ValueChanged<bool> onFocusChange,
    FocusableOnKeyCallback onKey,
    String debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(
          key: key,
          child: child,
          autofocus: autofocus,
          onFocusChange: onFocusChange,
          onKey: onKey,
          debugLabel: debugLabel,
        );

  /// Returns the node of the [FocusScope] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static FocusScopeNode of(BuildContext context) {
    assert(context != null);
    final _FocusableMarker marker = context.inheritFromWidgetOfExactType(_FocusableMarker);
    return marker?.node?.nearestScope ?? context.owner.focusManager.rootScope;
  }

  /// Returns the ancestor nodes of the [FocusScope] in the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static List<FocusScopeNode> ancestorsOf(BuildContext context) {
    assert(context != null);
    final FocusScopeNode parent = FocusScope.of(context);
    return parent?.ancestors?.cast<FocusScopeNode>()?.toList() ?? <FocusScopeNode>[];
  }

  /// The focus scope node that this FocusScope will use.
  ///
  /// If not supplied, will create and manage its own.
  final FocusScopeNode node;

  @override
  FocusScopeNode get _externalNode => node;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusScopeNode>('node', node, defaultValue: null));
  }

  @override
  _FocusableScopeState createState() => _FocusableScopeState();
}

class _FocusableScopeState extends _FocusableState {
  @override
  FocusScopeNode _createNode(){
    return FocusScopeNode(
      debugLabel: widget.debugLabel,
      context: context,
    );
  }
}

// The InheritedWidget marker for Focusable and FocusScope.
class _FocusableMarker extends InheritedWidget {
  const _FocusableMarker({
    Key key,
    @required this.node,
    Widget child,
  })  : assert(node != null),
        super(key: key, child: child);

  final FocusNode node;

  @override
  bool updateShouldNotify(_FocusableMarker oldWidget) {
    return node != oldWidget.node;
  }
}

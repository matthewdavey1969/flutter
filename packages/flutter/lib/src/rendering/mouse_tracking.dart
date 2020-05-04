// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedHashSet;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

import 'mouse_cursor.dart';
import 'object.dart';

/// Signature for listening to [PointerEnterEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
typedef PointerEnterEventListener = void Function(PointerEnterEvent event);

/// Signature for listening to [PointerExitEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
typedef PointerExitEventListener = void Function(PointerExitEvent event);

/// Signature for listening to [PointerHoverEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
typedef PointerHoverEventListener = void Function(PointerHoverEvent event);

/// The annotation object used to annotate regions that are interested in mouse
/// movements.
///
/// To use an annotation, push it with [AnnotatedRegionLayer] during painting.
/// The annotation's callbacks or configurations will be used depending on the
/// relationship between annotations and mouse pointers.
/// 
/// A [RenderObject] who uses this class must not dispose this class in its
/// `detach`, even if it recreates a new one in `attach`, because the object
/// might be detached and attached during the same frame during a reparent, and
/// replacing the `MouseTrackerAnnotation` will cause an unnecessary `onExit` and
/// `onEnter`.
///
/// This class is also the type parameter of the annotation search started by
/// [MouseTracker].
///
/// See also:
///
///  * [MouseTracker], which uses [MouseTrackerAnnotation].
///  * [MouseTrackedRenderObjectMixin], which is a convenient mixin for render
///    objects that implements this class while supporting varying cursor and
///    callbacks.
class MouseTrackerAnnotation with Diagnosticable {
  /// Creates an immutable [MouseTrackerAnnotation].
  const MouseTrackerAnnotation({
    this.onEnter,
    this.onHover,
    this.onExit,
    this.cursor,
  });

  /// Triggered when a mouse pointer, with or without buttons pressed, has
  /// entered the annotated region.
  ///
  /// This callback is triggered when the pointer has started to be contained
  /// by the annotationed region for any reason, which means it always matches a
  /// later [onExit].
  ///
  /// See also:
  ///
  ///  * [onExit], which is triggered when a mouse pointer exits the region.
  ///  * [MouseRegion.onEnter], which uses this callback.
  final PointerEnterEventListener onEnter;

  /// Triggered when a pointer has moved within the annotated region without
  /// buttons pressed.
  ///
  /// This callback is triggered when:
  ///
  ///  * An annotation that did not contain the pointer has moved to under a
  ///    pointer that has no buttons pressed.
  ///  * A pointer has moved onto, or moved within an annotation without buttons
  ///    pressed.
  ///
  /// This callback is not triggered when:
  ///
  ///  * An annotation that is containing the pointer has moved, and still
  ///    contains the pointer.
  ///
  /// See also:
  ///
  ///  * [MouseRegion.onHover], which uses this callback.
  final PointerHoverEventListener onHover;

  /// Triggered when a mouse pointer, with or without buttons pressed, has
  /// exited the annotated region when the annotated region still exists.
  ///
  /// This callback is triggered when the pointer has stopped being contained
  /// by the region for any reason, which means it always matches an earlier
  /// [onEnter].
  ///
  /// See also:
  ///
  ///  * [onEnter], which is triggered when a mouse pointer enters the region.
  ///  * [RenderMouseRegion.onExit], which uses this callback.
  ///  * [MouseRegion.onExit], which uses this callback, but is not triggered in
  ///    certain cases and does not always match its earier [MouseRegion.onEnter].
  final PointerExitEventListener onExit;

  /// The mouse cursor for mouse pointers that are hovering over the annotated
  /// region.
  ///
  /// When a mouse enters the annotated region, its cursor will be changed to the
  /// [cursor]. If the [cursor] is null, then the annotated region does not
  /// control cursors, but defers the choice to the next annotation behind this
  /// one on the screen in hit-test order, or [SystemMouseCursors.basic] if no
  /// others can be found.
  ///
  /// The [MouseTrackerAnnotation] is immutable and does not support varying
  /// [cursor].
  ///
  /// For a subclass that wishes to support varying [cursor], it must implement
  /// [addStatusListener] and [removeStatusListener].
  ///
  /// See also:
  ///
  ///  * [MouseCursors] for a general introduction to the mouse cursor system.
  ///  * [SystemMouseCursors], which is a collection of system cursors of all
  ///    platforms.
  ///  * [RenderMouseRegion.cursor] and [MouseRegion.cursor], which provide
  ///    values to this field.
  ///  * [MouseTrackedRenderObjectMixin], which is a utility class that simplifies
  ///    defining annotations that support varying [cursor].
  final MouseCursor cursor;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagsSummary<Function>(
      'callbacks',
      <String, Function> {
        'enter': onEnter,
        'hover': onHover,
        'exit': onExit,
      },
      ifEmpty: '<none>',
    ));
    properties.add(DiagnosticsProperty<MouseCursor>('cursor', cursor, defaultValue: null));
  }
}

/// A mixin for render objects that wants to push a [MouseTrackerAnnotation] with
/// varying callbacks and cursors.
///
/// A [RenderObject] that has [MouseTrackedRenderObjectMixin] should push itself
/// as an annotation after assigning callbacks or [cursor] as desired. This mixin
/// will monitor the value of [cursor] and properly notify listeners or call
/// [markNeedsPaint] when necessary.
/// 
/// If you just want to use [PreparedMouseCursor] on the render object layer,
/// usually the easiest way is [RenderMouseRegion]. The
/// [MouseTrackedRenderObjectMixin] should be used if you want to define your own
/// render object class that includes cursor configuration, especially if the
/// cursor of this render object might change.
///
/// See also:
///
///  * [MouseTracker], which uses [MouseTrackerAnnotation].
///  * [MouseTrackerAnnotation], which is an immutable implementation of
///    this class, and the interface thereof.
mixin MouseTrackedRenderObjectMixin on RenderObject implements MouseTrackerAnnotation {
  @override
  PointerEnterEventListener onEnter;

  @override
  PointerHoverEventListener onHover;

  @override
  PointerExitEventListener onExit;

  @override
  MouseCursor get cursor => _cursor;
  MouseCursor _cursor;
  set cursor(MouseCursor value) {
    final MouseCursor oldCursor = _cursor;
    _cursor = value;
    if (attached && oldCursor != value) {
      if ((oldCursor != null) == (value != null)) {
        _notifyCursorListeners();
      } else {
        markNeedsPaint();
      }
    }
  }

  final ObserverList<VoidCallback> _cursorListeners = ObserverList<VoidCallback>();

  void _notifyCursorListeners() {
    final List<VoidCallback> localListeners = List<VoidCallback>.from(_cursorListeners);
    for (final VoidCallback listener in localListeners) {
      try {
        if (_cursorListeners.contains(listener))
          listener();
      } catch (exception, stack) {
        InformationCollector collector;
        assert(() {
          collector = () sync* {
            yield DiagnosticsProperty<MouseTrackedRenderObjectMixin>(
              'The $runtimeType notifying status listeners was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          };
          return true;
        }());
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'animation library',
          context: ErrorDescription('while notifying status listeners for $runtimeType'),
          informationCollector: collector
        ));
      }
    }
  }
}

/// Signature for searching for [MouseTrackerAnnotation]s at the given offset.
///
/// It is used by the [MouseTracker] to fetch annotations for the mouse
/// position.
typedef MouseDetectorAnnotationFinder = Iterable<MouseTrackerAnnotation> Function(Offset offset);

// Various states of a connected mouse device used by [MouseTracker].
class _MouseState {
  _MouseState({
    @required PointerEvent initialEvent,
  }) : assert(initialEvent != null),
       _latestEvent = initialEvent;

  // The list of annotations that contains this device.
  //
  // It uses [LinkedHashSet] to keep the insertion order.
  LinkedHashSet<MouseTrackerAnnotation> get annotations => _annotations;
  LinkedHashSet<MouseTrackerAnnotation> _annotations = <MouseTrackerAnnotation>{} as LinkedHashSet<MouseTrackerAnnotation>;

  LinkedHashSet<MouseTrackerAnnotation> replaceAnnotations(LinkedHashSet<MouseTrackerAnnotation> value) {
    assert(value != null);
    final LinkedHashSet<MouseTrackerAnnotation> previous = _annotations;
    _annotations = value;
    return previous;
  }

  // The most recently processed mouse event observed from this device.
  PointerEvent get latestEvent => _latestEvent;
  PointerEvent _latestEvent;

  PointerEvent replaceLatestEvent(PointerEvent value) {
    assert(value != null);
    assert(value.device == _latestEvent.device);
    final PointerEvent previous = _latestEvent;
    _latestEvent = value;
    return previous;
  }

  int get device => latestEvent.device;

  @override
  String toString() {
    String describeEvent(PointerEvent event) {
      return event == null ? 'null' : describeIdentity(event);
    }
    final String describeLatestEvent = 'latestEvent: ${describeEvent(latestEvent)}';
    final String describeAnnotations = 'annotations: [list of ${annotations.length}]';
    return '${describeIdentity(this)}($describeLatestEvent, $describeAnnotations)';
  }
}

/// Used by [MouseTracker] to provide the details of an update of a mouse
/// device.
///
/// This class contains the information needed to handle the update that might
/// change the state of a mouse device, or the [MouseTrackerAnnotation]s that
/// the mouse device is hovering.
@immutable
class MouseTrackerUpdateDetails with Diagnosticable {
  /// When device update is triggered by a new frame.
  ///
  /// All parameters are required.
  const MouseTrackerUpdateDetails.byNewFrame({
    @required this.lastAnnotations,
    @required this.nextAnnotations,
    @required this.previousEvent,
  }) : assert(previousEvent != null),
       assert(lastAnnotations != null),
       assert(nextAnnotations != null),
       triggeringEvent = null;

  /// When device update is triggered by a pointer event.
  ///
  /// The [lastAnnotations], [nextAnnotations], and [triggeringEvent] are
  /// required.
  const MouseTrackerUpdateDetails.byPointerEvent({
    @required this.lastAnnotations,
    @required this.nextAnnotations,
    this.previousEvent,
    @required this.triggeringEvent,
  }) : assert(triggeringEvent != null),
       assert(lastAnnotations != null),
       assert(nextAnnotations != null);

  /// The annotations that the device is hovering before the update.
  ///
  /// It is never null.
  final LinkedHashSet<MouseTrackerAnnotation> lastAnnotations;

  /// The annotations that the device is hovering after the update.
  ///
  /// It is never null.
  final LinkedHashSet<MouseTrackerAnnotation> nextAnnotations;

  /// The last event that the device observed before the update.
  ///
  /// If the update is triggered by a frame, it is not null, since the pointer
  /// must have been added before. If the update is triggered by an event,
  /// it might be null.
  final PointerEvent previousEvent;

  /// The event that triggered this update.
  ///
  /// It is non-null if and only if the update is triggered by a pointer event.
  final PointerEvent triggeringEvent;

  /// The pointing device of this update.
  int get device {
    final int result = (previousEvent ?? triggeringEvent).device;
    assert(result != null);
    return result;
  }

  /// The last event that the device observed after the update.
  ///
  /// The [latestEvent] is never null.
  PointerEvent get latestEvent {
    final PointerEvent result = triggeringEvent ?? previousEvent;
    assert(result != null);
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('device', device));
    properties.add(DiagnosticsProperty<PointerEvent>('previousEvent', previousEvent));
    properties.add(DiagnosticsProperty<PointerEvent>('triggeringEvent', triggeringEvent));
    properties.add(DiagnosticsProperty<Set<MouseTrackerAnnotation>>('lastAnnotations', lastAnnotations));
    properties.add(DiagnosticsProperty<Set<MouseTrackerAnnotation>>('nextAnnotations', nextAnnotations));
  }
}

/// A base class that tracks the relationship between mouse devices and
/// [MouseTrackerAnnotation]s.
///
/// A _device update_ is defined as an event that changes the relationship
/// between mouse devices and [MouseTrackerAnnotation]s. Subclasses should
/// override [handleDeviceUpdate] to process the updates.
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [mouseIsConnected] changes.
///
/// ### States and device updates
///
/// The state of [BaseMouseTracker] consists of two parts:
///
///  * The mouse devices that are connected.
///  * In which annotations each device is contained.
///
/// The states remain stable most of the time, and are only changed at the
/// following moments:
///
///  * An eligible [PointerEvent] has been observed, e.g. a device is added,
///    removed, or moved. In this case, the state related to this device will
///    be immediately updated, and triggers [handleDeviceUpdate] on this device.
///  * A frame has been painted. In this case, a callback will be scheduled for
///    the upcoming post-frame phase to update all devices, and triggers
///    [handleDeviceUpdate] on each device separately.
///
/// See also:
///
///   * [MouseTracker], which is a subclass of [BaseMouseTracker] with definition
///     of how to process mouse event callbacks and mouse cursors.
///   * [MouseCursorMixin], which is a mixin for [BaseMouseTracker] that defines
///     how to process mouse cursors.
class BaseMouseTracker extends ChangeNotifier {
  /// Creates a [BaseMouseTracker] to keep track of mouse locations.
  ///
  /// The first parameter is a [PointerRouter], which [BaseMouseTracker] will
  /// subscribe to and receive events from. Usually it is the global singleton
  /// instance [GestureBinding.pointerRouter].
  ///
  /// The second parameter is a function with which the [BaseMouseTracker] can
  /// search for [MouseTrackerAnnotation]s at a given position.
  /// Usually it is [Layer.findAllAnnotations] of the root layer.
  ///
  /// All of the parameters must be non-null.
  BaseMouseTracker(this._router, this.annotationFinder)
      : assert(_router != null),
        assert(annotationFinder != null) {
    _router.addGlobalRoute(_handleEvent);
  }

  @override
  void dispose() {
    super.dispose();
    _router.removeGlobalRoute(_handleEvent);
  }

  /// Find annotations at a given offset in global logical coordinate space
  /// in visual order from front to back.
  ///
  /// [MouseTracker] uses this callback to know which annotations are
  /// affected by each device.
  ///
  /// The annotations should be returned in visual order from front to
  /// back, so that the callbacks are called in an correct order.
  final MouseDetectorAnnotationFinder annotationFinder;

  // The pointer router that the mouse tracker listens to, and receives new
  // mouse events from.
  final PointerRouter _router;

  bool _hasScheduledPostFrameCheck = false;
  /// Mark all devices as dirty, and schedule a callback that is executed in the
  /// upcoming post-frame phase to check their updates.
  ///
  /// Checking a device means to collect the annotations that the pointer
  /// hovers, and triggers necessary callbacks accordingly.
  ///
  /// Although the actual callback belongs to the scheduler's post-frame phase,
  /// this method must be called in persistent callback phase to ensure that
  /// the callback is scheduled after every frame, since every frame can change
  /// the position of annotations. Typically the method is called by
  /// [RendererBinding]'s drawing method.
  void schedulePostFrameCheck() {
    assert(SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks);
    assert(!_debugDuringDeviceUpdate);
    if (!mouseIsConnected)
      return;
    if (!_hasScheduledPostFrameCheck) {
      _hasScheduledPostFrameCheck = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        assert(_hasScheduledPostFrameCheck);
        _hasScheduledPostFrameCheck = false;
        _updateAllDevices();
      });
    }
  }

  /// Whether or not a mouse is connected and has produced events.
  bool get mouseIsConnected => _mouseStates.isNotEmpty;

  // Tracks the state of connected mouse devices.
  //
  // It is the source of truth for the list of connected mouse devices.
  final Map<int, _MouseState> _mouseStates = <int, _MouseState>{};

  // Used to wrap any procedure that might change `mouseIsConnected`.
  //
  // This method records `mouseIsConnected`, runs `task`, and calls
  // [notifyListeners] at the end if the `mouseIsConnected` has changed.
  void _monitorMouseConnection(VoidCallback task) {
    final bool mouseWasConnected = mouseIsConnected;
    task();
    if (mouseWasConnected != mouseIsConnected)
      notifyListeners();
  }

  bool _debugDuringDeviceUpdate = false;
  // Used to wrap any procedure that might call [handleDeviceUpdate].
  //
  // In debug mode, this method uses `_debugDuringDeviceUpdate` to prevent
  // `_deviceUpdatePhase` being recursively called.
  void _deviceUpdatePhase(VoidCallback task) {
    assert(!_debugDuringDeviceUpdate);
    assert(() {
      _debugDuringDeviceUpdate = true;
      return true;
    }());
    task();
    assert(() {
      _debugDuringDeviceUpdate = false;
      return true;
    }());
  }

  // Whether an observed event might update a device.
  static bool _shouldMarkStateDirty(_MouseState state, PointerEvent event) {
    if (state == null)
      return true;
    assert(event != null);
    final PointerEvent lastEvent = state.latestEvent;
    assert(event.device == lastEvent.device);
    // An Added can only follow a Removed, and a Removed can only be followed
    // by an Added.
    assert((event is PointerAddedEvent) == (lastEvent is PointerRemovedEvent));

    // Ignore events that are unrelated to mouse tracking.
    if (event is PointerSignalEvent)
      return false;
    return lastEvent is PointerAddedEvent
      || event is PointerRemovedEvent
      || lastEvent.position != event.position;
  }

  // Find the annotations that is hovered by the device of the `state`.
  //
  // If the device is not connected, an empty set is returned without calling
  // `annotationFinder`.
  LinkedHashSet<MouseTrackerAnnotation> _findAnnotations(_MouseState state) {
    final Offset globalPosition = state.latestEvent.position;
    final int device = state.device;
    return (_mouseStates.containsKey(device))
      ? LinkedHashSet<MouseTrackerAnnotation>.from(annotationFinder(globalPosition))
      : <MouseTrackerAnnotation>{} as LinkedHashSet<MouseTrackerAnnotation>;
  }

  /// A callback that is called on the update of a device.
  ///
  /// This method should be called only by [MouseTracker].
  ///
  /// Override this method to receive updates when the relationship between a
  /// device and annotations have changed. Subclasses should override this method
  /// to first call to their inherited [handleDeviceUpdate] method, and then
  /// process the update as desired,
  ///
  /// The update can be caused by two kinds of triggers:
  ///
  ///   * Triggered by the addition, movement, or removal of a pointer. Such
  ///     calls occur during the handler of the event, indicated by
  ///     `details.triggeringEvent` being non-null.
  ///   * Triggered by the appearance, movement, or disappearance of an annotation.
  ///     Such calls occur after each new frame, during the post-frame callbacks,
  ///     indicated by `details.triggeringEvent` being null.
  ///
  /// This method is not triggered if the [MouseTrackerAnnotation] is mutated.
  ///
  /// Calling of this method must be wrapped in `_deviceUpdatePhase`.
  @protected
  @mustCallSuper
  void handleDeviceUpdate(MouseTrackerUpdateDetails details) {
    assert(_debugDuringDeviceUpdate);
  }

  // Handler for events coming from the PointerRouter.
  //
  // If the event marks the device dirty, update the device immediately.
  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse)
      return;
    if (event is PointerSignalEvent)
      return;
    final int device = event.device;
    final _MouseState existingState = _mouseStates[device];
    if (!_shouldMarkStateDirty(existingState, event))
      return;

    _monitorMouseConnection(() {
      _deviceUpdatePhase(() {
        // Update mouseState to the latest devices that have not been removed,
        // so that [mouseIsConnected], which is decided by `_mouseStates`, is
        // correct during the callbacks.
        if (existingState == null) {
          _mouseStates[device] = _MouseState(initialEvent: event);
        } else {
          assert(event is! PointerAddedEvent);
          if (event is PointerRemovedEvent)
            _mouseStates.remove(event.device);
        }
        final _MouseState targetState = _mouseStates[device] ?? existingState;

        final PointerEvent lastEvent = targetState.replaceLatestEvent(event);
        final LinkedHashSet<MouseTrackerAnnotation> nextAnnotations = _findAnnotations(targetState);
        final LinkedHashSet<MouseTrackerAnnotation> lastAnnotations = targetState.replaceAnnotations(nextAnnotations);

        handleDeviceUpdate(MouseTrackerUpdateDetails.byPointerEvent(
          lastAnnotations: lastAnnotations,
          nextAnnotations: nextAnnotations,
          previousEvent: lastEvent,
          triggeringEvent: event,
        ));
      });
    });
  }

  // Update all devices, despite observing no new events.
  //
  // This is called after a new frame, since annotations can be moved after
  // every frame.
  void _updateAllDevices() {
    _deviceUpdatePhase(() {
      for (final _MouseState dirtyState in _mouseStates.values) {
        final PointerEvent lastEvent = dirtyState.latestEvent;
        final LinkedHashSet<MouseTrackerAnnotation> nextAnnotations = _findAnnotations(dirtyState);
        final LinkedHashSet<MouseTrackerAnnotation> lastAnnotations = dirtyState.replaceAnnotations(nextAnnotations);

        handleDeviceUpdate(MouseTrackerUpdateDetails.byNewFrame(
          lastAnnotations: lastAnnotations,
          nextAnnotations: nextAnnotations,
          previousEvent: lastEvent,
        ));
      }
    });
  }
}

mixin _MouseTrackerEventMixin on BaseMouseTracker {
  // Handles device update and dispatches mouse event callbacks.
  static void _handleDeviceUpdateMouseEvents(MouseTrackerUpdateDetails details) {
    final PointerEvent previousEvent = details.previousEvent;
    final PointerEvent triggeringEvent = details.triggeringEvent;
    final PointerEvent latestEvent = details.latestEvent;

    final LinkedHashSet<MouseTrackerAnnotation> lastAnnotations = details.lastAnnotations;
    final LinkedHashSet<MouseTrackerAnnotation> nextAnnotations = details.nextAnnotations;

    // Order is important for mouse event callbacks. The `findAnnotations`
    // returns annotations in the visual order from front to back. We call
    // it the "visual order", and the opposite one "reverse visual order".
    // The algorithm here is explained in
    // https://github.com/flutter/flutter/issues/41420

    // Send exit events to annotations that are in last but not in next, in
    // visual order.
    final Iterable<MouseTrackerAnnotation> exitingAnnotations = lastAnnotations.difference(nextAnnotations);
    for (final MouseTrackerAnnotation annotation in exitingAnnotations) {
      if (annotation.onExit != null)
        annotation.onExit(PointerExitEvent.fromMouseEvent(latestEvent));
    }

    // Send enter events to annotations that are not in last but in next, in
    // reverse visual order.
    final Iterable<MouseTrackerAnnotation> enteringAnnotations =
      nextAnnotations.difference(lastAnnotations).toList().reversed;
    for (final MouseTrackerAnnotation annotation in enteringAnnotations) {
      if (annotation.onEnter != null)
        annotation.onEnter(PointerEnterEvent.fromMouseEvent(latestEvent));
    }

    // Send hover events to annotations that are in next, in reverse visual
    // order. The reverse visual order is chosen only because of the simplicity
    // by keeping the hover events aligned with enter events.
    if (triggeringEvent is PointerHoverEvent) {
      final Offset hoverPositionBeforeUpdate = previousEvent is PointerHoverEvent ? previousEvent.position : null;
      final bool pointerHasMoved = hoverPositionBeforeUpdate == null || hoverPositionBeforeUpdate != triggeringEvent.position;
      // If the hover event follows a non-hover event, or has moved since the
      // last hover, then trigger the hover callback on all annotations.
      // Otherwise, trigger the hover callback only on annotations that it
      // newly enters.
      final Iterable<MouseTrackerAnnotation> hoveringAnnotations = pointerHasMoved ? nextAnnotations.toList().reversed : enteringAnnotations;
      for (final MouseTrackerAnnotation annotation in hoveringAnnotations) {
        if (annotation.onHover != null) {
          annotation.onHover(triggeringEvent);
        }
      }
    }
  }

  @protected
  @override
  void handleDeviceUpdate(MouseTrackerUpdateDetails details) {
    super.handleDeviceUpdate(details);
    _handleDeviceUpdateMouseEvents(details);
  }
}

/// Trackes the relationship between mouse devices and annotations, and
/// triggers mouse events and cursor changes accordingly.
///
/// The [MouseTracker] trackes the relationship between mouse devices and
/// [MouseTrackerAnnotation]s, and when such relationship changes, triggers
/// the following changes if applicable:
///
///  * Dispatches mouse-related pointer events (pointer enter, hover, and exit).
///  * Notifies changes of [mouseIsConnected].
///  * Changes mouse cursors.
///
/// An instance of [MouseTracker] is owned by the global singleton of
/// [RendererBinding].
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [mouseIsConnected] changes.
///
/// See also:
///
///   * [BaseMouseTracker], which introduces more details about the timing of
///     device updates.
class MouseTracker extends BaseMouseTracker with MouseTrackerCursorMixin, _MouseTrackerEventMixin {
  /// Creates a [MouseTracker] to keep track of mouse locations.
  ///
  /// The first parameter is a [PointerRouter], which [MouseTracker] will
  /// subscribe to and receive events from. Usually it is the global singleton
  /// instance [GestureBinding.pointerRouter].
  ///
  /// The second parameter is a function with which the [MouseTracker] can
  /// search for [MouseTrackerAnnotation]s at a given position.
  /// Usually it is [Layer.findAllAnnotations] of the root layer.
  ///
  /// All of the parameters must be non-null.
  MouseTracker(
    PointerRouter router,
    MouseDetectorAnnotationFinder annotationFinder,
  ) : super(router, annotationFinder);
}

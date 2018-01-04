// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scrollable.dart';


/// A box in which widgets on a wheel can be scrolled.
///
/// This widget is similar to a [ListView] but with the restriction that all
/// children must be the same size along the scrolling axis.
///
/// When the list is at the zero scroll offset, the first child is aligned with
/// the middle of the viewport. When the list is at the final scroll offset,
/// the last child is aligned with the middle of the viewport
///
/// The children are rendered as if rotating on a wheel instead of scrolling on
/// a plane.
class ListWheelScrollView extends StatelessWidget {
  /// Creates a box in which children are scrolled on a wheel.
  const ListWheelScrollView({
    Key key,
    this.controller,
    this.physics,
    this.diameterRatio: 2.0,
    this.perspective: 0.003,
    @required this.itemExtent,
    this.clipToSize: true,
    this.renderChildrenOutsideViewport: false,
    @required this.children,
  }) : assert(diameterRatio != null && diameterRatio > 0.0),
       assert(
         perspective != null && perspective >= 0.0 && perspective < 0.01,
         'A perspective too high will be clipped in the z-axis and therefore '
         'not renderable. Value must be between 0 and 0.01.'
       ),
       assert(itemExtent != null && itemExtent > 0.0),
       assert(clipToSize != null),
       assert(renderChildrenOutsideViewport != null),
       assert(
         !renderChildrenOutsideViewport || !clipToSize,
         'Cannot renderChildrenOutsideViewport and clipToSize since children '
         'rendered outside will be clipped anyway.'
       ),
       super(key: key);

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController controller;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// {@macro flutter.widgets.wheelList.diameterRatio}
  ///
  /// Defaults to an arbitrary but aesthetically reasonable number of 2.0.
  ///
  /// Must not be null and must be positive.
  final double diameterRatio;

  /// Perspective of the cylindrical projection.
  ///
  /// A number between 0 and 0.01 where 0 means looking at the cylinder from
  /// infinitely far with an infinitely small field of view and 1 means looking
  /// at the cylinder from infinitely close with an infinitely large field of
  /// view (which cannot be rendered).
  ///
  /// Defaults to an arbitrary but aesthetically reasonable number of 0.003.
  /// A larger number brings the vanishing point closer and a smaller number
  /// pushes the vanishing point further.
  ///
  /// Must not be null.
  final double perspective;

  /// Size of all children in the main axis. Must not be null and must be
  /// positive.
  final double itemExtent;

  /// Whether to clip painted children to the inside of this scroll view.
  ///
  /// Defaults to [true]. Must not be null.
  ///
  /// If this is false and [renderChildrenOutsideViewport] is false, the
  /// first and last children may be painted partly outside of this scroll view.
  final bool clipToSize;

  /// Whether to paint children inside the viewport only.
  ///
  /// If false, every child will be painted. However the [Scrollable] is still
  /// the size of the viewport and detects gestures inside only.
  ///
  /// Defaults to [false]. Must not be null. Cannot be true if [clipToSize]
  /// is also true since children outside the viewport will be clipped, and
  /// therefore cannot render children outside the viewport.
  final bool renderChildrenOutsideViewport;

  /// List of children to scroll on top of the cylinder.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return new Scrollable(
      controller: controller,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return new _ListWheelViewport(
          diameterRatio: diameterRatio,
          perspective: perspective,
          itemExtent: itemExtent,
          clipToSize: clipToSize,
          renderChildrenOutsideViewport: renderChildrenOutsideViewport,
          offset: offset,
          children: children,
        );
      },
    );
  }
}

class _ListWheelViewport extends MultiChildRenderObjectWidget {
  _ListWheelViewport({
    Key key,
    this.diameterRatio,
    this.perspective,
    this.itemExtent,
    this.clipToSize,
    this.renderChildrenOutsideViewport,
    this.offset,
    List<Widget> children,
  }) : super(key: key, children: children);

  final double diameterRatio;
  final double perspective;
  final double itemExtent;
  final bool clipToSize;
  final bool renderChildrenOutsideViewport;
  final ViewportOffset offset;

  @override
  RenderListWheelViewport createRenderObject(BuildContext context) {
    return new RenderListWheelViewport(
      diameterRatio: diameterRatio,
      perspective: perspective,
      itemExtent: itemExtent,
      clipToSize: clipToSize,
      renderChildrenOutsideViewport: renderChildrenOutsideViewport,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderListWheelViewport renderObject) {
    renderObject
      ..diameterRatio = diameterRatio
      ..perspective = perspective
      ..itemExtent = itemExtent
      ..clipToSize = clipToSize
      ..renderChildrenOutsideViewport = renderChildrenOutsideViewport
      ..offset = offset;
  }
}

typedef double _ChildSizingFunction(RenderBox child);

class _ListWheelParentData extends ContainerBoxParentData<RenderBox> { }

/// Render, onto a wheel, a bigger sequential set of objects inside this viewport.
///
/// Takes a scrollable set of fixed sized [RenderBox]es and renders them
/// sequentially along the scrolling axis.
// Can be augmented later to have configurable axis directions.
///
/// It also starts with the first scrollable item in the center of the main axis
/// and ends with the last scrollable item in the center of the main axis. This
/// is in contrast to typical lists that starts with the first scrollable item
/// at the start of the main axis and ends with the last scrollable item at the
/// end of the main axis.
///
/// Also, instead of rendering its children on a flat plane, it renders them
/// as if each child is broken into its own plane and that plane is
/// perpendicularly fixed onto a cylinder which rotates along the scrolling
/// axis.
///
/// This class works in 3 coordinate systems:
///
/// 1- The **scrollable layout coordinates**. This coordinate system is used to
///    communicate with [ViewportOffset] and describes its children's abstract
///    offset from the beginning of the scrollable list at (0.0, 0.0).
///
///    The list is scrollable from the start of the first child item to the
///    start of the last child item.
///
///    Children's layout coordinates don't change as the viewport scrolls.
///
/// 2- The **untransformed plane's viewport painting coordinates**. Children are
///    not painted in this coordinate system. It's an abstract intermediary used
///    before transforming into the next cylindrical coordinate system.
///
///    This system is the **scrollable layout coordinates** translated by the
///    scroll offset such that (0.0, 0.0) is the top left corner of the
///    viewport.
///
///    Because the viewport is centered at the scrollable list's scroll offset
///    instead of starting at the scroll offset, there are paintable children
///    ~1/2 viewport length before and after the scroll offset instead of ~1
///    viewport length after the scroll offset.
///
///    Children's visibility inclusion in the viewport is determined in this
///    system regardless of the cylinder's properties such as [diameterRatio]
///    or [perspective]. In other words, a 100px long viewport will always
///    paint 10-11 visible 10px children if there are enough children in the
///    viewport.
///
/// 3- The **transformed cylindrical space viewport painting coordinates**.
///    Paintable children from system 2 get their positions transformed into
///    a cylindrical projection matrix instead of a cartesian offset wrt to
///    the scroll offset.
///
///    Children in this coordinate system are painted.
///
///    The wheel's size and the maximum and minimum visible angles are both
///    controlled by [diameterRatio]. Children visible in the **untransformed
///    plane's viewport painting coordinates**'s viewport will be radially
///    evenly laid out between the maximum and minimum angles determined by
///    intersecting the viewport's main axis length with a cylinder whose
///    diameter is [diameterRatio] times longer, as long as those angles are
///    between -pi/2 and pi/2.
///
///    For example, if [diameterRatio] is 2.0 and this [RenderListWheelViewport]
///    is 100.0px in the main axis, then the diameter is 200.0. And children
///    will be evenly laid out between that cylinder's -arcsin(0.5) and
///    arcsin(0.5) angles.
///
///    The cylinder's 0 degree side is always centered in the
///    [RenderListWheelViewport]. The transformation from **untransformed
///    plane's viewport painting coordinates** is also done such that the child
///    in the center of that plane will be mostly untransformed with children
///    above and below it being transformed more as the angle increases.
class RenderListWheelViewport
    extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _ListWheelParentData>,
         RenderBoxContainerDefaultsMixin<RenderBox, _ListWheelParentData>
    implements RenderAbstractViewport {
  RenderListWheelViewport({
    @required ViewportOffset offset,
    @required double diameterRatio,
    @required double perspective,
    @required double itemExtent,
    @required bool clipToSize,
    @required bool renderChildrenOutsideViewport,
    List<RenderBox> children,
  }) : assert(offset != null),
       _offset = offset,
       _diameterRatio = diameterRatio,
       _perspective = perspective,
       _itemExtent = itemExtent,
       _clipToSize = clipToSize,
       _renderChildrenOutsideViewport = renderChildrenOutsideViewport {
    addAll(children);
  }

  /// The associated ViewportOffset object for the viewport.
  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset)
      return;
    if (attached)
      _offset.removeListener(_hasScrolled);
    _offset = value;
    if (attached)
      _offset.addListener(_hasScrolled);
    markNeedsLayout();
  }

  /// {@template flutter.widgets.wheelList.diameterRatio}
  /// A ratio between the diameter of the cylinder and the viewport's size
  /// in the main axis.
  ///
  /// A value of 1 means the cylinder has the same diameter as the viewport's
  /// size.
  ///
  /// A value smaller than 1 means items at the edges of the cylinder are
  /// entirely contained inside the viewport.
  ///
  /// A value larger than 1 means angles less than +/- [math.pi] / 2 from the
  /// center of the cylinder are visible.
  ///
  /// The same number of children will be visible in the viewport regardless of
  /// the [diameterRatio]. The number of children visible is based on the
  /// viewport's length along the main axis divided by the children's
  /// [itemExtent]. Then the children are evenly distributed along the visible
  /// angles up to +/- [math.pi] / 2.
  ///
  /// Just as it's impossible to stretch a paper to cover the an entire
  /// half of a cylinder's surface where the cylinder has the same diameter
  /// as the paper's length, choosing a [diameterRatio] smaller than [math.pi]
  /// will leave same gaps between the children.
  /// {@endtemplate}
  double get diameterRatio => _diameterRatio;
  double _diameterRatio;
  set diameterRatio(double value) {
    assert(value != null);
    assert(
      value > 0,
      "You can't set a diameterRatio of 0. It would imply a cylinder of 0 "
      'diameter in which case nothing will be drawn');
    if (value == _diameterRatio)
      return;
    _diameterRatio = value;
    _hasScrolled();
  }

  /// Perspective of the cylindrical projection. See doc in
  /// [MatrixUtils.createCylindricalProjectionTransform].
  double get perspective => _perspective;
  double _perspective;
  set perspective(double value) {
    assert(value != null);
    assert(
      value <= 0.01,
      'A perspective value too high will always be clipped in the z axis and unrenderable.\n'
      'Choose a value lower than 0.01',
    );
    if (value == _perspective)
      return;
    _perspective = value;
    _hasScrolled();
  }

  /// The size of the children along the main axis. Children [RenderBox]es will
  /// be given the [BoxConstraints] to be this exact size.
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    assert(value != null);
    assert(value > 0.0);
    if (value == _itemExtent)
      return;
    _itemExtent = value;
    markNeedsLayout();
  }

  bool _clipToSize;
  set clipToSize(bool value) {
    assert(value != null);
    if (value == _clipToSize)
      return;
    _clipToSize = value;
    _hasScrolled();
  }

  bool _renderChildrenOutsideViewport;
  set renderChildrenOutsideViewport(bool value) {
    assert(value != null);
    if (value == _renderChildrenOutsideViewport)
      return;
    _renderChildrenOutsideViewport = value;
    _hasScrolled();
  }

  void _hasScrolled() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _ListWheelParentData)
      child.parentData = new _ListWheelParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_hasScrolled);
  }

  @override
  void detach() {
    _offset.removeListener(_hasScrolled);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  /// Main axis length in the untransformed plane.
  double get _viewportExtent {
    assert(hasSize);
    return size.height;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the first item in the center.
  double get _minScrollExtent {
    assert(hasSize);
    return 0.0;
  }

  /// Main axis scroll extent in the **scrollable layout coordinates** that puts
  /// the last item in the center.
  double get _maxScrollExtent {
    assert(hasSize);
    if (!(childCount > 0))
      return 0.0;

    return math.max(0.0, (childCount - 1) * _itemExtent);
  }

  /// Scroll extent distance in the untransformed plane between the center
  /// position in the viewport and the top position in the viewport.
  ///
  /// It's also the distance in the untransformed plane that children's painting
  /// is offset by wrt to those children's [BoxParentData.offset].
  double get _topScrollMarginExtent {
    assert(hasSize);
    // Consider adding an alignment configurable.
    return _minScrollExtent - size.height / 2.0 + _itemExtent / 2.0;
  }

  /// Transforms a **scrollable layout coordinates**' Y position to the
  /// **untransformed plane's viewport painting coordinates**' Y position given
  /// the current scroll offset.
  double _getUntransformedPaintingCoordinateY(double layoutCoordinateY) {
    return layoutCoordinateY - _topScrollMarginExtent - offset.pixels;
  }

  /// Children with offsets larger than this value in the **scrollable layout
  /// coordinates** can be painted.
  double get _firstVisibleLayoutOffset {
    assert(hasSize);
    if (_renderChildrenOutsideViewport)
      return double.negativeInfinity;
    return _minScrollExtent - size.height / 2.0 - _itemExtent / 2.0 + offset.pixels;
  }

  /// Children with offsets smaller than this value in the **scrollable layout
  /// coordinates** can be painted.
  double get _lastVisibleLayoutOffset {
    assert(hasSize);
    if (_renderChildrenOutsideViewport)
      return double.infinity;
    return _minScrollExtent + size.height / 2.0 + _itemExtent / 2.0 + offset.pixels;
  }

  /// Given the _diameterRatio, return the largest absolute angle of the item
  /// at the edge of the portion of the visible cylinder.
  ///
  /// For a _diameterRatio of 1 or less than 1 (i.e. the viewport is bigger
  /// than the cylinder diameter), this value reaches and clips at pi / 2.
  ///
  /// When the center of children passes this angle, they are no longer painted
  /// if renderChildrenOutsideViewport is false.
  double get _maxVisibleRadian {
    if (_diameterRatio < 1.0)
      return math.pi / 2.0;
    return math.asin(1 / _diameterRatio);
  }

  double _getIntrinsicCrossAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final _ListWheelParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
      (RenderBox child) => child.getMinIntrinsicWidth(height)
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
      (RenderBox child) => child.getMaxIntrinsicWidth(height)
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (childCount > 0)
      return childCount * _itemExtent;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (childCount > 0)
      return childCount * _itemExtent;
    return 0.0;
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll, it would shift in its parent if the parent was baseline-aligned,
  // which makes no sense.

  @override
  void performLayout() {
    double currentOffset = 0.0;
    RenderBox child = firstChild;
    final BoxConstraints innerConstraints =
        constraints.copyWith(
          minHeight: _itemExtent,
          maxHeight: _itemExtent,
          minWidth: 0.0,
        );
    while(child != null) {
      child.layout(innerConstraints, parentUsesSize: true);
      final _ListWheelParentData childParentData = child.parentData;
      // Centers the child in the cross axis. Consider making it configurable.
      final double crossPosition = size.width / 2.0 - child.size.width / 2.0;
      childParentData.offset = new Offset(crossPosition, currentOffset);
      currentOffset += _itemExtent;
      child = childParentData.nextSibling;
    }

    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(_minScrollExtent, _maxScrollExtent);
  }

  bool _shouldClipAtCurrentOffset() {
    final double highestUntransformedPaintY =
        _getUntransformedPaintingCoordinateY(0.0);
    return highestUntransformedPaintY < 0.0
        || size.height < highestUntransformedPaintY + _maxScrollExtent + _itemExtent;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (childCount > 0) {
     if (_clipToSize && _shouldClipAtCurrentOffset()) {
       context.pushClipRect(
         needsCompositing,
         offset,
         Offset.zero & size,
        _paintVisibleChildren,
       );
     } else {
        _paintVisibleChildren(context, offset);
     }
    }
  }

  /// Visits all the children until one is partially visible in the viewport.
  RenderBox _getFirstVisibleChild() {
    assert(childCount > 0);
    final double firstVisibleLayoutOffset = _firstVisibleLayoutOffset;

    RenderBox child = firstChild;
    _ListWheelParentData childParentData = child.parentData;

    while (childParentData != null
        && childParentData.offset.dy <= firstVisibleLayoutOffset) {
      child = childParentData.nextSibling;
      childParentData = child?.parentData;
    }

    return child;
  }

  /// Paints all children visible in the current viewport.
  void _paintVisibleChildren(PaintingContext context, Offset offset) {
    assert(childCount > 0);
    final double lastVisibleLayoutOffset = _lastVisibleLayoutOffset;

    RenderBox childToPaint = _getFirstVisibleChild();
    _ListWheelParentData childParentData = childToPaint?.parentData;

    while (childParentData != null
        && childParentData.offset.dy < lastVisibleLayoutOffset) {
      _paintTransformedChild(childToPaint, context, offset, childParentData.offset);
      childToPaint = childParentData.nextSibling;
      childParentData = childToPaint?.parentData;
    }
  }

  /// Takes in a child with a **scrollable layout offset** and paints it in the
  /// **transformed cylindrical space viewport painting coordinates**.
  void _paintTransformedChild(
    RenderBox child,
    PaintingContext context,
    Offset offset,
    Offset layoutOffset,
  ) {
    final Offset untransformedPaintingCoordinates = offset
        + new Offset(
            layoutOffset.dx,
            _getUntransformedPaintingCoordinateY(layoutOffset.dy)
        );

    // Get child's center as a fraction of the viewport's height.
    final double fractionalY =
        (untransformedPaintingCoordinates.dy + _itemExtent / 2.0) / size.height;
    final double angle = -(fractionalY - 0.5) * 2.0 * _maxVisibleRadian;
    // Don't paint the backside of the cylinder when
    // renderChildrenOutsideViewport is true.
    if (angle > math.pi / 2.0 || angle < -math.pi / 2.0)
      return;

    final Matrix4 transform = MatrixUtils.createCylindricalProjectionTransform(
      radius: size.height * _diameterRatio / 2.0,
      angle: angle,
      perspective: _perspective,
    );

    context.pushTransform(
      needsCompositing,
      offset,
      _centerOriginTransform(transform),
      // Pre-transform painting function.
      (PaintingContext context, Offset offset) {
        context.paintChild(
          child,
          offset + new Offset(
            untransformedPaintingCoordinates.dx,
            // Paint everything in the center (e.g. angle = 0), then transform.
            -_topScrollMarginExtent,
          ),
        );
      },
    );
  }

  /// Apply incoming transformation with the transformation's origin at the
  /// viewport's center.
  Matrix4 _centerOriginTransform(Matrix4 originalMatrix) {
    final Matrix4 result = new Matrix4.identity();
    final Offset centerOriginTranslation = Alignment.center.alongSize(size);
    result.translate(centerOriginTranslation.dx, centerOriginTranslation.dy);
    result.multiply(originalMatrix);
    result.translate(-centerOriginTranslation.dx, -centerOriginTranslation.dy);
    return result;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translate(0.0, _getUntransformedPaintingCoordinateY(0.0));
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    if (child != null && _shouldClipAtCurrentOffset()) {
      return Offset.zero & size;
    }
    return null;
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return false;
  }

  @override
  double getOffsetToReveal(RenderObject target, double alignment) {
    final _ListWheelParentData parentData = target.parentData;
    final double centerPosition = parentData.offset.dy;

    if (alignment < 0.5) {
      return centerPosition + _topScrollMarginExtent * alignment * 2.0;
    } else if (alignment > 0.5) {
      return centerPosition - _topScrollMarginExtent * (alignment - 0.5) * 2.0;
    } else {
      return centerPosition;
    }
  }

  @override
  void showOnScreen([RenderObject child]) {
    // Shows the child in the selected/center position.
    offset.jumpTo(getOffsetToReveal(child, 0.5));

    // Make sure the viewport itself is on screen.
    super.showOnScreen();
  }
}

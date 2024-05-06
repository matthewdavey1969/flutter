// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Carousel extends StatefulWidget {
  Carousel({
    super.key,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.overlayColor,
    this.itemSnapping = false,
    this.shrinkExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.onTap,
    required this.itemExtent,
    required this.children,
  }) : allowFullyExpand = null,
       layout = _CarouselLayout.uncontained,
       layoutWeights = null;

  /// multi-browse
  const Carousel.multibrowse({
    super.key,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.overlayColor,
    this.itemSnapping = false,
    this.shrinkExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.allowFullyExpand = false,
    this.onTap,
    required this.layoutWeights,
    required this.children,
  }) : layout = _CarouselLayout.multiBrowse,
       itemExtent = null;

  /// hero
  const Carousel.hero({
    super.key,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.overlayColor,
    bool centered = false,
    this.allowFullyExpand = true,
    this.itemSnapping = false,
    this.shrinkExtent,
    this.controller,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.onTap,
    required this.layoutWeights,
    required this.children,
  }) : layout = centered ? _CarouselLayout.centeredHero : _CarouselLayout.hero,
       itemExtent = null;

  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final WidgetStateProperty<Color?>? overlayColor;
  final double? shrinkExtent;
  final bool itemSnapping;
  final double? itemExtent;
  final CarouselController? controller;
  final Axis scrollDirection;
  final bool reverse;
  final bool? allowFullyExpand;
  final ValueChanged<int>? onTap;
  final _CarouselLayout layout;
  final List<int>? layoutWeights;
  final List<Widget> children;

  @override
  State<Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late double? itemExtent;
  late List<int>? weights;
  late CarouselController _controller;
  late bool? allowFullyExpand;

  @override
  void initState() {
    _updateWeights();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    allowFullyExpand = widget.allowFullyExpand;
    itemExtent = getItemExtent();
    _updateController();
  }

  @override
  void didUpdateWidget(covariant Carousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.layoutWeights != oldWidget.layoutWeights) {
      _updateWeights();
      _updateController();
    }
    if (widget.itemExtent != oldWidget.itemExtent) {
      itemExtent = getItemExtent();
    }
    if (widget.layout != oldWidget.layout) {
      allowFullyExpand = widget.allowFullyExpand;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateWeights() {
    weights = widget.layoutWeights;
    if (widget.layout == _CarouselLayout.centeredHero) {
      assert(weights != null);
      weights = List<int>.from(widget.layoutWeights!);
      final int length = weights!.length;
      final int minWeight = weights!.min;
      weights!.sort();
      weights!.insertAll(length, List<int>.filled(length - 1, minWeight));
    }
  }

  void _updateController() {
    int maxItem = 0;
    if (weights != null) {
      final int maxWeight = weights!.max;
      for (int index = 0; index < weights!.length; index++) {
        if (weights!.elementAt(index) == maxWeight) {
          maxItem = index;
          break;
        }
      }
    }

    final int initialItem = switch(widget.layout) {
      _CarouselLayout.uncontained => 0,
      _CarouselLayout.multiBrowse => 0,
      _CarouselLayout.hero || _CarouselLayout.centeredHero => maxItem,
    };

    _controller = widget.controller
      ?? CarouselController(
        initialItem: initialItem,
        itemExtent: itemExtent,
        layoutWeights: weights,
      );
  }

  AxisDirection _getDirection(BuildContext context) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        assert(debugCheckHasDirectionality(context));
        final TextDirection textDirection = Directionality.of(context);
        final AxisDirection axisDirection = textDirectionToAxisDirection(textDirection);
        return widget.reverse ? flipAxisDirection(axisDirection) : axisDirection;
      case Axis.vertical:
        return widget.reverse ? AxisDirection.up : AxisDirection.down;
    }
  }

  double? getItemExtent() {
    if (widget.itemExtent != null) {
      final double screenExtent = switch(widget.scrollDirection) {
        Axis.horizontal => MediaQuery.of(context).size.width,
        Axis.vertical => MediaQuery.of(context).size.height,
      };

      return clampDouble(widget.itemExtent!, 0, screenExtent);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AxisDirection axisDirection = _getDirection(context);
    final ScrollPhysics physics = widget.itemSnapping
      ? const CarouselScrollPhysics()
      : ScrollConfiguration.of(context).getScrollPhysics(context);

    final List<Widget> children = List<Widget>.generate(widget.children.length, (int index) {
      return Padding(
        padding: widget.padding ?? const EdgeInsets.all(4.0),
        child: Material(
          clipBehavior: Clip.antiAlias,
          color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
          elevation: widget.elevation ?? 0.0,
          shape: widget.shape ?? const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28.0))
          ),
          child: InkWell(
            onTap: () {
              widget.onTap?.call(index);
            },
            overlayColor: widget.overlayColor ?? WidgetStateProperty.resolveWith((Set<WidgetState> states) {
              if (states.contains(MaterialState.pressed)) {
                return theme.colorScheme.onSurface.withOpacity(0.1);
              }
              if (states.contains(MaterialState.hovered)) {
                return theme.colorScheme.onSurface.withOpacity(0.08);
              }
              if (states.contains(MaterialState.focused)) {
                return theme.colorScheme.onSurface.withOpacity(0.1);
              }
              return null;
            }),
            child: widget.children.elementAt(index),
          ),
        ),
      );
    });

    return Scrollable(
      axisDirection: axisDirection,
      controller: _controller,
      physics: physics,
      viewportBuilder: (BuildContext context, ViewportOffset position) {
        return Viewport(
          cacheExtent: 0.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          axisDirection: axisDirection,
          offset: position,
          clipBehavior: Clip.antiAlias,
          slivers: <Widget>[
            if (itemExtent != null) _SliverFixedExtentCarousel(
              itemExtent: itemExtent!,
              minExtent: widget.shrinkExtent ?? 0.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return children.elementAt(index);
                },
                childCount: children.length,
              ),
            ),
            if (weights != null) _SliverWeightedCarousel(
              allowFullyExpand: allowFullyExpand ?? false,
              shrinkExtent: widget.shrinkExtent ?? 0.0,
              weights: weights!,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return children.elementAt(index);
                },
                childCount: children.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SliverFixedExtentCarousel extends SliverMultiBoxAdaptorWidget {
  const _SliverFixedExtentCarousel({
    required super.delegate,
    required this.minExtent,
    required this.itemExtent,
  });

  final double itemExtent;
  final double minExtent;

  @override
  RenderSliverFixedExtentBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverFixedExtentCarousel(
      childManager: element,
      minExtent: minExtent,
      maxExtent: itemExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSliverFixedExtentCarousel renderObject) {
    renderObject.maxExtent = itemExtent;
  }
}

class _RenderSliverFixedExtentCarousel extends RenderSliverFixedExtentBoxAdaptor {
  _RenderSliverFixedExtentCarousel({
    required super.childManager,
    required double maxExtent,
    required double minExtent,
  }) : _maxExtent = maxExtent,
       _minExtent = minExtent;

  double get maxExtent => _maxExtent;
  double _maxExtent;
  set maxExtent(double value) {
    if (_maxExtent == value) {
      return;
    }
    _maxExtent = value;
    markNeedsLayout();
  }

  double get minExtent => _minExtent;
  double _minExtent;
  set minExtent(double value) {
    if (_minExtent == value) {
      return;
    }
    _minExtent = value;
    markNeedsLayout();
  }

  double _buildItemExtent(int index, SliverLayoutDimensions currentLayoutDimensions) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();
    final double shrinkExtent = constraints.scrollOffset - (constraints.scrollOffset / maxExtent).floor() * maxExtent;
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);
    if (index == firstVisibleIndex) {
      final double effectiveExtent = maxExtent - shrinkExtent;
      return math.max(effectiveExtent, effectiveMinExtent);
    }

    final double scrollOffsetForLastIndex = constraints.scrollOffset + constraints.remainingPaintExtent;
    if (index == getMaxChildIndexForScrollOffset(scrollOffsetForLastIndex, maxExtent)) {
      return clampDouble(scrollOffsetForLastIndex - maxExtent * index, effectiveMinExtent, maxExtent);
    }
    return maxExtent;
  }

  /// The layout offset for the child with the given index.
  @override
  double indexToLayoutOffset(
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
    int index,
  ) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();
    final double effectiveMinExtent = math.max(constraints.remainingPaintExtent % maxExtent, minExtent);
    if (index == firstVisibleIndex) {
      final double firstVisibleItemExtent = _buildItemExtent(index, currentLayoutDimensions);
      if (firstVisibleItemExtent <= effectiveMinExtent) {
        return maxExtent * index - effectiveMinExtent + maxExtent;
      }
      return constraints.scrollOffset;
    }
    return maxExtent * index;
  }

    /// The minimum child index that is visible at the given scroll offset.
  @override
  int getMinChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    final int firstVisibleIndex = (constraints.scrollOffset / maxExtent).floor();
    return math.max(firstVisibleIndex, 0);
  }

  @override
  int getMaxChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    if (maxExtent > 0.0) {
      final double actual = scrollOffset / maxExtent - 1;
      final int round = actual.round();
      if ((actual * maxExtent - round * maxExtent).abs() < precisionErrorTolerance) {
        return math.max(0, round);
      }
      return math.max(0, actual.ceil());
    }
    return 0;
  }

  @override
  double? get itemExtent => null;

  @override
  ItemExtentBuilder? get itemExtentBuilder => _buildItemExtent;
}

class _SliverWeightedCarousel extends SliverMultiBoxAdaptorWidget {
  const _SliverWeightedCarousel({
    required super.delegate,
    required this.allowFullyExpand,
    required this.shrinkExtent,
    required this.weights,
  });

  final bool allowFullyExpand;
  final double shrinkExtent;
  final List<int> weights;

  @override
  RenderSliverFixedExtentBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverWeightedCarousel(
      childManager: element,
      allowFullyExpand: allowFullyExpand,
      shrinkExtent: shrinkExtent,
      weights: weights,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSliverWeightedCarousel renderObject) {
    renderObject.allowFullyExpand = allowFullyExpand;
    renderObject.shrinkExtent = shrinkExtent;
    renderObject.weights = weights;
  }
}

class _RenderSliverWeightedCarousel extends RenderSliverFixedExtentBoxAdaptor {
  _RenderSliverWeightedCarousel({
    required super.childManager,
    required bool allowFullyExpand,
    required double shrinkExtent,
    required List<int> weights,
  }) : _allowFullyExpand = allowFullyExpand,
       _shrinkExtent = shrinkExtent,
       _weights = weights;

  bool get allowFullyExpand => _allowFullyExpand;
  bool _allowFullyExpand;
  set allowFullyExpand(bool value) {
    if (_allowFullyExpand == value) {
      return;
    }
    _allowFullyExpand = value;
    markNeedsLayout();
  }

  double get shrinkExtent => _shrinkExtent;
  double _shrinkExtent;
  set shrinkExtent(double value) {
    if (_shrinkExtent == value) {
      return;
    }
    _shrinkExtent = value;
    markNeedsLayout();
  }

  List<int> get weights => _weights;
  List<int> _weights;
  set weights(List<int> value) {
    if (_weights == value) {
      return;
    }
    _weights = value;
    markNeedsLayout();
  }

  double _buildItemExtent(int index, SliverLayoutDimensions currentLayoutDimensions) {
    double extent;
    if (index == _firstVisibleItemIndex) {
      extent = math.max(_distanceToLeadingEdge, effectiveShrinkExtent);
    }
    else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 <= weights.length
    ) {
      assert(index - _firstVisibleItemIndex < weights.length);
      final int currIndexOnWeightList = index - _firstVisibleItemIndex;
      final int currWeight = weights.elementAt(currIndexOnWeightList);
      extent = extentUnit * currWeight; // initial extent
      final double progress = _firstVisibleItemOffscreenExtent / firstChildExtent;

      assert(currIndexOnWeightList - 1 < weights.length, '$index');
      final int prevWeight = weights.elementAt(currIndexOnWeightList - 1);
      final double finalIncrease = (prevWeight - currWeight) / weights.max;
      extent = extent + finalIncrease * progress * maxChildExtent;
    }
    else if (index > _firstVisibleItemIndex
      && index - _firstVisibleItemIndex + 1 > weights.length)
    {
      double visibleItemsTotalExtent = _distanceToLeadingEdge;
      for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
        visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
      }
      extent = math.max(constraints.remainingPaintExtent - visibleItemsTotalExtent, effectiveShrinkExtent);
    }
    else {
      extent = math.max(minChildExtent, effectiveShrinkExtent);
    }
    return extent;
  }

  double get extentUnit => constraints.viewportMainAxisExtent / (weights.reduce((int total, int extent) => total + extent));
  double get firstChildExtent => weights.first * extentUnit;
  double get maxChildExtent => weights.max * extentUnit;
  double get minChildExtent => weights.min * extentUnit;
  double get effectiveShrinkExtent => clampDouble(shrinkExtent, 0, minChildExtent);

  int get _firstVisibleItemIndex {
    int smallerWeightCount = 0;
    for (final int weight in weights) {
      if (weight == weights.max) {
        break;
      }
      smallerWeightCount += 1;
    }
    int index;

    final double actual = constraints.scrollOffset / firstChildExtent;
    final int round = (constraints.scrollOffset / firstChildExtent).round();
    if ((actual - round).abs() < precisionErrorTolerance) {
      index = round;
    } else {
      index = actual.floor();
    }
    return allowFullyExpand ? index - smallerWeightCount : index;
  }
  double get _firstVisibleItemOffscreenExtent {
    int index;
    final double actual = constraints.scrollOffset / firstChildExtent;
    final int round = (constraints.scrollOffset / firstChildExtent).round();
    if ((actual - round).abs() < precisionErrorTolerance) {
      index = round;
    } else {
      index = actual.floor();
    }
    return constraints.scrollOffset - index * firstChildExtent;
  }
  double get _distanceToLeadingEdge => firstChildExtent - _firstVisibleItemOffscreenExtent;

  /// The layout offset for the child with the given index.
  @override
  double indexToLayoutOffset(
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
    int index,
  ) {
    if (index == _firstVisibleItemIndex) {
      if (_distanceToLeadingEdge <= effectiveShrinkExtent) {
        return constraints.scrollOffset - effectiveShrinkExtent + _distanceToLeadingEdge;
      }
      return constraints.scrollOffset;
    }
    double visibleItemsTotalExtent = _distanceToLeadingEdge;
    for (int i = _firstVisibleItemIndex + 1; i < index; i++) {
      visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
    }
    return constraints.scrollOffset + visibleItemsTotalExtent;
  }

  /// The minimum child index that is visible at the given scroll offset.
  @override
  int getMinChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    return math.max(_firstVisibleItemIndex, 0);
  }

  /// The maximum child index that is visible at the given scroll offset.
  @override
  int getMaxChildIndexForScrollOffset(
    double scrollOffset,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    final int? childCount = childManager.estimatedChildCount;
    if (childCount != null) {
      double visibleItemsTotalExtent = _distanceToLeadingEdge;
      for (int i = _firstVisibleItemIndex + 1; i < childCount; i++) {
        visibleItemsTotalExtent += _buildItemExtent(i, currentLayoutDimensions);
        if (visibleItemsTotalExtent >= constraints.viewportMainAxisExtent) {
          return i;
        }
      }
    }
    return childCount ?? 0;
  }

  ///
  @override
  double computeMaxScrollOffset(
    SliverConstraints constraints,
    @Deprecated(
      'The itemExtent is already available within the scope of this function. '
      'This feature was deprecated after v3.20.0-7.0.pre.'
    )
    double itemExtent,
  ) {
    return childManager.childCount * maxChildExtent;
  }

  BoxConstraints _getChildConstraints(int index) {
    double extent;
    extent = itemExtentBuilder!(index, currentLayoutDimensions)!;
    return constraints.asBoxConstraints(
      minExtent: extent,
      maxExtent: extent,
    );
  }

  @override
  void performLayout() {
    assert((itemExtent != null && itemExtentBuilder == null) ||
        (itemExtent == null && itemExtentBuilder != null));
    assert(itemExtentBuilder != null || (itemExtent!.isFinite && itemExtent! >= 0));

    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;
    currentLayoutDimensions = SliverLayoutDimensions(
      scrollOffset: constraints.scrollOffset,
      precedingScrollExtent: constraints.precedingScrollExtent,
      viewportMainAxisExtent: constraints.viewportMainAxisExtent,
      crossAxisExtent: constraints.crossAxisExtent
    );
    // TODO(Piinks): Clean up when deprecation expires.
    const double deprecatedExtraItemExtent = -1;

    final int firstIndex = getMinChildIndexForScrollOffset(scrollOffset, deprecatedExtraItemExtent);
    final int? targetLastIndex = targetEndScrollOffset.isFinite ?
        getMaxChildIndexForScrollOffset(targetEndScrollOffset, deprecatedExtraItemExtent) : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(firstIndex: firstIndex);
      final int trailingGarbage = targetLastIndex != null ? calculateTrailingGarbage(lastIndex: targetLastIndex) : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      final double layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      if (!addInitialChild(index: firstIndex, layoutOffset: layoutOffset)) {
        // There are either no children, or we are past the end of all our children.
        final double max;
        if (firstIndex <= 0) {
          max = 0.0;
        } else {
          max = computeMaxScrollOffset(constraints, deprecatedExtraItemExtent);
        }
        geometry = SliverGeometry(
          scrollExtent: max,
          maxPaintExtent: max,
        );
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox? trailingChildWithLayout;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final RenderBox? child = insertAndLayoutLeadingChild(_getChildConstraints(index));
      if (child == null) {
        // Items before the previously first child are no longer present.
        // Reset the scroll offset to offset all items prior and up to the
        // missing item. Let parent re-layout everything.
        geometry = SliverGeometry(scrollOffsetCorrection: indexToLayoutOffset(deprecatedExtraItemExtent, index));
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(_getChildConstraints(indexOf(firstChild!)));
      final SliverMultiBoxAdaptorParentData childParentData = firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    // From the last item to the firstly encountered max item
    double extraLayoutOffset = 0;
    if (allowFullyExpand) {
      for (int i = weights.length - 1; i >= 0; i--) {
        if (weights.elementAt(i) == weights.max) {
          break;
        }
        extraLayoutOffset += weights.elementAt(i) * extentUnit;
      }
    }

    double estimatedMaxScrollOffset = double.infinity;
    // Layout visible items after the first visible item.
    for (int index = indexOf(trailingChildWithLayout!) + 1; targetLastIndex == null || index <= targetLastIndex; ++index) {
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(_getChildConstraints(index), after: trailingChildWithLayout);
        if (child == null) {
          // We have run out of children.
          estimatedMaxScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, index) + extraLayoutOffset;
          break;
        }
      } else {
        child.layout(_getChildConstraints(index));
      }
      trailingChildWithLayout = child;
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(childParentData.index == index);
      childParentData.layoutOffset = indexToLayoutOffset(deprecatedExtraItemExtent, childParentData.index!);
    }

    final int lastIndex = indexOf(lastChild!);
    final double leadingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, firstIndex);
    double trailingScrollOffset;

    if (lastIndex + 1 == childManager.childCount) {
      trailingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, lastIndex);

      trailingScrollOffset += math.max(weights.last * extentUnit, _buildItemExtent(lastIndex, currentLayoutDimensions));
      trailingScrollOffset += extraLayoutOffset;
    } else {
      trailingScrollOffset = indexToLayoutOffset(deprecatedExtraItemExtent, lastIndex + 1);
    }

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    estimatedMaxScrollOffset = math.min(
      estimatedMaxScrollOffset,
      estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      ),
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: allowFullyExpand ? 0 : leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: allowFullyExpand ? 0 : leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double targetEndScrollOffsetForPaint = constraints.scrollOffset + constraints.remainingPaintExtent;
    final int? targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite ?
        getMaxChildIndexForScrollOffset(targetEndScrollOffsetForPaint, deprecatedExtraItemExtent) : null;

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      // Conservative to avoid flickering away the clip during scroll.
      hasVisualOverflow: (targetLastIndexForPaint != null && lastIndex >= targetLastIndexForPaint)
        || constraints.scrollOffset > 0.0,
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }

  @override
  double? get itemExtent => null;

  /// The main-axis extent builder of each item.
  ///
  /// If this is non-null, the [itemExtent] must be null.
  /// If this is null, the [itemExtent] must be non-null.
  @override
  ItemExtentBuilder? get itemExtentBuilder => _buildItemExtent;
}

enum _CarouselLayout {
  /// Show carousel items with 3 sizes. Leading items have maximum size, the
  /// second to last item has medium size and the last item has minimum size.
  multiBrowse,

  /// Carousel items have same size.
  uncontained,

  /// The hero layout shows at least one large item and one small item.
  hero,

  /// The center-aligned hero layout shows at least one large item and two small items.
  centeredHero,
}

class CarouselScrollPhysics extends ScrollPhysics {
  const CarouselScrollPhysics({super.parent});

  @override
  CarouselScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CarouselScrollPhysics(parent: buildParent(ancestor));
  }

  double _getTargetPixels(
    _CarouselPosition position,
    Tolerance tolerance,
    double velocity,
  ) {
    double fraction;
    if (position.itemExtent != null) {
      fraction = position.itemExtent! / position.viewportDimension;
    } else {
      assert(position.layoutWeights != null);
      fraction = position.layoutWeights!.first / position.layoutWeights!.sum;
    }

    final double itemWidth = position.viewportDimension * fraction;

    final double actual = math.max(0.0, position.pixels) / itemWidth;
    final double round = actual.roundToDouble();
    double item;
    if ((actual - round).abs() < precisionErrorTolerance) {
      item = round;
    }
    else {
      item = actual;
    }
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return item.roundToDouble() * itemWidth;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    assert(
      position is _CarouselPosition,
      'CarouselScrollPhysics can only be used with Scrollables that uses '
      'the CarouselController',
    );

    final _CarouselPosition metrics = position as _CarouselPosition;
    if ((velocity <= 0.0 && metrics.pixels <= metrics.minScrollExtent) ||
        (velocity >= 0.0 && metrics.pixels >= metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    final Tolerance tolerance = toleranceFor(metrics);
    final double target = _getTargetPixels(metrics, tolerance, velocity);
    if (target != metrics.pixels) {
      return ScrollSpringSimulation(
        spring,
        metrics.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => true;
}

class CarouselMetrics extends FixedScrollMetrics {
  /// Creates an immutable snapshot of values associated with a [Carousel].
  CarouselMetrics({
    required super.minScrollExtent,
    required super.maxScrollExtent,
    required super.pixels,
    required super.viewportDimension,
    required super.axisDirection,
    this.itemExtent,
    this.layoutWeights, // first item weight / total weight
    required super.devicePixelRatio,
  });

  @override
  CarouselMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    List<int>? layoutWeights,
    double? devicePixelRatio,
  }) {
    return CarouselMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      layoutWeights: layoutWeights ?? this.layoutWeights,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }

///
  final double? itemExtent;

  /// The fraction of the viewport that the first item occupies.
  ///
  /// Used to compute [item] from the current [pixels].
  final List<int>? layoutWeights;
}


class _CarouselPosition extends ScrollPositionWithSingleContext implements CarouselMetrics {
  _CarouselPosition({
    required super.physics,
    required super.context,
    this.initialItem = 0,
    // bool keepPage = true,
    double? itemExtent,
    List<int>? layoutWeights,
    super.oldPosition,
  }) : assert(layoutWeights != null && itemExtent == null
       || layoutWeights == null && itemExtent != null),
       _layoutWeights = layoutWeights,
       _itemExtent = itemExtent,
       _itemToShowOnStartup = initialItem.toDouble(),
       super(
         initialPixels: null
       );

  final int initialItem;
  double _itemToShowOnStartup;
  // When the viewport has a zero-size, the `page` can not
  // be retrieved by `getPageFromPixels`, so we need to cache the page
  // for use when resizing the viewport to non-zero next time.
  double? _cachedItem;

  @override
  List<int>? get layoutWeights => _layoutWeights;
  List<int>? _layoutWeights;
  set layoutWeights(List<int>? value) {
    if (_layoutWeights == value) {
      return;
    }
    _layoutWeights = value;
  }

  @override
  double? get itemExtent => _itemExtent;
  double? _itemExtent;
  set itemExtent(double? value) {
    if (_itemExtent == value) {
      return;
    }
    _itemExtent = value;
  }

  double getItemFromPixels(double pixels, double viewportDimension) {
    assert(viewportDimension > 0.0);
    double fraction;
    if (itemExtent != null) {
      fraction = itemExtent! / viewportDimension;
    } else { // If itemExtent is null, layoutWeights cannot be null.
      fraction = layoutWeights!.first / layoutWeights!.sum;
    }
    final double actual = math.max(0.0, pixels) / (viewportDimension * fraction);
    final double round = actual.roundToDouble();
    if ((actual - round).abs() < precisionErrorTolerance) {
      return round;
    }
    return actual;
  }

  double getPixelsFromItem(double item) {
    double fraction;
    if (itemExtent != null) {
      fraction = itemExtent! / viewportDimension;
    } else { // If itemExtent is null, layoutWeights cannot be null.
      fraction = layoutWeights!.first / layoutWeights!.sum;
    }
    return item * viewportDimension * fraction;
  }

  @override
  bool applyViewportDimension(double viewportDimension) {
    final double? oldViewportDimensions = hasViewportDimension ? this.viewportDimension : null;
    if (viewportDimension == oldViewportDimensions) {
      return true;
    }
    final bool result = super.applyViewportDimension(viewportDimension);
    final double? oldPixels = hasPixels ? pixels : null;
    double item;
    if (oldPixels == null) {
      item = _itemToShowOnStartup;
    } else if (oldViewportDimensions == 0.0) {
      // If resize from zero, we should use the _cachedItem to recover the state.
      item = _cachedItem!;
    } else {
      item = getItemFromPixels(oldPixels, oldViewportDimensions!);
    }
    final double newPixels = getPixelsFromItem(item);
    // If the viewportDimension is zero, cache the page
    // in case the viewport is resized to be non-zero.
    _cachedItem = (viewportDimension == 0.0) ? item : null;

    if (newPixels != oldPixels) {
      correctPixels(newPixels);
      return false;
    }
    return result;
  }

  @override
  CarouselMetrics copyWith({
    double? minScrollExtent,
    double? maxScrollExtent,
    double? pixels,
    double? viewportDimension,
    AxisDirection? axisDirection,
    double? itemExtent,
    List<int>? layoutWeights,
    double? devicePixelRatio,
  }) {
    return CarouselMetrics(
      minScrollExtent: minScrollExtent ?? (hasContentDimensions ? this.minScrollExtent : null),
      maxScrollExtent: maxScrollExtent ?? (hasContentDimensions ? this.maxScrollExtent : null),
      pixels: pixels ?? (hasPixels ? this.pixels : null),
      viewportDimension: viewportDimension ?? (hasViewportDimension ? this.viewportDimension : null),
      axisDirection: axisDirection ?? this.axisDirection,
      itemExtent: itemExtent ?? this.itemExtent,
      layoutWeights: layoutWeights ?? this.layoutWeights,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
    );
  }
}

class CarouselController extends ScrollController {
  /// Creates a carousel controller.
  CarouselController({
    this.initialItem = 0,
    // this.keepPage = true,
    this.itemExtent,
    this.layoutWeights,
  });

  /// The item that expands to full size when first creating the [PageView].
  final int initialItem;

  final double? itemExtent;

  /// The fraction of the viewport that the first visible carousel item should occupy.
  final List<int>? layoutWeights;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return _CarouselPosition(
      physics: physics,
      context: context,
      initialItem: initialItem,
      // keepPage: keepPage,
      itemExtent: itemExtent,
      layoutWeights: layoutWeights,
      oldPosition: oldPosition,
    );
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    final _CarouselPosition carouselPosition = position as _CarouselPosition;
    if (layoutWeights != null) {
      carouselPosition.layoutWeights = layoutWeights;
    }
    if (itemExtent != null) {
      carouselPosition.itemExtent = itemExtent;
    }
  }
}

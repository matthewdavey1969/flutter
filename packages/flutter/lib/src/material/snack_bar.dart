// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button_style.dart';
import 'color_scheme.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'material_state.dart';
import 'scaffold.dart';
import 'snack_bar_theme.dart';
import 'text_button.dart';
import 'text_button_theme.dart';
import 'theme.dart';

// Examples can assume:
// late BuildContext context;

const double _singleLineVerticalPadding = 14.0;

// TODO(ianh): We should check if the given text and actions are going to fit on
// one line or not, and if they are, use the single-line layout, and if not, use
// the multiline layout, https://github.com/flutter/flutter/issues/32782
// See https://material.io/components/snackbars#specs, 'Longer Action Text' does
// not match spec.

const Duration _snackBarTransitionDuration = Duration(milliseconds: 250);
const Duration _snackBarDisplayDuration = Duration(milliseconds: 4000);
const Curve _snackBarHeightCurve = Curves.fastOutSlowIn;
const Curve _snackBarFadeInCurve =
    Interval(0.45, 1.0, curve: Curves.fastOutSlowIn);
const Curve _snackBarFadeOutCurve =
    Interval(0.72, 1.0, curve: Curves.fastOutSlowIn);

/// Specify how a [SnackBar] was closed.
///
/// The [ScaffoldMessengerState.showSnackBar] function returns a
/// [ScaffoldFeatureController]. The value of the controller's closed property
/// is a Future that resolves to a SnackBarClosedReason. Applications that need
/// to know how a snackbar was closed can use this value.
///
/// Example:
///
/// ```dart
/// ScaffoldMessenger.of(context).showSnackBar(
///   const SnackBar(
///     content: Text('He likes me. I think he likes me.'),
///   )
/// ).closed.then((SnackBarClosedReason reason) {
///    // ...
/// });
/// ```
enum SnackBarClosedReason {
  /// The snack bar was closed after the user tapped a [SnackBarAction].
  action,

  /// The snack bar was closed through a [SemanticsAction.dismiss].
  dismiss,

  /// The snack bar was closed by a user's swipe.
  swipe,

  /// The snack bar was closed by the [ScaffoldFeatureController] close callback
  /// or by calling [ScaffoldMessengerState.hideCurrentSnackBar] directly.
  hide,

  /// The snack bar was closed by an call to [ScaffoldMessengerState.removeCurrentSnackBar].
  remove,

  /// The snack bar was closed because its timer expired.
  timeout,
}

/// A button for a [SnackBar], known as an "action".
///
/// Snack bar actions are always enabled. If you want to disable a snack bar
/// action, simply don't include it in the snack bar.
///
/// Snack bar actions can only be pressed once. Subsequent presses are ignored.
///
/// See also:
///
///  * [SnackBar]
///  * <https://material.io/design/components/snackbars.html>
class SnackBarAction extends StatefulWidget {
  /// Creates an action for a [SnackBar].
  ///
  /// The [label] and [onPressed] arguments must be non-null.
  const SnackBarAction({
    super.key,
    this.textColor,
    this.disabledTextColor,
    required this.label,
    required this.onPressed,
  })  : assert(label != null),
        assert(onPressed != null);

  /// The button label color. If not provided, defaults to
  /// [SnackBarThemeData.actionTextColor].
  ///
  /// If [textColor] is a [MaterialStateColor], then the effective text
  /// color can depend on the [MaterialState.selected] state, e.g. if the
  /// action is hovered or not.
  final Color? textColor;

  /// The button disabled label color. This color is shown after the
  /// [SnackBarAction] is dismissed.
  final Color? disabledTextColor;

  /// The button label.
  final String label;

  /// The callback to be called when the button is pressed. Must not be null.
  ///
  /// This callback will be called at most once each time this action is
  /// displayed in a [SnackBar].
  final VoidCallback onPressed;

  @override
  State<SnackBarAction> createState() => _SnackBarActionState();
}

class _SnackBarActionState extends State<SnackBarAction> {
  bool _haveTriggeredAction = false;

  void _handlePressed() {
    if (_haveTriggeredAction) {
      return;
    }
    setState(() {
      _haveTriggeredAction = true;
    });
    widget.onPressed();
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
  }

  @override
  Widget build(BuildContext context) {
    final SnackBarThemeData defaults = Theme.of(context).useMaterial3
        ? _SnackbarDefaultsM3(context)
        : _SnackbarDefaultsM2(context);
    final SnackBarThemeData snackBarTheme = Theme.of(context).snackBarTheme;

    MaterialStateColor resolveForegroundColor() {
      if (widget.textColor is MaterialStateColor) {
        return widget.textColor! as MaterialStateColor;
      }
      return MaterialStateColor.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return widget.disabledTextColor ??
              snackBarTheme.disabledActionTextColor ??
              defaults.disabledActionTextColor!;
        }
        return widget.textColor ??
            snackBarTheme.actionTextColor ??
            defaults.actionTextColor!;
      });
    }

    return TextButton(
      style: ButtonStyle(
        foregroundColor: resolveForegroundColor(),
      ),
      onPressed: _haveTriggeredAction ? null : _handlePressed,
      child: Text(widget.label),
    );
  }
}

/// An icon for a [SnackBar].
///
/// Snack bar actions are not included by default. To enable it, include the
/// [Snackbar.icon] parameter in the snack bar.
///
/// By default, snack bar icons use the Close icon.
///
/// Snack bar icons can only be pressed once. Subsequent presses are ignored.
///
/// See also:
///
///  * [SnackBar]
///  * <https://material.io/design/components/snackbars.html>
class SnackBarIcon extends StatefulWidget {
  /// Creates an icon for a [SnackBar].
  ///
  /// The [label] and [onPressed] arguments must be non-null.
  const SnackBarIcon({
    super.key,
    this.icon,
    this.onPressed,
  });

  /// The icon to use.
  ///
  /// By default, uses the Close icon.
  final Icon? icon;

  /// The callback to be called when the icon is pressed. If null,
  /// the snack bar will be dismissed with no other action.
  ///
  /// This callback will be called at most once each time this icon is
  /// displayed in a [SnackBar].
  final VoidCallback? onPressed;

  @override
  State<SnackBarIcon> createState() => _SnackBarIconState();
}

class _SnackBarIconState extends State<SnackBarIcon> {
  bool _haveTriggeredIcon = false;

  void _handlePressed() {
    if (_haveTriggeredIcon) {
      return;
    }
    setState(() {
      _haveTriggeredIcon = true;
    });
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
  }

  @override
  Widget build(BuildContext context) {
    final SnackBarThemeData defaults = Theme.of(context).useMaterial3
        ? _SnackbarDefaultsM3(context)
        : _SnackbarDefaultsM2(context);
    final SnackBarThemeData snackBarTheme = Theme.of(context).snackBarTheme;

    return IconButton(
      icon: widget.icon ?? snackBarTheme.icon ?? defaults.icon!,
      onPressed: _haveTriggeredIcon ? null : _handlePressed,
    );
  }
}

/// A lightweight message with an optional action which briefly displays at the
/// bottom of the screen.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=zpO6n_oZWw0}
///
/// To display a snack bar, call `ScaffoldMessenger.of(context).showSnackBar()`,
/// passing an instance of [SnackBar] that describes the message.
///
/// To control how long the [SnackBar] remains visible, specify a [duration].
///
/// A SnackBar with an action will not time out when TalkBack or VoiceOver are
/// enabled. This is controlled by [AccessibilityFeatures.accessibleNavigation].
///
/// During page transitions, the [SnackBar] will smoothly animate to its
/// location on the other page. For example if the [SnackBar.behavior] is set to
/// [SnackBarBehavior.floating] and the next page has a floating action button,
/// while the current one does not, the [SnackBar] will smoothly animate above
/// the floating action button. It also works in the case of a back gesture
/// transition.
///
/// {@tool dartpad}
/// Here is an example of a [SnackBar] with an [action] button implemented using
/// [SnackBarAction].
///
/// ** See code in examples/api/lib/material/snack_bar/snack_bar.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// Here is an example of a customized [SnackBar]. It utilizes
/// [behavior], [shape], [padding], [width], and [duration] to customize the
/// location, appearance, and the duration for which the [SnackBar] is visible.
///
/// ** See code in examples/api/lib/material/snack_bar/snack_bar.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ScaffoldMessenger.of], to obtain the current [ScaffoldMessengerState],
///    which manages the display and animation of snack bars.
///  * [ScaffoldMessengerState.showSnackBar], which displays a [SnackBar].
///  * [ScaffoldMessengerState.removeCurrentSnackBar], which abruptly hides the
///    currently displayed snack bar, if any, and allows the next to be displayed.
///  * [SnackBarAction], which is used to specify an [action] button to show
///    on the snack bar.
///  * [SnackBarThemeData], to configure the default property values for
///    [SnackBar] widgets.
///  * <https://material.io/design/components/snackbars.html>
class SnackBar extends StatefulWidget {
  /// Creates a snack bar.
  ///
  /// The [content] argument must be non-null. The [elevation] must be null or
  /// non-negative.
  const SnackBar({
    super.key,
    required this.content,
    this.backgroundColor,
    this.elevation,
    this.margin,
    this.padding,
    this.width,
    this.shape,
    this.behavior,
    this.action,
    this.icon,
    this.duration = _snackBarDisplayDuration,
    this.animation,
    this.onVisible,
    this.dismissDirection = DismissDirection.down,
    this.clipBehavior = Clip.hardEdge,
  })  : assert(elevation == null || elevation >= 0.0),
        assert(content != null),
        assert(
          width == null || margin == null,
          'Width and margin can not be used together',
        ),
        assert(duration != null),
        assert(clipBehavior != null);

  /// The primary content of the snack bar.
  ///
  /// Typically a [Text] widget.
  final Widget content;

  /// The snack bar's background color.
  ///
  /// If not specified, it will use [SnackBarThemeData.backgroundColor] of
  /// [ThemeData.snackBarTheme]. If that is not specified it will default to a
  /// dark variation of [ColorScheme.surface] for light themes, or
  /// [ColorScheme.onSurface] for dark themes.
  final Color? backgroundColor;

  /// The z-coordinate at which to place the snack bar. This controls the size
  /// of the shadow below the snack bar.
  ///
  /// Defines the card's [Material.elevation].
  ///
  /// If this property is null, then [SnackBarThemeData.elevation] of
  /// [ThemeData.snackBarTheme] is used, if that is also null, the default value
  /// is 6.0.
  final double? elevation;

  /// Empty space to surround the snack bar.
  ///
  /// This property is only used when [behavior] is [SnackBarBehavior.floating].
  /// It can not be used if [width] is specified.
  ///
  /// If this property is null, then the default is
  /// `EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 10.0)`.
  final EdgeInsetsGeometry? margin;

  /// The amount of padding to apply to the snack bar's content and optional
  /// action.
  ///
  /// If this property is null, the default padding values are as follows:
  ///
  /// * [content]
  ///     * Top and bottom paddings are 14.
  ///     * Left padding is 24 if [behavior] is [SnackBarBehavior.fixed],
  ///       16 if [behavior] is [SnackBarBehavior.floating].
  ///     * Right padding is same as start padding if there is no [action],
  ///       otherwise 0.
  /// * [action]
  ///     * Top and bottom paddings are 14.
  ///     * Left and right paddings are half of [content]'s left padding.
  ///
  /// If this property is not null, the padding is as follows:
  ///
  /// * [content]
  ///     * Left, top and bottom paddings are assigned normally.
  ///     * Right padding is assigned normally if there is no [action],
  ///       otherwise 0.
  /// * [action]
  ///     * Left padding is replaced with half the right padding.
  ///     * Top and bottom paddings are assigned normally.
  ///     * Right padding is replaced with one and a half times the
  ///       right padding.
  final EdgeInsetsGeometry? padding;

  /// The width of the snack bar.
  ///
  /// If width is specified, the snack bar will be centered horizontally in the
  /// available space. This property is only used when [behavior] is
  /// [SnackBarBehavior.floating]. It can not be used if [margin] is specified.
  ///
  /// If this property is null, then [SnackBarThemeData.width] of
  /// [ThemeData.snackBarTheme] is used. If that is null, the snack bar will
  /// take up the full device width less the margin.
  final double? width;

  /// The shape of the snack bar's [Material].
  ///
  /// Defines the snack bar's [Material.shape].
  ///
  /// If this property is null then [SnackBarThemeData.shape] of
  /// [ThemeData.snackBarTheme] is used. If that's null then the shape will
  /// depend on the [SnackBarBehavior]. For [SnackBarBehavior.fixed], no
  /// overriding shape is specified, so the [SnackBar] is rectangular. For
  /// [SnackBarBehavior.floating], it uses a [RoundedRectangleBorder] with a
  /// circular corner radius of 4.0.
  final ShapeBorder? shape;

  /// This defines the behavior and location of the snack bar.
  ///
  /// Defines where a [SnackBar] should appear within a [Scaffold] and how its
  /// location should be adjusted when the scaffold also includes a
  /// [FloatingActionButton] or a [BottomNavigationBar]
  ///
  /// If this property is null, then [SnackBarThemeData.behavior] of
  /// [ThemeData.snackBarTheme] is used. If that is null, then the default is
  /// [SnackBarBehavior.fixed].
  final SnackBarBehavior? behavior;

  /// (optional) An action that the user can take based on the snack bar.
  ///
  /// For example, the snack bar might let the user undo the operation that
  /// prompted the snackbar. Snack bars can have at most one action.
  ///
  /// The action should not be "dismiss" or "cancel".
  final SnackBarAction? action;

  /// (optional) An icon that the user can tap.
  ///
  /// If included, by default the icon dismisses the snack bar.
  final SnackBarIcon? icon;

  /// The amount of time the snack bar should be displayed.
  ///
  /// Defaults to 4.0s.
  ///
  /// See also:
  ///
  ///  * [ScaffoldMessengerState.removeCurrentSnackBar], which abruptly hides the
  ///    currently displayed snack bar, if any, and allows the next to be
  ///    displayed.
  ///  * <https://material.io/design/components/snackbars.html>
  final Duration duration;

  /// The animation driving the entrance and exit of the snack bar.
  final Animation<double>? animation;

  /// Called the first time that the snackbar is visible within a [Scaffold].
  final VoidCallback? onVisible;

  /// The direction in which the SnackBar can be dismissed.
  ///
  /// Cannot be null, defaults to [DismissDirection.down].
  final DismissDirection dismissDirection;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge], and must not be null.
  final Clip clipBehavior;

  // API for ScaffoldMessengerState.showSnackBar():

  /// Creates an animation controller useful for driving a snack bar's entrance and exit animation.
  static AnimationController createAnimationController(
      {required TickerProvider vsync}) {
    return AnimationController(
      duration: _snackBarTransitionDuration,
      debugLabel: 'SnackBar',
      vsync: vsync,
    );
  }

  /// Creates a copy of this snack bar but with the animation replaced with the given animation.
  ///
  /// If the original snack bar lacks a key, the newly created snack bar will
  /// use the given fallback key.
  SnackBar withAnimation(Animation<double> newAnimation, {Key? fallbackKey}) {
    return SnackBar(
      key: key ?? fallbackKey,
      content: content,
      backgroundColor: backgroundColor,
      elevation: elevation,
      margin: margin,
      padding: padding,
      width: width,
      shape: shape,
      behavior: behavior,
      action: action,
      icon: icon,
      duration: duration,
      animation: newAnimation,
      onVisible: onVisible,
      dismissDirection: dismissDirection,
      clipBehavior: clipBehavior,
    );
  }

  @override
  State<SnackBar> createState() => _SnackBarState();
}

class _SnackBarState extends State<SnackBar> {
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    widget.animation!.addStatusListener(_onAnimationStatusChanged);
  }

  @override
  void didUpdateWidget(SnackBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation!.removeStatusListener(_onAnimationStatusChanged);
      widget.animation!.addStatusListener(_onAnimationStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.animation!.removeStatusListener(_onAnimationStatusChanged);
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
      case AnimationStatus.completed:
        if (widget.onVisible != null && !_wasVisible) {
          widget.onVisible!();
        }
        _wasVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    assert(widget.animation != null);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final SnackBarThemeData snackBarTheme = theme.snackBarTheme;
    final bool isThemeDark = theme.brightness == Brightness.dark;
    final Color buttonColor =
        isThemeDark ? colorScheme.primary : colorScheme.secondary;
    final SnackBarThemeData defaults = theme.useMaterial3
        ? _SnackbarDefaultsM3(context)
        : _SnackbarDefaultsM2(context);

    // SnackBar uses a theme that is the opposite brightness from
    // the surrounding theme.
    final Brightness brightness =
        isThemeDark ? Brightness.light : Brightness.dark;

// Invert the theme values. Material 3 values are tokenzied to pre-inverted values.
    final ThemeData inverseTheme = theme.copyWith(
      colorScheme: ColorScheme(
        primary: colorScheme.onPrimary,
        primaryVariant: colorScheme.onPrimary,
        secondary: buttonColor,
        secondaryVariant: colorScheme.onSecondary,
        surface: colorScheme.onSurface,
        background: defaults.backgroundColor!,
        error: colorScheme.onError,
        onPrimary: colorScheme.primary,
        onSecondary: colorScheme.secondary,
        onSurface: colorScheme.surface,
        onBackground: colorScheme.background,
        onError: colorScheme.error,
        brightness: brightness,
      ),
    );

    final TextStyle? contentTextStyle =
        snackBarTheme.contentTextStyle ?? defaults.contentTextStyle;
    final SnackBarBehavior snackBarBehavior =
        widget.behavior ?? snackBarTheme.behavior ?? defaults.behavior!;
    final double? width = widget.width ?? snackBarTheme.width;
    assert(() {
      // Whether the behavior is set through the constructor or the theme,
      // assert that our other properties are configured properly.
      if (snackBarBehavior != SnackBarBehavior.floating) {
        String message(String parameter) {
          final String prefix =
              '$parameter can only be used with floating behavior.';
          if (widget.behavior != null) {
            return '$prefix SnackBarBehavior.fixed was set in the SnackBar constructor.';
          } else if (snackBarTheme.behavior != null) {
            return '$prefix SnackBarBehavior.fixed was set by the inherited SnackBarThemeData.';
          } else {
            return '$prefix SnackBarBehavior.fixed was set by default.';
          }
        }

        assert(widget.margin == null, message('Margin'));
        assert(width == null, message('Width'));
      }
      return true;
    }());

    final bool isFloatingSnackBar =
        snackBarBehavior == SnackBarBehavior.floating;
    final double horizontalPadding = isFloatingSnackBar ? 16.0 : 24.0;
    final EdgeInsetsGeometry padding = widget.padding ??
        EdgeInsetsDirectional.only(
            start: horizontalPadding,
            end: widget.action != null || widget.icon != null
                ? 0
                : horizontalPadding);

    final double actionHorizontalMargin =
        (widget.padding?.resolve(TextDirection.ltr).right ??
                horizontalPadding) /
            2;

    final double iconHorizontalMargin =
        (widget.padding?.resolve(TextDirection.ltr).right ??
                horizontalPadding) /
            12.0;

    final CurvedAnimation heightAnimation =
        CurvedAnimation(parent: widget.animation!, curve: _snackBarHeightCurve);
    final CurvedAnimation fadeInAnimation =
        CurvedAnimation(parent: widget.animation!, curve: _snackBarFadeInCurve);
    final CurvedAnimation fadeOutAnimation = CurvedAnimation(
      parent: widget.animation!,
      curve: _snackBarFadeOutCurve,
      reverseCurve: const Threshold(0.0),
    );

    Widget snackBar = Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: widget.padding == null
                  ? const EdgeInsets.symmetric(
                      vertical: _singleLineVerticalPadding)
                  : null,
              child: DefaultTextStyle(
                style: contentTextStyle!,
                child: widget.content,
              ),
            ),
          ),
          if (widget.action != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: actionHorizontalMargin),
              child: TextButtonTheme(
                data: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: buttonColor,
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                  ),
                ),
                child: widget.action!,
              ),
            ),
          if (widget.icon != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: iconHorizontalMargin),
              child: widget.icon,
            ),
        ],
      ),
    );

    if (!isFloatingSnackBar) {
      snackBar = SafeArea(
        top: false,
        child: snackBar,
      );
    }

    final double elevation =
        widget.elevation ?? snackBarTheme.elevation ?? defaults.elevation!;
    final Color backgroundColor = widget.backgroundColor ??
        snackBarTheme.backgroundColor ??
        defaults.backgroundColor!;
    final ShapeBorder? shape = widget.shape ??
        snackBarTheme.shape ??
        (isFloatingSnackBar ? defaults.shape : null);

    snackBar = Material(
      shape: shape,
      elevation: elevation,
      color: backgroundColor,
      child: Theme(
        data: theme.useMaterial3 ? theme : inverseTheme,
        child: mediaQueryData.accessibleNavigation
            ? snackBar
            : FadeTransition(
                opacity: fadeOutAnimation,
                child: snackBar,
              ),
      ),
    );

    if (isFloatingSnackBar) {
      const double topMargin = 5.0;
      const double bottomMargin = 10.0;
      // If width is provided, do not include horizontal margins.
      if (width != null) {
        snackBar = Container(
          margin: const EdgeInsets.only(top: topMargin, bottom: bottomMargin),
          width: width,
          child: snackBar,
        );
      } else {
        const double horizontalMargin = 15.0;
        snackBar = Padding(
          padding: widget.margin ??
              const EdgeInsets.fromLTRB(
                horizontalMargin,
                topMargin,
                horizontalMargin,
                bottomMargin,
              ),
          child: snackBar,
        );
      }
      snackBar = SafeArea(
        top: false,
        bottom: false,
        child: snackBar,
      );
    }

    snackBar = Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () {
        ScaffoldMessenger.of(context)
            .removeCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
      },
      child: Dismissible(
        key: const Key('dismissible'),
        direction: widget.dismissDirection,
        resizeDuration: null,
        onDismissed: (DismissDirection direction) {
          ScaffoldMessenger.of(context)
              .removeCurrentSnackBar(reason: SnackBarClosedReason.swipe);
        },
        child: snackBar,
      ),
    );

    final Widget snackBarTransition;
    if (mediaQueryData.accessibleNavigation) {
      snackBarTransition = snackBar;
    } else if (isFloatingSnackBar) {
      snackBarTransition = FadeTransition(
        opacity: fadeInAnimation,
        child: snackBar,
      );
    } else {
      snackBarTransition = AnimatedBuilder(
        animation: heightAnimation,
        builder: (BuildContext context, Widget? child) {
          return Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: heightAnimation.value,
            child: child,
          );
        },
        child: snackBar,
      );
    }

    return Hero(
      tag: '<SnackBar Hero tag - ${widget.content}>',
      transitionOnUserGestures: true,
      child: ClipRect(
        clipBehavior: widget.clipBehavior,
        child: snackBarTransition,
      ),
    );
  }
}

// Hand coded defaults based on Material Design 2.
class _SnackbarDefaultsM2 extends SnackBarThemeData {
  _SnackbarDefaultsM2(BuildContext context)
      : _theme = Theme.of(context),
        _colors = Theme.of(context).colorScheme;

  final ThemeData _theme;
  final ColorScheme _colors;

  @override
  double get elevation => 6.0;

  @override
  Color get backgroundColor => _theme.brightness == Brightness.light
      ? Color.alphaBlend(_colors.onSurface.withOpacity(0.80), _colors.surface)
      : _colors.onSurface;

  @override
  TextStyle? get contentTextStyle => ThemeData(
          brightness: _theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light)
      .textTheme
      .titleMedium;

  @override
  SnackBarBehavior get behavior => SnackBarBehavior.fixed;

  @override
  Color get actionTextColor => _colors.secondary;

  @override
  Color get disabledActionTextColor => _colors.onSurface
      .withOpacity(_theme.brightness == Brightness.light ? 0.38 : 0.3);

  @override
  ShapeBorder get shape => const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(4.0),
        ),
      );

  @override
  Icon get icon => Icon(
        Icons.close,
        size: 24.0,
        color: _colors.onSurface,
      );
}

// BEGIN GENERATED TOKEN PROPERTIES - Snackbar

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_137

class _SnackbarDefaultsM3 extends SnackBarThemeData {
  const _SnackbarDefaultsM3(this.context);

  final BuildContext context;

  @override
  Color get backgroundColor => Theme.of(context).colorScheme.inverseSurface;

  @override
  Color get actionTextColor =>  MaterialStateColor.resolveWith((Set<MaterialState> states) {
    if (states.contains(MaterialState.disabled)) {
      return Theme.of(context).colorScheme.inversePrimary;
    }
    if (states.contains(MaterialState.pressed)) {
      return Theme.of(context).colorScheme.inversePrimary;
    }
    if (states.contains(MaterialState.hovered)) {
      return Theme.of(context).colorScheme.inversePrimary;
    }
    if (states.contains(MaterialState.focused)) {
      return Theme.of(context).colorScheme.inversePrimary;
    }
    return Theme.of(context).colorScheme.inversePrimary;
  });

  @override
  Color get disabledActionTextColor => Theme.of(context).colorScheme.inversePrimary;


  @override
  TextStyle get contentTextStyle => Theme.of(context).textTheme.bodyMedium!.copyWith
    (color:  Theme.of(context).colorScheme.onInverseSurface);

  @override
  double get elevation => 6.0;

  @override
  ShapeBorder get shape => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));

  @override
  SnackBarBehavior get behavior => SnackBarBehavior.fixed;

  @override Icon get icon =>
      Icon(Icons.close,
      size:  24.0,
      color: _iconColor(),
    );

  Color _iconColor() {
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return Theme.of(context).colorScheme.onInverseSurface;
      }
      if (states.contains(MaterialState.hovered)) {
        return Theme.of(context).colorScheme.onInverseSurface;
      }
      if (states.contains(MaterialState.focused)) {
        return Theme.of(context).colorScheme.onInverseSurface;
      }
      return Theme.of(context).colorScheme.onInverseSurface;
    });
  }
}

// END GENERATED TOKEN PROPERTIES - Snackbar

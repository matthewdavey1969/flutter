// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon_theme_data.dart';
import 'text_theme.dart';

export 'package:flutter/services.dart' show Brightness;

// Values derived from https://developer.apple.com/design/resources/.
const _CupertinoThemeDefaults _kDefaultTheme = _CupertinoThemeDefaults(
  CupertinoColors.systemBlue,
  CupertinoColors.systemBackground,
  CupertinoDynamicColor.withBrightness(
    color: Color(0xF0F9F9F9),
    darkColor: Color(0xF01D1D1D),
    // Values extracted from navigation bar. For toolbar or tabbar the dark color is 0xF0161616.
  ),
  CupertinoColors.systemBackground,
);

/// Applies a visual styling theme to descendant Cupertino widgets.
///
/// Affects the color and text styles of Cupertino widgets whose styling
/// are not overridden when constructing the respective widgets instances.
///
/// Descendant widgets can retrieve the current [CupertinoThemeData] by calling
/// [CupertinoTheme.of]. An [InheritedWidget] dependency is created when
/// an ancestor [CupertinoThemeData] is retrieved via [CupertinoTheme.of].
///
/// The [CupertinoTheme] widget implies an [IconTheme] widget, whose
/// [IconTheme.data] has the same color as [CupertinoThemeData.primaryColor]
///
/// See also:
///
///  * [CupertinoThemeData], specifies the theme's visual styling.
///  * [CupertinoApp], which will automatically add a [CupertinoTheme] based on the
///    value of [CupertinoApp.theme].
///  * [Theme], a Material theme which will automatically add a [CupertinoTheme]
///    with a [CupertinoThemeData] derived from the Material [ThemeData].
class CupertinoTheme extends StatelessWidget {
  /// Creates a [CupertinoTheme] to change descendant Cupertino widgets' styling.
  ///
  /// The [data] and [child] parameters must not be null.
  const CupertinoTheme({
    Key? key,
    required this.data,
    required this.child,
  }) : assert(child != null),
       assert(data != null),
       super(key: key);

  /// The [CupertinoThemeData] styling for this theme.
  final CupertinoThemeData data;

  /// Retrieves the [CupertinoThemeData] from the closest ancestor [CupertinoTheme]
  /// widget, or a default [CupertinoThemeData] if no [CupertinoTheme] ancestor
  /// exists.
  ///
  /// Lazily resolves all the colors defined in that [CupertinoThemeData]
  /// against the given [BuildContext] on a best-effort basis, when they're
  /// first accessed.
  static CupertinoThemeData of(BuildContext context) {
    final _InheritedCupertinoTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return (inheritedTheme?.theme.data ?? const CupertinoThemeData()).resolveFrom(context);
  }

  /// Retrieves the [Brightness] to use for descendant Cupertino widgets, based
  /// on the value of [CupertinoThemeData.brightness] in the given [context].
  ///
  /// If no [CupertinoTheme] can be found in the given [context], or its `brightness`
  /// is null, it will fall back to [MediaQueryData.platformBrightness].
  ///
  /// Throws an exception if no valid [CupertinoTheme] or [MediaQuery] widgets
  /// exist in the ancestry tree.
  ///
  /// See also:
  ///
  /// * [maybeBrightnessOf], which returns null if no valid [CupertinoTheme] or
  ///   [MediaQuery] exists, instead of throwing.
  /// * [CupertinoThemeData.brightness], the property takes precedence over
  ///   [MediaQueryData.platformBrightness] for descendant Cupertino widgets.
  static Brightness brightnessOf(BuildContext context) {
    final _InheritedCupertinoTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return inheritedTheme?.theme.data.brightness ?? MediaQuery.of(context).platformBrightness;
  }

  /// Retrieves the [Brightness] to use for descendant Cupertino widgets, based
  /// on the value of [CupertinoThemeData.brightness] in the given [context].
  ///
  /// If no [CupertinoTheme] can be found in the given [context], it will fall
  /// back to [MediaQueryData.platformBrightness].
  ///
  /// Returns null if no valid [CupertinoTheme] or [MediaQuery] widgets exist in
  /// the ancestry tree.
  ///
  /// See also:
  ///
  /// * [CupertinoThemeData.brightness], the property takes precedence over
  ///   [MediaQueryData.platformBrightness] for descendant Cupertino widgets.
  /// * [brightnessOf], which throws if no valid [CupertinoTheme] or
  ///   [MediaQuery] exists, instead of returning null.
  static Brightness? maybeBrightnessOf(BuildContext context) {
    final _InheritedCupertinoTheme? inheritedTheme = context.dependOnInheritedWidgetOfExactType<_InheritedCupertinoTheme>();
    return inheritedTheme?.theme.data.brightness ?? MediaQuery.maybeOf(context)?.platformBrightness;
  }

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _InheritedCupertinoTheme(
      theme: this,
      child: IconTheme(
        data: CupertinoIconThemeData(color: data.primaryColor),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    data.debugFillProperties(properties);
  }
}

class _InheritedCupertinoTheme extends InheritedWidget {
  const _InheritedCupertinoTheme({
    Key? key,
    required this.theme,
    required Widget child,
  }) : assert(theme != null),
       super(key: key, child: child);

  final CupertinoTheme theme;

  @override
  bool updateShouldNotify(_InheritedCupertinoTheme old) => theme.data != old.theme.data;
}

/// Styling specifications for a [CupertinoTheme].
///
/// All constructor parameters can be null, in which case a
/// [CupertinoColors.activeBlue] based default iOS theme styling is used.
///
/// Parameters can also be partially specified, in which case some parameters
/// will cascade down to other dependent parameters to create a cohesive
/// visual effect. For instance, if a [primaryColor] is specified, it would
/// cascade down to affect some fonts in [textTheme] if [textTheme] is not
/// specified.
///
/// See also:
///
///  * [CupertinoTheme], in which this [CupertinoThemeData] is inserted.
///  * [ThemeData], a Material equivalent that also configures Cupertino
///    styling via a [CupertinoThemeData] subclass [MaterialBasedCupertinoThemeData].
@immutable
class CupertinoThemeData extends NoDefaultCupertinoThemeData with Diagnosticable {
  /// Creates a [CupertinoTheme] styling specification.
  ///
  /// Unspecified parameters default to a reasonable iOS default style.
  const CupertinoThemeData({
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
  }) : this.raw(
        brightness,
        primaryColor,
        primaryContrastingColor,
        textTheme,
        barBackgroundColor,
        scaffoldBackgroundColor,
      );

  /// Same as the default constructor but with positional arguments to avoid
  /// forgetting any and to specify all arguments.
  ///
  /// Used by subclasses to get the superclass's defaulting behaviors.
  @protected
  const CupertinoThemeData.raw(
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
  ) : this._rawWithDefaults(
    brightness,
    primaryColor,
    primaryContrastingColor,
    textTheme,
    barBackgroundColor,
    scaffoldBackgroundColor,
    _kDefaultTheme,
  );

  const CupertinoThemeData._rawWithDefaults(
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
    this._defaults,
  ) : super(
    brightness: brightness,
    primaryColor: primaryColor,
    primaryContrastingColor: primaryContrastingColor,
    textTheme: textTheme,
    barBackgroundColor: barBackgroundColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
  );

  final _CupertinoThemeDefaults _defaults;

  @override
  Color get primaryColor => super.primaryColor ?? _defaults.primaryColor;

  @override
  Color get primaryContrastingColor => super.primaryContrastingColor ?? _defaults.primaryContrastingColor;

  @override
  CupertinoTextThemeData get textTheme {
    return super.textTheme ?? CupertinoTextThemeData(primaryColor: primaryColor);
  }

  @override
  Color get barBackgroundColor => super.barBackgroundColor ?? _defaults.barBackgroundColor;

  @override
  Color get scaffoldBackgroundColor => super.scaffoldBackgroundColor ?? _defaults.scaffoldBackgroundColor;

  @override
  NoDefaultCupertinoThemeData noDefault() {
    return NoDefaultCupertinoThemeData(
      brightness: super.brightness,
      primaryColor: super.primaryColor,
      primaryContrastingColor: super.primaryContrastingColor,
      textTheme: super.textTheme,
      barBackgroundColor: super.barBackgroundColor,
      scaffoldBackgroundColor: super.scaffoldBackgroundColor,
    );
  }

  /// Returns a new theme data that lazily resolves its [CupertinoDynamicColor]
  /// attributes when accessed.
  ///
  /// Under the hood, this method returns a [CupertinoThemeData] that captures
  /// the given [BuildContext], and resolves attributes against the captured
  /// [BuildContext] when they're accessed for the first time. The results are
  /// cached, subsequent accesses to the same attribute will get the cached
  /// value. For this reason, the resulting theme data generally should not be
  /// passed to other widgets or render objects, as the captured [BuildContext]
  /// may become stale or deactivated.
  ///
  /// Called by [CupertinoTheme.of] to resolve colors defined in the retrieved
  /// [CupertinoThemeData].
  @protected
  CupertinoThemeData resolveFrom(BuildContext context) {
    return _CupertinoDynamicThemeData(baseThemeData: this, context: context);
  }

  @override
  CupertinoThemeData copyWith({
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
  }) {
    return CupertinoThemeData._rawWithDefaults(
      brightness ?? super.brightness,
      primaryColor ?? super.primaryColor,
      primaryContrastingColor ?? super.primaryContrastingColor,
      textTheme ?? super.textTheme,
      barBackgroundColor ?? super.barBackgroundColor,
      scaffoldBackgroundColor ?? super.scaffoldBackgroundColor,
      _defaults,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: null));
    properties.add(createCupertinoColorProperty('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(createCupertinoColorProperty('primaryContrastingColor', primaryContrastingColor, defaultValue: defaultData.primaryContrastingColor));
    properties.add(createCupertinoColorProperty('barBackgroundColor', barBackgroundColor, defaultValue: defaultData.barBackgroundColor));
    properties.add(createCupertinoColorProperty('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    textTheme.debugFillProperties(properties);
  }
}

class _CupertinoDynamicThemeData with Diagnosticable implements CupertinoThemeData {
  _CupertinoDynamicThemeData({
    required CupertinoThemeData baseThemeData,
    required BuildContext context,
  }) : _themeData = baseThemeData,
       _context = context;

  @override
  Brightness? get brightness => _themeData.brightness;

  @override
  _CupertinoThemeDefaults get _defaults => _themeData._defaults;
  final CupertinoThemeData _themeData;
  final BuildContext _context;

  @override
  late final Color primaryColor = CupertinoDynamicColor.resolve(_themeData.primaryColor, _context);

  @override
  late final Color primaryContrastingColor = CupertinoDynamicColor.resolve(_themeData.primaryContrastingColor, _context);

  @override
  late final CupertinoTextThemeData textTheme = _themeData.textTheme.resolveFrom(_context);

  @override
  late final Color barBackgroundColor = CupertinoDynamicColor.resolve(_themeData.barBackgroundColor, _context);

  @override
  late final Color scaffoldBackgroundColor = CupertinoDynamicColor.resolve(_themeData.scaffoldBackgroundColor, _context);

  @override
  CupertinoThemeData resolveFrom(BuildContext context) {
    return _CupertinoDynamicThemeData(baseThemeData: _themeData, context: context);
  }

  @override
  NoDefaultCupertinoThemeData noDefault() => _themeData.noDefault();

  @override
  CupertinoThemeData copyWith({
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor,
    Color? scaffoldBackgroundColor,
  }) {
    return _CupertinoDynamicThemeData(
      baseThemeData: _themeData.copyWith(
        brightness: brightness,
        primaryColor: primaryColor,
        primaryContrastingColor: primaryContrastingColor,
        textTheme: textTheme,
        barBackgroundColor: barBackgroundColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
      ),
      context: _context,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness, defaultValue: null));
    properties.add(createCupertinoColorProperty('primaryColor', primaryColor, defaultValue: defaultData.primaryColor));
    properties.add(createCupertinoColorProperty('primaryContrastingColor', primaryContrastingColor, defaultValue: defaultData.primaryContrastingColor));
    properties.add(createCupertinoColorProperty('barBackgroundColor', barBackgroundColor, defaultValue: defaultData.barBackgroundColor));
    properties.add(createCupertinoColorProperty('scaffoldBackgroundColor', scaffoldBackgroundColor, defaultValue: defaultData.scaffoldBackgroundColor));
    textTheme.debugFillProperties(properties);
  }
}


/// Styling specifications for a cupertino theme without default values for
/// unspecified properties.
///
/// Unlike [CupertinoThemeData] instances of this class do not return default
/// values for properties that have been left unspecified in the constructor.
/// Instead, unspecified properties will return null. This is used by
/// Material's [ThemeData.cupertinoOverrideTheme].
///
/// See also:
///
///  * [CupertinoThemeData], which uses reasonable default values for
///    unspecified theme properties.
class NoDefaultCupertinoThemeData {
  /// Creates a [NoDefaultCupertinoThemeData] styling specification.
  ///
  /// Unspecified properties default to null.
  const NoDefaultCupertinoThemeData({
    this.brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
  });

  /// The brightness override for Cupertino descendants.
  ///
  /// Defaults to null. If a non-null [Brightness] is specified, the value will
  /// take precedence over the ambient [MediaQueryData.platformBrightness], when
  /// determining the brightness of descendant Cupertino widgets.
  ///
  /// If coming from a Material [Theme] and unspecified, [brightness] will be
  /// derived from the Material [ThemeData]'s `brightness`.
  ///
  /// See also:
  ///
  ///  * [MaterialBasedCupertinoThemeData], a [CupertinoThemeData] that defers
  ///    [brightness] to its Material [Theme] parent if it's unspecified.
  ///
  ///  * [CupertinoTheme.brightnessOf], a method used to retrieve the overall
  ///    [Brightness] from a [BuildContext], for Cupertino widgets.
  final Brightness? brightness;

  /// A color used on interactive elements of the theme.
  ///
  /// This color is generally used on text and icons in buttons and tappable
  /// elements. Defaults to [CupertinoColors.activeBlue].
  ///
  /// If coming from a Material [Theme] and unspecified, [primaryColor] will be
  /// derived from the Material [ThemeData]'s `colorScheme.primary`. However, in
  /// iOS styling, the [primaryColor] is more sparsely used than in Material
  /// Design where the [primaryColor] can appear on non-interactive surfaces like
  /// the [AppBar] background, [TextField] borders etc.
  ///
  /// See also:
  ///
  ///  * [MaterialBasedCupertinoThemeData], a [CupertinoThemeData] that defers
  ///    [primaryColor] to its Material [Theme] parent if it's unspecified.
  final Color? primaryColor;

  /// A color that must be easy to see when rendered on a [primaryColor] background.
  ///
  /// For example, this color is used for a [CupertinoButton]'s text and icons
  /// when the button's background is [primaryColor].
  ///
  /// If coming from a Material [Theme] and unspecified, [primaryContrastingColor]
  /// will be derived from the Material [ThemeData]'s `colorScheme.onPrimary`.
  ///
  /// See also:
  ///
  ///  * [MaterialBasedCupertinoThemeData], a [CupertinoThemeData] that defers
  ///    [primaryContrastingColor] to its Material [Theme] parent if it's unspecified.
  final Color? primaryContrastingColor;

  /// Text styles used by Cupertino widgets.
  ///
  /// Derived from [primaryColor] if unspecified.
  final CupertinoTextThemeData? textTheme;

  /// Background color of the top nav bar and bottom tab bar.
  ///
  /// Defaults to a light gray in light mode, or a dark translucent gray color in
  /// dark mode.
  final Color? barBackgroundColor;

  /// Background color of the scaffold.
  ///
  /// Defaults to [CupertinoColors.systemBackground].
  final Color? scaffoldBackgroundColor;

  /// Returns an instance of the theme data whose property getters only return
  /// the construction time specifications with no derived values.
  ///
  /// Used in Material themes to let unspecified properties fallback to Material
  /// theme properties instead of iOS defaults.
  NoDefaultCupertinoThemeData noDefault() => this;

  /// Creates a copy of the theme data with specified attributes overridden.
  ///
  /// Only the current instance's specified attributes are copied instead of
  /// derived values. For instance, if the current [textTheme] is implied from
  /// the current [primaryColor] because it was not specified, copying with a
  /// different [primaryColor] will also change the copy's implied [textTheme].
  NoDefaultCupertinoThemeData copyWith({
    Brightness? brightness,
    Color? primaryColor,
    Color? primaryContrastingColor,
    CupertinoTextThemeData? textTheme,
    Color? barBackgroundColor ,
    Color? scaffoldBackgroundColor,
  }) {
    return NoDefaultCupertinoThemeData(
      brightness: brightness ?? this.brightness,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryContrastingColor: primaryContrastingColor ?? this.primaryContrastingColor,
      textTheme: textTheme ?? this.textTheme,
      barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
    );
  }
}

/// The default values of a [CupertinoThemeData].
///
/// The dynamic colors stored in this class must be resolved at the point of
/// use, to avoid declaring unnecessary dependencies on ancestor [Element]s.
/// For this reason, this class may store a [BuildContext].
@immutable
class _CupertinoThemeDefaults {
  const _CupertinoThemeDefaults(
    this.primaryColor,
    this.primaryContrastingColor,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
  );

  final Color primaryColor;
  final Color primaryContrastingColor;
  final Color barBackgroundColor;
  final Color scaffoldBackgroundColor;
}

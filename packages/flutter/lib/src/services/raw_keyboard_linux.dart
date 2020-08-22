// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter/foundation.dart';

import 'keyboard_key.dart';
import 'keyboard_maps.dart';
import 'raw_keyboard.dart';

/// Platform-specific key event data for Linux.
///
/// Different window toolkit implementations can map to different key codes. This class
/// will use the correct mapping depending on the [keyHelper] provided.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataLinux extends RawKeyEventData {
  /// Creates a key event data structure specific for Linux.
  ///
  /// The [keyHelper], [scanCode], [unicodeScalarValues], [keyCode], and [modifiers],
  /// arguments must not be null.
  const RawKeyEventDataLinux({
    required this.keyHelper,
    this.unicodeScalarValues = 0,
    this.scanCode = 0,
    this.keyCode = 0,
    this.modifiers = 0,
    required this.isDown,
  }) : assert(scanCode != null),
       assert(unicodeScalarValues != null),
       assert((unicodeScalarValues & ~LogicalKeyboardKey.valueMask) == 0),
       assert(keyCode != null),
       assert(modifiers != null),
       assert(keyHelper != null);

  /// A helper class that abstracts the fetching of the toolkit-specific mappings.
  ///
  /// There is no real concept of a "native" window toolkit on Linux, and each implementation
  /// (GLFW, GTK, QT, etc) may have a different key code mapping.
  final KeyHelper keyHelper;

  /// An int with up to two Unicode scalar values generated by a single keystroke. An assertion
  /// will fire if more than two values are encoded in a single keystroke.
  ///
  /// This is typically the character that [keyCode] would produce without any modifier keys.
  /// For dead keys, it is typically the diacritic it would add to a character. Defaults to 0,
  /// asserted to be not null.
  final int unicodeScalarValues;

  /// The hardware scan code id corresponding to this key event.
  ///
  /// These values are not reliable and vary from device to device, so this
  /// information is mainly useful for debugging.
  final int scanCode;

  /// The hardware key code corresponding to this key event.
  ///
  /// This is the physical key that was pressed, not the Unicode character.
  /// This value may be different depending on the window toolkit used. See [KeyHelper].
  final int keyCode;

  /// A mask of the current modifiers using the values in Modifier Flags.
  /// This value may be different depending on the window toolkit used. See [KeyHelper].
  final int modifiers;

  /// Whether or not this key event is a key down (true) or key up (false).
  final bool isDown;

  @override
  String get keyLabel => unicodeScalarValues == 0 ? '' : String.fromCharCode(unicodeScalarValues);

  @override
  PhysicalKeyboardKey get physicalKey => kLinuxToPhysicalKey[scanCode] ?? PhysicalKeyboardKey.none;

  @override
  LogicalKeyboardKey get logicalKey {
    // Look to see if the keyCode is a printable number pad key, so that a
    // difference between regular keys (e.g. "=") and the number pad version
    // (e.g. the "=" on the number pad) can be determined.
    final LogicalKeyboardKey? numPadKey = keyHelper.numpadKey(keyCode);
    if (numPadKey != null) {
      return numPadKey;
    }

    // If it has a non-control-character label, then either return the existing
    // constant, or construct a new Unicode-based key from it. Don't mark it as
    // autogenerated, since the label uniquely identifies an ID from the Unicode
    // plane.
    if (keyLabel.isNotEmpty &&
        !LogicalKeyboardKey.isControlCharacter(keyLabel)) {
      final int keyId = LogicalKeyboardKey.unicodePlane | (unicodeScalarValues & LogicalKeyboardKey.valueMask);
      return LogicalKeyboardKey.findKeyByKeyId(keyId) ?? LogicalKeyboardKey(
        keyId,
        keyLabel: keyLabel,
        debugName: kReleaseMode ? null : 'Key ${keyLabel.toUpperCase()}',
      );
    }

    // Look to see if the keyCode is one we know about and have a mapping for.
    LogicalKeyboardKey? newKey = keyHelper.logicalKey(keyCode);
    if (newKey != null) {
      return newKey;
    }

    const int linuxKeyIdPlane = 0x00600000000;

    // This is a non-printable key that we don't know about, so we mint a new
    // code with the autogenerated bit set.
    newKey ??= LogicalKeyboardKey(
      linuxKeyIdPlane | keyCode | LogicalKeyboardKey.autogeneratedMask,
      debugName: kReleaseMode ? null : 'Unknown key code $keyCode',
    );
    return newKey;
  }

  @override
  bool isModifierPressed(ModifierKey key, {KeyboardSide side = KeyboardSide.any}) {
    return keyHelper.isModifierPressed(key, modifiers, side: side, keyCode: keyCode, isDown: isDown);
  }

  @override
  KeyboardSide getModifierSide(ModifierKey key) {
    return keyHelper.getModifierSide(key);
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'RawKeyEventDataLinux')}(keyLabel: $keyLabel, keyCode: $keyCode, scanCode: $scanCode,'
        ' unicodeScalarValues: $unicodeScalarValues, modifiers: $modifiers, '
        'modifiers down: $modifiersPressed)';
  }
}

/// Abstract class for window-specific key mappings.
///
/// Given that there might be multiple window toolkit implementations (GLFW,
/// GTK, QT, etc), this creates a common interface for each of the
/// different toolkits.
abstract class KeyHelper {
  /// Create a KeyHelper implementation depending on the given toolkit.
  factory KeyHelper(String toolkit) {
    if (toolkit == 'glfw') {
      return GLFWKeyHelper();
    } else if (toolkit == 'gtk') {
      return GtkKeyHelper();
    } else {
      throw FlutterError('Window toolkit not recognized: $toolkit');
    }
  }

  /// Returns a [KeyboardSide] enum value that describes which side or sides of
  /// the given keyboard modifier key were pressed at the time of this event.
  KeyboardSide getModifierSide(ModifierKey key);

  /// Returns true if the given [ModifierKey] was pressed at the time of this
  /// event.
  bool isModifierPressed(ModifierKey key, int modifiers, {KeyboardSide side = KeyboardSide.any, required int keyCode, required bool isDown});

  /// The numpad key from the specific key code mapping.
  LogicalKeyboardKey? numpadKey(int keyCode);

  /// The logical key key from the specific key code mapping.
  LogicalKeyboardKey? logicalKey(int keyCode);
}

/// Helper class that uses GLFW-specific key mappings.
class GLFWKeyHelper with KeyHelper {
  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the CAPS LOCK modifier key is on.
  ///
  /// {@template flutter.services.glfwKeyHelper.modifiers}
  /// Use this value if you need to decode the [RawKeyEventDataLinux.modifiers]
  /// field yourself, but it's much easier to use [isModifierPressed] if you
  /// just want to know if a modifier is pressed. This is especially true on
  /// GLFW, since its modifiers don't include the effects of the current key
  /// event.
  /// {@endtemplate}
  static const int modifierCapsLock = 0x0010;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the SHIFT modifier keys is pressed.
  ///
  /// {@macro flutter.services.glfwKeyHelper.modifiers}
  static const int modifierShift = 0x0001;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.glfwKeyHelper.modifiers}
  static const int modifierControl = 0x0002;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the ALT modifier keys is pressed.
  ///
  /// {@macro flutter.services.glfwKeyHelper.modifiers}
  static const int modifierAlt = 0x0004;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the Meta(SUPER) modifier keys is pressed.
  ///
  /// {@macro flutter.services.glfwKeyHelper.modifiers}
  static const int modifierMeta = 0x0008;


  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether any key in the numeric keypad is pressed.
  ///
  /// {@macro flutter.services.glfwKeyHelper.modifiers}
  static const int modifierNumericPad = 0x0020;

  int _mergeModifiers({required int modifiers, required int keyCode, required bool isDown}) {
    // GLFW Key codes for modifier keys.
    const int shiftLeftKeyCode = 340;
    const int shiftRightKeyCode = 344;
    const int controlLeftKeyCode = 341;
    const int controlRightKeyCode = 345;
    const int altLeftKeyCode = 342;
    const int altRightKeyCode = 346;
    const int metaLeftKeyCode = 343;
    const int metaRightKeyCode = 347;
    const int capsLockKeyCode = 280;
    const int numLockKeyCode = 282;

    // On GLFW, the "modifiers" bitfield is the state as it is BEFORE this event
    // happened, not AFTER, like every other platform. Consequently, if this is
    // a key down, then we need to add the correct modifier bits, and if it's a
    // key up, we need to remove them.

    int modifierChange = 0;
    switch (keyCode) {
      case shiftLeftKeyCode:
      case shiftRightKeyCode:
        modifierChange = modifierShift;
        break;
      case controlLeftKeyCode:
      case controlRightKeyCode:
        modifierChange = modifierControl;
        break;
      case altLeftKeyCode:
      case altRightKeyCode:
        modifierChange = modifierAlt;
        break;
      case metaLeftKeyCode:
      case metaRightKeyCode:
        modifierChange = modifierMeta;
        break;
      case capsLockKeyCode:
        modifierChange = modifierCapsLock;
        break;
      case numLockKeyCode:
        modifierChange = modifierNumericPad;
        break;
      default:
        break;
    }

    return isDown ? modifiers | modifierChange : modifiers & ~modifierChange;
  }

  @override
  bool isModifierPressed(ModifierKey key, int modifiers, {KeyboardSide side = KeyboardSide.any, required int keyCode, required bool isDown}) {
    modifiers = _mergeModifiers(modifiers: modifiers, keyCode: keyCode, isDown: isDown);
    switch (key) {
      case ModifierKey.controlModifier:
        return modifiers & modifierControl != 0;
      case ModifierKey.shiftModifier:
        return modifiers & modifierShift != 0;
      case ModifierKey.altModifier:
        return modifiers & modifierAlt != 0;
      case ModifierKey.metaModifier:
        return modifiers & modifierMeta != 0;
      case ModifierKey.capsLockModifier:
        return modifiers & modifierCapsLock != 0;
      case ModifierKey.numLockModifier:
        return modifiers & modifierNumericPad != 0;
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
      case ModifierKey.scrollLockModifier:
        // These are not used in GLFW keyboards.
        return false;
    }
  }

  @override
  KeyboardSide getModifierSide(ModifierKey key) {
    // Neither GLFW nor X11 provide a distinction between left and right
    // modifiers, so defaults to KeyboardSide.all.
    // https://code.woboq.org/qt5/include/X11/X.h.html#_M/ShiftMask
    return KeyboardSide.all;
  }

  @override
  LogicalKeyboardKey? numpadKey(int keyCode) {
    return kGlfwNumpadMap[keyCode];
  }

  @override
  LogicalKeyboardKey? logicalKey(int keyCode) {
    return kGlfwToLogicalKey[keyCode];
  }
}

/// Helper class that uses GTK-specific key mappings.
class GtkKeyHelper with KeyHelper {
  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the SHIFT modifier keys is pressed.
  ///
  /// {@template flutter.services.gtkKeyHelper.modifiers}
  /// Use this value if you need to decode the [RawKeyEventDataLinux.modifiers] field yourself, but
  /// it's much easier to use [isModifierPressed] if you just want to know if a
  /// modifier is pressed. This is especially true on GTK, since its modifiers
  /// don't include the effects of the current key event.
  /// {@endtemplate}
  static const int modifierShift = 1 << 0;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the CAPS LOCK modifier key is on.
  ///
  /// {@macro flutter.services.gtkKeyHelper.modifiers}
  static const int modifierCapsLock = 1 << 1;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.gtkKeyHelper.modifiers}
  static const int modifierControl = 1 << 2;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the first modifier key is pressed (usually mapped to alt).
  ///
  /// {@macro flutter.services.gtkKeyHelper.modifiers}
  static const int modifierMod1 = 1 << 3;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether the second modifier key is pressed (assumed to be mapped to
  /// num lock).
  ///
  /// {@macro flutter.services.gtkKeyHelper.modifiers}
  static const int modifierMod2 = 1 << 4;

  /// This mask is used to check the [RawKeyEventDataLinux.modifiers] field to
  /// test whether one of the Meta(SUPER) modifier keys is pressed.
  ///
  /// {@macro flutter.services.gtkKeyHelper.modifiers}
  static const int modifierMeta = 1 << 28;

  int _mergeModifiers({required int modifiers, required int keyCode, required bool isDown}) {
    // GTK Key codes for modifier keys.
    const int shiftLeftKeyCode = 0xffe1;
    const int shiftRightKeyCode = 0xffe2;
    const int controlLeftKeyCode = 0xffe3;
    const int controlRightKeyCode = 0xffe4;
    const int capsLockKeyCode = 0xffe5;
    const int shiftLockKeyCode = 0xffe6;
    const int metaLeftKeyCode = 0xffe7;
    const int metaRightKeyCode = 0xffe8;
    const int altLeftKeyCode = 0xffe9;
    const int altRightKeyCode = 0xffea;
    const int numLockKeyCode = 0xff7f;

    // On GTK, the "modifiers" bitfield is the state as it is BEFORE this event
    // happened, not AFTER, like every other platform. Consequently, if this is
    // a key down, then we need to add the correct modifier bits, and if it's a
    // key up, we need to remove them.

    int modifierChange = 0;
    switch (keyCode) {
      case shiftLeftKeyCode:
      case shiftRightKeyCode:
        modifierChange = modifierShift;
        break;
      case controlLeftKeyCode:
      case controlRightKeyCode:
        modifierChange = modifierControl;
        break;
      case altLeftKeyCode:
      case altRightKeyCode:
        modifierChange = modifierMod1;
        break;
      case metaLeftKeyCode:
      case metaRightKeyCode:
        modifierChange = modifierMeta;
        break;
      case capsLockKeyCode:
      case shiftLockKeyCode:
        modifierChange = modifierCapsLock;
        break;
      case numLockKeyCode:
        modifierChange = modifierMod2;
        break;
      default:
        break;
    }

    return isDown ? modifiers | modifierChange : modifiers & ~modifierChange;
  }

  @override
  bool isModifierPressed(ModifierKey key, int modifiers, {KeyboardSide side = KeyboardSide.any, required int keyCode, required bool isDown}) {
    modifiers = _mergeModifiers(modifiers: modifiers, keyCode: keyCode, isDown: isDown);
    switch (key) {
      case ModifierKey.controlModifier:
        return modifiers & modifierControl != 0;
      case ModifierKey.shiftModifier:
        return modifiers & modifierShift != 0;
      case ModifierKey.altModifier:
        return modifiers & modifierMod1 != 0;
      case ModifierKey.metaModifier:
        return modifiers & modifierMeta != 0;
      case ModifierKey.capsLockModifier:
        return modifiers & modifierCapsLock != 0;
      case ModifierKey.numLockModifier:
        return modifiers & modifierMod2 != 0;
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
      case ModifierKey.scrollLockModifier:
        // These are not used in GTK keyboards.
        return false;
    }
  }

  @override
  KeyboardSide getModifierSide(ModifierKey key) {
    // Neither GTK nor X11 provide a distinction between left and right
    // modifiers, so defaults to KeyboardSide.all.
    // https://code.woboq.org/qt5/include/X11/X.h.html#_M/ShiftMask
    return KeyboardSide.all;
  }

  @override
  LogicalKeyboardKey? numpadKey(int keyCode) {
    return kGtkNumpadMap[keyCode];
  }

  @override
  LogicalKeyboardKey? logicalKey(int keyCode) {
    return kGtkToLogicalKey[keyCode];
  }
}

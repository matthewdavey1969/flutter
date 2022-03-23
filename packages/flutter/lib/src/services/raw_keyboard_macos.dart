// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'keyboard_key.dart';
import 'keyboard_maps.dart';
import 'raw_keyboard.dart';

/// Convert a UTF32 rune to its lower case.
int runeToLowerCase(int rune) {
  // Assume only Basic Multilingual Plane runes have lower and upper cases.
  // For other characters, return them as is.
  const int utf16BmpUpperBound = 0xD7FF;
  if (rune > utf16BmpUpperBound) return rune;
  return String.fromCharCode(rune).toLowerCase().codeUnitAt(0);
}

/// Platform-specific key event data for macOS.
///
/// This object contains information about key events obtained from macOS's
/// `NSEvent` interface.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataMacOs extends RawKeyEventData {
  /// Creates a key event data structure specific for macOS.
  ///
  /// The [characters], [charactersIgnoringModifiers], and [modifiers], arguments
  /// must not be null.
  const RawKeyEventDataMacOs({
    this.characters = '',
    this.charactersIgnoringModifiers = '',
    this.keyCode = 0,
    this.modifiers = 0,
  })  : assert(characters != null),
        assert(charactersIgnoringModifiers != null),
        assert(keyCode != null),
        assert(modifiers != null);

  /// The Unicode characters associated with a key-up or key-down event.
  ///
  /// See also:
  ///
  ///  * [Apple's NSEvent documentation](https://developer.apple.com/documentation/appkit/nsevent/1534183-characters?language=objc)
  final String characters;

  /// The characters generated by a key event as if no modifier key (except for
  /// Shift) applies.
  ///
  /// See also:
  ///
  ///  * [Apple's NSEvent documentation](https://developer.apple.com/documentation/appkit/nsevent/1524605-charactersignoringmodifiers?language=objc)
  final String charactersIgnoringModifiers;

  /// The virtual key code for the keyboard key associated with a key event.
  ///
  /// See also:
  ///
  ///  * [Apple's NSEvent documentation](https://developer.apple.com/documentation/appkit/nsevent/1534513-keycode?language=objc)
  final int keyCode;

  /// A mask of the current modifiers using the values in Modifier Flags.
  ///
  /// See also:
  ///
  ///  * [Apple's NSEvent documentation](https://developer.apple.com/documentation/appkit/nsevent/1535211-modifierflags?language=objc)
  final int modifiers;

  @override
  String get keyLabel => charactersIgnoringModifiers;

  @override
  PhysicalKeyboardKey get physicalKey =>
      kMacOsToPhysicalKey[keyCode] ??
      PhysicalKeyboardKey(LogicalKeyboardKey.windowsPlane + keyCode);

  @override
  LogicalKeyboardKey get logicalKey {
    // Look to see if the keyCode is a printable number pad key, so that a
    // difference between regular keys (e.g. "=") and the number pad version
    // (e.g. the "=" on the number pad) can be determined.
    final LogicalKeyboardKey? numPadKey = kMacOsNumPadMap[keyCode];
    if (numPadKey != null) {
      return numPadKey;
    }

    // Keys that can't be derived with characterIgnoringModifiers will be
    // derived from their key codes using this map.
    final LogicalKeyboardKey? knownKey = kMacOsToLogicalKey[keyCode];
    if (knownKey != null) {
      return knownKey;
    }

    // If this key is a single printable character, generate the
    // LogicalKeyboardKey from its Unicode value. Control keys such as ESC,
    // CTRL, and SHIFT are not printable. HOME, DEL, arrow keys, and function
    // keys are considered modifier function keys, which generate invalid
    // Unicode scalar values. Multi-char characters are also discarded.
    int? character;
    if (keyLabel.isNotEmpty) {
      final List<int> codePoints = keyLabel.runes.toList();
      if (codePoints.length == 1 &&
          // Ideally we should test whether `codePoints[0]` is in the range.
          // Since LogicalKeyboardKey.isControlCharacter and _isUnprintableKey
          // only tests BMP, it is fine to test keyLabel instead.
          !LogicalKeyboardKey.isControlCharacter(keyLabel) &&
          !_isUnprintableKey(keyLabel)) {
        character = runeToLowerCase(codePoints[0]);
      }
    }
    if (character != null) {
      final int keyId = LogicalKeyboardKey.unicodePlane |
          (character & LogicalKeyboardKey.valueMask);
      return LogicalKeyboardKey.findKeyByKeyId(keyId) ??
          LogicalKeyboardKey(keyId);
    }

    // This is a non-printable key that we don't know about, so we mint a new
    // code.
    return LogicalKeyboardKey(keyCode | LogicalKeyboardKey.macosPlane);
  }

  bool _isLeftRightModifierPressed(
      KeyboardSide side, int anyMask, int leftMask, int rightMask) {
    if (modifiers & anyMask == 0) {
      return false;
    }
    // If only the "anyMask" bit is set, then we respond true for requests of
    // whether either left or right is pressed. Handles the case where macOS
    // supplies just the "either" modifier flag, but not the left/right flag.
    // (e.g. modifierShift but not modifierLeftShift).
    final bool anyOnly =
        modifiers & (leftMask | rightMask | anyMask) == anyMask;
    switch (side) {
      case KeyboardSide.any:
        return true;
      case KeyboardSide.all:
        return modifiers & leftMask != 0 && modifiers & rightMask != 0 ||
            anyOnly;
      case KeyboardSide.left:
        return modifiers & leftMask != 0 || anyOnly;
      case KeyboardSide.right:
        return modifiers & rightMask != 0 || anyOnly;
    }
  }

  @override
  bool isModifierPressed(ModifierKey key,
      {KeyboardSide side = KeyboardSide.any}) {
    final int independentModifier = modifiers & deviceIndependentMask;
    final bool result;
    switch (key) {
      case ModifierKey.controlModifier:
        result = _isLeftRightModifierPressed(
            side,
            independentModifier & modifierControl,
            modifierLeftControl,
            modifierRightControl);
        break;
      case ModifierKey.shiftModifier:
        result = _isLeftRightModifierPressed(
            side,
            independentModifier & modifierShift,
            modifierLeftShift,
            modifierRightShift);
        break;
      case ModifierKey.altModifier:
        result = _isLeftRightModifierPressed(
            side,
            independentModifier & modifierOption,
            modifierLeftOption,
            modifierRightOption);
        break;
      case ModifierKey.metaModifier:
        result = _isLeftRightModifierPressed(
            side,
            independentModifier & modifierCommand,
            modifierLeftCommand,
            modifierRightCommand);
        break;
      case ModifierKey.capsLockModifier:
        result = independentModifier & modifierCapsLock != 0;
        break;
      // On macOS, the function modifier bit is set for any function key, like F1,
      // F2, etc., but the meaning of ModifierKey.modifierFunction in Flutter is
      // that of the Fn modifier key, so there's no good way to emulate that on
      // macOS.
      case ModifierKey.functionModifier:
      case ModifierKey.numLockModifier:
      case ModifierKey.symbolModifier:
      case ModifierKey.scrollLockModifier:
        // These modifier masks are not used in macOS keyboards.
        result = false;
        break;
    }
    assert(!result || getModifierSide(key) != null,
        "$runtimeType thinks that a modifier is pressed, but can't figure out what side it's on.");
    return result;
  }

  @override
  KeyboardSide? getModifierSide(ModifierKey key) {
    KeyboardSide? findSide(int anyMask, int leftMask, int rightMask) {
      final int combinedMask = leftMask | rightMask;
      final int combined = modifiers & combinedMask;
      if (combined == leftMask) {
        return KeyboardSide.left;
      } else if (combined == rightMask) {
        return KeyboardSide.right;
      } else if (combined == combinedMask ||
          modifiers & (combinedMask | anyMask) == anyMask) {
        // Handles the case where macOS supplies just the "either" modifier
        // flag, but not the left/right flag. (e.g. modifierShift but not
        // modifierLeftShift), or if left and right flags are provided, but not
        // the "either" modifier flag.
        return KeyboardSide.all;
      }
      return null;
    }

    switch (key) {
      case ModifierKey.controlModifier:
        return findSide(
            modifierControl, modifierLeftControl, modifierRightControl);
      case ModifierKey.shiftModifier:
        return findSide(modifierShift, modifierLeftShift, modifierRightShift);
      case ModifierKey.altModifier:
        return findSide(
            modifierOption, modifierLeftOption, modifierRightOption);
      case ModifierKey.metaModifier:
        return findSide(
            modifierCommand, modifierLeftCommand, modifierRightCommand);
      case ModifierKey.capsLockModifier:
      case ModifierKey.numLockModifier:
      case ModifierKey.scrollLockModifier:
      case ModifierKey.functionModifier:
      case ModifierKey.symbolModifier:
        return KeyboardSide.all;
    }
  }

  @override
  bool shouldDispatchEvent() {
    // On macOS laptop keyboards, the fn key is used to generate home/end and
    // f1-f12, but it ALSO generates a separate down/up event for the fn key
    // itself. Other platforms hide the fn key, and just produce the key that
    // it is combined with, so to keep it possible to write cross platform
    // code that looks at which keys are pressed, the fn key is ignored on
    // macOS.
    return logicalKey != LogicalKeyboardKey.fn;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('characters', characters));
    properties.add(DiagnosticsProperty<String>(
        'charactersIgnoringModifiers', charactersIgnoringModifiers));
    properties.add(DiagnosticsProperty<int>('keyCode', keyCode));
    properties.add(DiagnosticsProperty<int>('modifiers', modifiers));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is RawKeyEventDataMacOs &&
        other.characters == characters &&
        other.charactersIgnoringModifiers == charactersIgnoringModifiers &&
        other.keyCode == keyCode &&
        other.modifiers == modifiers;
  }

  @override
  int get hashCode => Object.hash(
        characters,
        charactersIgnoringModifiers,
        keyCode,
        modifiers,
      );

  /// Returns true if the given label represents an unprintable key.
  ///
  /// Examples of unprintable keys are "NSUpArrowFunctionKey = 0xF700"
  /// or "NSHomeFunctionKey = 0xF729".
  ///
  /// See <https://developer.apple.com/documentation/appkit/1535851-function-key_unicodes?language=objc> for more
  /// information.
  ///
  /// Used by [RawKeyEvent] subclasses to help construct IDs.
  static bool _isUnprintableKey(String label) {
    if (label.length != 1) {
      return false;
    }
    final int codeUnit = label.codeUnitAt(0);
    return codeUnit >= 0xF700 && codeUnit <= 0xF8FF;
  }

  // Modifier key masks. See Apple's NSEvent documentation
  // https://developer.apple.com/documentation/appkit/nseventmodifierflags?language=objc
  // https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-86/IOHIDSystem/IOKit/hidsystem/IOLLEvent.h.auto.html

  /// This mask is used to check the [modifiers] field to test whether the CAPS
  /// LOCK modifier key is on.
  ///
  /// {@template flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  /// Use this value if you need to decode the [modifiers] field yourself, but
  /// it's much easier to use [isModifierPressed] if you just want to know if
  /// a modifier is pressed.
  /// {@endtemplate}
  static const int modifierCapsLock = 0x10000;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// SHIFT modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierShift = 0x20000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// SHIFT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierLeftShift = 0x02;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// SHIFT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierRightShift = 0x04;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// CTRL modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierControl = 0x40000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// CTRL modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierLeftControl = 0x01;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// CTRL modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierRightControl = 0x2000;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// ALT modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierOption = 0x80000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// ALT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierLeftOption = 0x20;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// ALT modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierRightOption = 0x40;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// CMD modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierCommand = 0x100000;

  /// This mask is used to check the [modifiers] field to test whether the left
  /// CMD modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierLeftCommand = 0x08;

  /// This mask is used to check the [modifiers] field to test whether the right
  /// CMD modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierRightCommand = 0x10;

  /// This mask is used to check the [modifiers] field to test whether any key in
  /// the numeric keypad is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierNumericPad = 0x200000;

  /// This mask is used to check the [modifiers] field to test whether the
  /// HELP modifier key is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierHelp = 0x400000;

  /// This mask is used to check the [modifiers] field to test whether one of the
  /// FUNCTION modifier keys is pressed.
  ///
  /// {@macro flutter.services.RawKeyEventDataMacOs.modifierCapsLock}
  static const int modifierFunction = 0x800000;

  /// Used to retrieve only the device-independent modifier flags, allowing
  /// applications to mask off the device-dependent modifier flags, including
  /// event coalescing information.
  static const int deviceIndependentMask = 0xffff0000;
}

// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'common.dart';

/// TODOC
class GLFWMouseCursorConstants {
  // Must be kept in sync with
  // https://www.glfw.org/docs/latest/group__shapes.html

  static const int GLFW_ARROW_CURSOR = 0x00036001;

  static const int GLFW_IBEAM_CURSOR = 0x00036002;

  static const int GLFW_HAND_CURSOR = 0x00036004;
}

/// TODOC
@immutable
class _GLFWMouseCursorActions {
  /// TODOC
  const _GLFWMouseCursorActions(this.mouseCursorChannel);

  /// TODOC
  final MethodChannel mouseCursorChannel;

  /// TODOC
  Future<void> setDeviceAsSystemCursor({
    @required int device,
    @required int systemConstant,
    @required bool hidden,
  }) {
    assert(device != null);
    assert(systemConstant != null);
    assert(hidden != null);
    return mouseCursorChannel.invokeMethod<void>(
      'setDeviceAsSystemCursor',
      <String, dynamic>{
        'device': device,
        'systemConstant': systemConstant,
        'hidden': hidden,
      },
    );
  }
}

/// TODOC
class MouseCursorGLFWDelegate extends MouseCursorPlatformDelegate {
  /// TODOC
  MouseCursorGLFWDelegate(this._mouseCursorChannel);

  final MethodChannel _mouseCursorChannel;

  Future<bool> _activateSystemConstant({
    @required ActivateMouseCursorDetails details,
    @required int systemConstant,
  }) async {
    await _GLFWMouseCursorActions(_mouseCursorChannel)
      .setDeviceAsSystemCursor(
        device: details.device,
        systemConstant: systemConstant,
        hidden: false,
      );
    // This action is asserted to be successful. If not, throw the error.
    return true;
  }

  Future<bool> _hideCursor({
    @required ActivateMouseCursorDetails details,
  }) async {
    await _GLFWMouseCursorActions(_mouseCursorChannel)
      .setDeviceAsSystemCursor(
        device: details.device,
        systemConstant: 0,
        hidden: true,
      );
    // This action is asserted to be successful. If not, throw the error.
    return true;
  }

  @override
  Future<bool> activateSystemCursor(
    ActivateMouseCursorDetails details,
    SystemCursorShape shape,
  ) async {
    switch (shape) {
      case SystemCursorShape.none:
        return _hideCursor(
          details: details,
        );
      case SystemCursorShape.basic:
        return _activateSystemConstant(
          details: details,
          systemConstant: GLFWMouseCursorConstants.GLFW_ARROW_CURSOR,
        );
      case SystemCursorShape.click:
        return _activateSystemConstant(
          details: details,
          systemConstant: GLFWMouseCursorConstants.GLFW_HAND_CURSOR,
        );
      case SystemCursorShape.text:
        return _activateSystemConstant(
          details: details,
          systemConstant: GLFWMouseCursorConstants.GLFW_IBEAM_CURSOR,
        );
      case SystemCursorShape.forbidden:
        return false;
      case SystemCursorShape.grab:
        return activateSystemCursor(details, SystemCursorShape.click);
      case SystemCursorShape.grabbing:
        return activateSystemCursor(details, SystemCursorShape.click);
    }
    return false;
  }
}

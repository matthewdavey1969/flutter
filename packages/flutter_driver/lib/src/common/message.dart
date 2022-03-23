// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// An object sent from the Flutter Driver to a Flutter application to instruct
/// the application to perform a task.
abstract class Command {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Command({this.timeout});

  /// Deserializes this command from the value generated by [serialize].
  Command.deserialize(Map<String, String> json) : timeout = _parseTimeout(json);

  static Duration? _parseTimeout(Map<String, String> json) {
    final String? timeout = json['timeout'];
    if (timeout == null) return null;
    return Duration(milliseconds: int.parse(timeout));
  }

  /// The maximum amount of time to wait for the command to complete.
  ///
  /// Defaults to no timeout, because it is common for operations to take oddly
  /// long in test environments (e.g. because the test host is overloaded), and
  /// having timeouts essentially means having race conditions.
  final Duration? timeout;

  /// Identifies the type of the command object and of the handler.
  String get kind;

  /// Whether this command requires the widget tree to be initialized before
  /// the command may be run.
  ///
  /// This defaults to true to force the application under test to call [runApp]
  /// before attempting to remotely drive the application. Subclasses may
  /// override this to return false if they allow invocation before the
  /// application has started.
  ///
  /// See also:
  ///
  ///  * [WidgetsBinding.isRootWidgetAttached], which indicates whether the
  ///    widget tree has been initialized.
  bool get requiresRootWidgetAttached => true;

  /// Serializes this command to parameter name/value pairs.
  @mustCallSuper
  Map<String, String> serialize() {
    final Map<String, String> result = <String, String>{
      'command': kind,
    };
    if (timeout != null) result['timeout'] = '${timeout!.inMilliseconds}';
    return result;
  }
}

/// An object sent from a Flutter application back to the Flutter Driver in
/// response to a command.
abstract class Result {
  /// A const constructor to allow subclasses to be const.
  const Result();

  /// An empty responds that does not include any result data.
  ///
  /// Consider using this object as a result for [Command]s that do not return
  /// any data.
  static const Result empty = _EmptyResult();

  /// Serializes this message to a JSON map.
  Map<String, dynamic> toJson();
}

class _EmptyResult extends Result {
  const _EmptyResult();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};
}

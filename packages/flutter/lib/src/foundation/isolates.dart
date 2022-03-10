// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '_isolates_io.dart'
  if (dart.library.html) '_isolates_web.dart' as isolates;

/// Signature for the callback passed to [compute].
///
/// {@macro flutter.foundation.compute.types}
///
/// Instances of [ComputeCallback] must be sendable between isolates i.e.
/// top-level functions, static methods or a closures that only capture objects
/// sendable between isolates or an instance methods which instance properties
/// are also sendable.
///
/// {@macro flutter.foundation.compute.limitations}
typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

/// The signature of [compute], which spawns an isolate, runs `callback` on
/// that isolate, passes it `message`, and (eventually) returns the value
/// returned by `callback`.
///
/// This is useful for operations that take longer than a few milliseconds, and
/// which would therefore risk skipping frames. For tasks that will only take a
/// few milliseconds, consider [SchedulerBinding.scheduleTask] instead.
///
/// {@template flutter.foundation.compute.types}
/// The [compute] method accepts the following parameters:
///
///  * `Q` is the type of the message that kicks off the computation.
///
///  * `R` is the type of the value returned.
/// {@endtemplate}
///
/// The `callback` must be sendable between isolates i.e. a top-level function,
/// static method or a closure that only captures objects sendable between
/// isolates or an instance method which instance properties are also sendable.
///
/// {@template flutter.foundation.compute.limitations}
/// There are limitations on the values that can be sent and received to and
/// from isolates. These limitations constrain the values of `Q` and `R` that
/// are possible. See the discussion at [SendPort.send].
///
/// The same limitations apply to any errors generated by the computation.
/// {@endtemplate}
///
/// The `debugLabel` argument can be specified to provide a name to add to the
/// [Timeline]. This is useful when profiling an application.
typedef ComputeImpl = Future<R> Function<Q, R>(ComputeCallback<Q, R> callback, Q message, { String? debugLabel });

/// A function that spawns an isolate and runs a callback on that isolate. This
/// method should be used to execute parallel tasks that reduce the risk of
/// skipping frames.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=5AxWC49ZMzs}
///
/// See also:
///
///   * [ComputeImpl], for function parameters and usage details.
///   * [Isolate.run], for an alternative version of this function without
///                    tracting information
const ComputeImpl compute = isolates.compute;

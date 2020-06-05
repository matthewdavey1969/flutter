// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'percentile_utils.dart';
import 'timeline.dart';

/// The catrgory shared by all profiling related timeline events.
const String kProfilingCategory = 'flutter::profiling';

// These field names need to be in-sync with:
// https://github.com/flutter/engine/blob/master/shell/profiling/sampling_profiler.cc
const String _kCpuProfile = 'CpuUsage';
const String _kGpuProfile = 'GpuUsage';
const String _kMemoryProfile = 'MemoryUsage';

/// Represents the supported profiling event types.
enum ProfileType {
  /// Profiling events corresponding to CPU usage.
  CPU,

  /// Profiling events corresponding to GPU usage.
  GPU,

  /// Profiling events corresponding to memory usage.
  Memory,
}

/// Summarizes [TimelineEvents]s corresponding to [kProfilingCategory] category.
///
/// A sample event (some fields have been omitted for brewity):
/// ```
///     {
///      "category": "flutter::profiling",
///      "name": "CpuUsage",
///      "ts": 121120,
///      "args": {
///        "total_cpu_usage": "20.5",
///        "num_threads": "6"
///      }
///    },
/// ```
/// This class provides methods to compute the average and percentile information
/// for supported profiles, i.e, CPU, Memory and GPU. Not all of these exist for
/// all the platforms.
class ProfilingSummarizer {
  ProfilingSummarizer._(this.eventByType);

  /// Creates a ProfilingSummarizer given the timeline events.
  static ProfilingSummarizer fromEvents(List<TimelineEvent> profilingEvents) {
    final Map<ProfileType, List<TimelineEvent>> eventByType =
        <ProfileType, List<TimelineEvent>>{};
    for (final TimelineEvent event in profilingEvents) {
      assert(event.category == kProfilingCategory);
      final ProfileType type = _getProfileType(event.name);
      if (eventByType.containsKey(type)) {
        eventByType[type].add(event);
      } else {
        eventByType[type] = <TimelineEvent>[event];
      }
    }
    return ProfilingSummarizer._(eventByType);
  }

  /// Key is the type of profiling event, for e.g. CPU, GPU, Memory.
  final Map<ProfileType, List<TimelineEvent>> eventByType;

  /// Returns the average, 90th and 99th percentile summary of CPU, GPU and Memory
  /// usage from the recorded events. Note: If a given profile type isn't available
  /// for any reason, the map will not contain the said profile type.
  Map<String, dynamic> summarize() {
    final Map<String, dynamic> summary = <String, dynamic>{};
    summary.addAll(_summarize(ProfileType.CPU, 'cpu_usage'));
    summary.addAll(_summarize(ProfileType.GPU, 'gpu_usage'));
    summary.addAll(_summarize(ProfileType.Memory, 'memory_usage'));
    return summary;
  }

  Map<String, dynamic> _summarize(ProfileType profileType, String name) {
    final Map<String, dynamic> summary = <String, dynamic>{};
    if (!hasProfilingInfo(profileType)) {
      return summary;
    }
    summary['average_$name'] = computeAverage(profileType);
    summary['90th_percentile_$name'] = computePercentile(profileType, 90);
    summary['99th_percentile_$name'] = computePercentile(profileType, 99);
    return summary;
  }

  /// Returns true if there are events in the timeline corresponding to [profileType].
  bool hasProfilingInfo(ProfileType profileType) {
    if (eventByType.containsKey(profileType)) {
      return eventByType[profileType].isNotEmpty;
    } else {
      return false;
    }
  }

  /// Computes the average of the `profileType` over the recorded events.
  double computeAverage(ProfileType profileType) {
    final List<TimelineEvent> events = eventByType[profileType];
    if (events.isEmpty) {
      return 0;
    }

    final double total = events
        .map((TimelineEvent e) => _getProfileValue(profileType, e))
        .reduce((double a, double b) => a + b);
    return total / events.length;
  }

  /// The [percentile]-th percentile `profileType` over the recorded events.
  double computePercentile(ProfileType profileType, double percentile) {
    final List<TimelineEvent> events = eventByType[profileType];
    if (events.isEmpty) {
      return 0;
    }

    final List<double> doubles = events
        .map((TimelineEvent e) => _getProfileValue(profileType, e))
        .toList();
    return findPercentile(doubles, percentile);
  }

  static ProfileType _getProfileType(String eventName) {
    switch (eventName) {
      case _kCpuProfile:
        return ProfileType.CPU;
      case _kGpuProfile:
        return ProfileType.GPU;
      case _kMemoryProfile:
        return ProfileType.Memory;
      default:
        throw Exception('Invalid profiling event: $eventName.');
    }
  }

  double _getProfileValue(ProfileType profileType, TimelineEvent e) {
    switch (profileType) {
      case ProfileType.CPU:
        return _getArgValue('total_cpu_usage', e);
      case ProfileType.GPU:
        return _getArgValue('gpu_usage', e);
      case ProfileType.Memory:
        final double dirtyMem = _getArgValue('dirty_memory_usage', e);
        final double ownedSharedMem =
            _getArgValue('owned_shared_memory_usage', e);
        return dirtyMem + ownedSharedMem;
    }

    return 0; // unreachable.
  }

  double _getArgValue(String argKey, TimelineEvent e) {
    assert(e.arguments.containsKey(argKey));
    final dynamic argVal = e.arguments[argKey];
    assert(argVal is String);
    return double.parse(argVal as String);
  }
}

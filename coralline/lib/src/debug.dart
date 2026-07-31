// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// Extension to provide zero-overhead debugging capabilities to CoralNode objects.
///
/// **Design Philosophy (Zero-Overhead & External State):**
/// Debugging complex topological graphs can be challenging. This extension allows developers
/// to tag nodes and capture their creation stack traces to hunt down memory leaks or trace
/// data pipelines. Crucially, it guarantees absolutely zero memory overhead in Release builds
/// by storing debug state externally using an [Expando] and wrapping the capture logic in `assert`.
extension CorallineDebugExtension on CoralNode {
  /// (Debug Only) A developer-defined tag to identify this specific object.
  String? get debugTag => _debugTags[this];

  /// (Debug Only) The exact code location where this object was created.
  String? get debugCreationLocation => _debugLocations[this];

  /// (Debug Only) Captures the current stack trace and assigns an optional tag.
  ///
  /// Use this via the cascade operator when instantiating a CoralNode object.
  ///
  /// * [tag]: An optional identifier for this node.
  /// * [traceCount]: The number of call stack frames to keep (default: 5).
  ///
  /// **Ensures:**
  /// * In debug mode, the node is tagged and its creation stack trace is captured and stored externally.
  /// * In release mode, does absolutely nothing (zero overhead).
  ///
  /// **Example:**
  /// ```dart
  /// final myCoral = Coral('data')..debugTrace('MyNode', 2);
  /// ```
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

extension CorallineTerminalDebugExtension on CorallineTerminal {
  String? get debugTag => _debugTags[this];
  String? get debugCreationLocation => _debugLocations[this];
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

extension CoralControllerDebugExtension on CoralController {
  String? get debugTag => _debugTags[this];
  String? get debugCreationLocation => _debugLocations[this];
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

extension CoralComputationDebugExtension on CoralComputation {
  String? get debugTag => _debugTags[this];
  String? get debugCreationLocation => _debugLocations[this];
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

extension CoralBroadcasterDebugExtension on CoralBroadcaster {
  String? get debugTag => _debugTags[this];
  String? get debugCreationLocation => _debugLocations[this];
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

extension CoralCouplerDebugExtension on CoralCoupler {
  String? get debugTag => _debugTags[this];
  String? get debugCreationLocation => _debugLocations[this];
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

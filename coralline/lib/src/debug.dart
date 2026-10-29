// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// Extension for attaching debug labels and creation locations to CoralNode objects.
///
/// **Design Philosophy (Zero-Overhead & External State):**
/// Debugging complex topological graphs can be challenging. This extension allows developers
/// to tag nodes and capture their creation stack traces to hunt down memory leaks or trace
/// data pipelines. Debug metadata is stored externally using an [Expando], and capture is guarded
/// by `assert`, so metadata is not recorded when assertions are disabled. Calling the extension
/// still has the normal method-call cost in that mode.
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
  /// * When assertions are disabled, the capture closure does not run and metadata is not stored.
  ///
  /// ## Examples
  /// ```dart
  /// final myCoral = Coral.data('data')..debugTrace('MyNode', 2);
  /// ```
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

/// Debug metadata extensions for [CorallineTerminal] instances.
extension CorallineTerminalDebugExtension on CorallineTerminal {
  /// (Debug Only) A developer-defined tag to identify this specific object.
  String? get debugTag => _debugTags[this];

  /// (Debug Only) The exact code location where this object was created.
  String? get debugCreationLocation => _debugLocations[this];

  /// (Debug Only) Captures the current stack trace and assigns an optional tag.
  ///
  /// * [tag]: An optional identifier for this terminal.
  /// * [traceCount]: The number of call stack frames to keep (default: 5).
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

/// Debug metadata extensions for [CoralController] instances.
extension CoralControllerDebugExtension on CoralController {
  /// (Debug Only) A developer-defined tag to identify this specific object.
  String? get debugTag => _debugTags[this];

  /// (Debug Only) The exact code location where this object was created.
  String? get debugCreationLocation => _debugLocations[this];

  /// (Debug Only) Captures the current stack trace and assigns an optional tag.
  ///
  /// * [tag]: An optional identifier for this controller.
  /// * [traceCount]: The number of call stack frames to keep (default: 5).
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

/// Debug metadata extensions for [CoralComputation] instances.
extension CoralComputationDebugExtension on CoralComputation {
  /// (Debug Only) A developer-defined tag to identify this specific object.
  String? get debugTag => _debugTags[this];

  /// (Debug Only) The exact code location where this object was created.
  String? get debugCreationLocation => _debugLocations[this];

  /// (Debug Only) Captures the current stack trace and assigns an optional tag.
  ///
  /// * [tag]: An optional identifier for this computation.
  /// * [traceCount]: The number of call stack frames to keep (default: 5).
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

/// Debug metadata extensions for [CoralBroadcaster] instances.
extension CoralBroadcasterDebugExtension on CoralBroadcaster {
  /// (Debug Only) A developer-defined tag to identify this specific object.
  String? get debugTag => _debugTags[this];

  /// (Debug Only) The exact code location where this object was created.
  String? get debugCreationLocation => _debugLocations[this];

  /// (Debug Only) Captures the current stack trace and assigns an optional tag.
  ///
  /// * [tag]: An optional identifier for this broadcaster.
  /// * [traceCount]: The number of call stack frames to keep (default: 5).
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

/// Debug metadata extensions for [CoralCoupler] instances.
extension CoralCouplerDebugExtension on CoralCoupler {
  /// (Debug Only) A developer-defined tag to identify this specific object.
  String? get debugTag => _debugTags[this];

  /// (Debug Only) The exact code location where this object was created.
  String? get debugCreationLocation => _debugLocations[this];

  /// (Debug Only) Captures the current stack trace and assigns an optional tag.
  ///
  /// * [tag]: An optional identifier for this coupler.
  /// * [traceCount]: The number of call stack frames to keep (default: 5).
  void debugTrace([String? tag, int traceCount = 5]) => _captureDebugTrace(this, tag, traceCount);
}

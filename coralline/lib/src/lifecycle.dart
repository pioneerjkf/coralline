// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// A status interface representing the current lifecycle state of a
/// [CoralNode] node.
///
/// **Core Concept (Lifecycle Observability):**
/// Provides a read-only view into the reactive lifecycle state of any node in the
/// topological graph.
///
/// **Design Philosophy:**
/// Coralline operates on a lazy, consumer-driven activation model. Nodes are only
/// activated when a downstream terminal connects and demands data, and are
/// deactivated when the terminal disconnects. This interface allows developers to
/// safely observe these transitions without being able to mutate them.
abstract interface class CorallineLifecycleStatus {
  /// Whether the node has been activated by a downstream terminal.
  bool get isActivated;

  /// Whether the node is currently running (activated and not paused).
  bool get isRunning;

  /// Whether the node is temporarily paused.
  bool get isPaused;

  /// Whether the node has been permanently deactivated.
  bool get isDeactivated;
}

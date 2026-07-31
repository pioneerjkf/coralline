// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// A multi-cast proxy that splits a single declarative pipeline to share a single upstream
/// among multiple consumers.
///
/// **Core Concept (Resource Efficiency):**
/// By default, [CoralNode] pipelines are linear (1:1). If multiple UI widgets
/// subscribe to the same upstream pipeline independently, the upstream logic
/// (and its heavy resources) is duplicated and computed multiple times.
/// [CoralBroadcaster] solves this by acting as a single, shared subscriber
/// that computes the upstream exactly once and distributes the cached result
/// to all attached downstream consumers, maximizing resource efficiency.
///
/// **Design Philosophy:**
/// - **Reference Counting Lifecycle**: The broadcaster tracks the exact number
///   of active downstream subscribers. It activates the upstream on the first
///   subscriber and deactivates it on the last (zero) subscriber, ensuring
///   optimal lifecycle management.
/// - **Intent Firewall**: To protect the shared upstream pipeline from conflicting
///   downstream demands (e.g., High-Res vs Low-Res), the broadcaster strictly
///   blocks downstream intents from propagating upstream.
/// - **Hidden Terminal**: Internally, it creates a hidden terminal to
///   securely pull data from the upstream graph.
///
/// **Intended Usage & Data Flow Architecture (Push-Dirty, Pull-Data):**
/// As a 1:N distributor, it slightly modifies the standard data flow:
///
/// **[Phase 2] Push-Dirty (Downstream Propagation)**
/// - When the upstream is dirty, the internal hidden terminal catches the signal,
///   clears the internal cache ([_latestSnapshot]), and broadcasts the Dirty
///   signal to all attached downstream consumers.
///
/// **[Phase 4] Pull-Data & Lazy Computation (Reverse Traversal)**
/// - When the first downstream consumer requests data, it pulls from the upstream,
///   computes it, and safely caches the result.
/// - When the second (or Nth) consumer requests data in the same cycle, it
///   instantly receives the cached snapshot without triggering upstream computation.
///
/// **AI & Developer Note:**
/// - **No Intent Propagation**: If an upstream node requires a specific UI context
///   (Intent) to function, it MUST be placed *downstream* of this broadcaster,
///   as the broadcaster acts as a firewall and drops all intents.
/// - **Concurrent Modification**: The internal broadcast mechanism includes safety
///   guards to prevent concurrent modification errors if a downstream consumer
///   attaches or detaches while the dirty signal is broadcasting.
///
/// **Example:**
/// ```dart
/// // Usually created via [CoralProvider] or an extension method:
/// final broadcaster = CoralBroadcaster(upstreamPipeline);
///
/// // Multiple downstreams can now safely branch off:
/// final branchA = broadcaster.coral.map((data) => data * 2);
/// final branchB = broadcaster.coral.map((data) => data + 10);
/// ```
sealed class CoralBroadcaster<T> implements CoralProvider<T> {
  /// Creates a multi-cast proxy that shares the [inbound] pipeline.
  ///
  /// * [inbound]: The source [Coral] pipeline to share among multiple downstream branches.
  /// * [lazyDeactivation]: Controls deactivation timing when subscriber count drops to zero.
  ///   Defaults to `true`.
  ///
  /// If [lazyDeactivation] is `true`, defers deactivation to the end of the microtask queue.
  /// If a new subscriber attaches within the same cycle (e.g., during a Widget
  /// rebuild or Hot Reload), the deactivation is canceled. This prevents
  /// expensive upstream resources from unnecessarily tearing down and flickering.
  /// If `false`, synchronously deactivates the upstream the exact millisecond the last
  /// subscriber detaches. Use this only when resources MUST be freed instantly.
  ///
  /// **Ensures:**
  /// * Returns a [CoralBroadcaster] that shares the [inbound] pipeline.
  factory CoralBroadcaster(Coral<T> inbound, {bool lazyDeactivation = true}) {
    if (lazyDeactivation) {
      return _LazyDeactivationCoralBroadcaster(inbound);
    } else {
      return _ImmediateDeactivationCoralBroadcaster(inbound);
    }
  }

  /// Creates a static, lightweight [CoralBroadcaster] holding a fixed [data] payload.
  ///
  /// * [data]: The constant value payload to wrap.
  ///
  /// **Ensures:**
  /// * Returns a [CoralBroadcaster] that wraps a static [Coral.data] node.
  factory CoralBroadcaster.data(T data) => CoralBroadcaster(Coral.data(data));

  /// Whether the upstream pipeline has been activated by at least one downstream branch.
  @override
  bool get isActivated;

  /// Whether the upstream pipeline is currently running.
  @override
  bool get isRunning;

  /// Whether the upstream pipeline is temporarily paused.
  @override
  bool get isPaused;

  /// Whether the upstream pipeline has been permanently deactivated.
  @override
  bool get isDeactivated;

  /// Exposes the shared branch [Coral] node that consumers can attach to.
  ///
  /// **Ensures:**
  /// * Returns a new branch [Coral] node linked to this broadcaster.
  @override
  Coral<T> get coral;
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// The foundational abstract base class for building custom declarative nodes in the graph.
///
/// [CoralComputation] defines the common interface and lifecycle state getters shared
/// by all custom computation nodes in the topological graph. Subclasses choose either
/// [SimplexComputation] (for 1:1 single-inbound optimization) or [ComplexComputation]
/// (for N:1 multi-inbound dependencies).
///
/// **Design Philosophy:**
/// Custom computations act as lazy, pull-based intermediary nodes. Instead of computing
/// immediately when upstream nodes change, they register as 'dirty' and defer calculation
/// until a downstream consumer explicitly requests data via [coral].
///
/// **AI & Developer Note:**
/// [CoralComputation] is a sealed class and cannot be extended or implemented outside
/// this library. Always inherit from either [SimplexComputation] (for 1:1 single inbound)
/// or [ComplexComputation] (for N:1 multi inbound).
///
/// **Example:**
/// ```dart
/// class MultiplyComputation extends SimplexComputation<int> {
///   MultiplyComputation(this.source, this.factor);
///   final Coral<int> source;
///   final int factor;
///
///   @override
///   @manifestSync
///   CoralNode manifest() => source;
///
///   @override
///   int compute() => source.data * factor;
/// }
/// ```
sealed class CoralComputation<T> implements CoralProvider<T> {
  CoralComputation();

  Coral<T> get _baseCoral;

  /// Exposes the underlying topological node that powers this computation.
  ///
  /// **Ensures:**
  /// * Returns the cached [Coral] instance managing this computation.
  @override
  @pragma('vm:prefer-inline')
  Coral<T> get coral => _baseCoral;

  /// Indicates whether the underlying topological node is currently active in the graph.
  ///
  /// Returns `true` if at least one downstream consumer is attached and listening.
  @override
  @pragma('vm:prefer-inline')
  bool get isActivated => coral._state.isActivated;

  /// Indicates whether the underlying topological node is running and processing events.
  @override
  @pragma('vm:prefer-inline')
  bool get isRunning => coral._state.isRunning;

  /// Indicates whether the underlying topological node is currently in a paused state.
  @override
  @pragma('vm:prefer-inline')
  bool get isPaused => coral._state.isPaused;

  /// Indicates whether the underlying topological node is currently deactivated.
  @override
  @pragma('vm:prefer-inline')
  bool get isDeactivated => coral._state.isDeactivated;

  /// Iterates over all direct upstream inbound nodes connected to this computation.
  ///
  /// **Ensures:**
  /// * Returns an iterable of all direct inbound [CoralNode] dependencies.
  @pragma('vm:prefer-inline')
  Iterable<CoralNode> iterateInbound() => (_baseCoral as _Joint)._iterateInbound();

  /// Performs the actual calculation and returns the computed result for this node.
  ///
  /// **Requires:**
  /// * Must be a pure and synchronous calculation without side-effects.
  /// * Every node accessed inside [compute] MUST be declared in [manifest].
  T compute();
}

/// A high-performance custom node computation optimized for a single inbound dependency (1:1).
///
/// Unlike [ComplexComputation] which manages an N:1 list of inbound dependencies,
/// [SimplexComputation] binds directly to a single upstream [CoralNode] returned by [manifest].
///
/// **Design Philosophy:**
/// Single-input transformation nodes (such as `map`, `where`, or `distinct`) constitute
/// the majority of reactive graph nodes. [SimplexComputation] eliminates array allocations
/// and loop overhead by storing a direct field reference to its single inbound node.
///
/// **Extreme Performance Optimization:**
/// * **Zero Extra Heap Allocation**: Avoids allocating `List.unmodifiable` containers.
/// * **Direct Field Reference**: Accesses `_inbound` directly without array index lookups.
/// * **Hot-Path Inlining**: Enables Dart VM method inlining on graph activation loops.
///
/// **AI & Developer Note:**
/// Use [SimplexComputation] whenever a computation has exactly one upstream source.
/// If your node requires multiple dependencies or dynamic manifest lists, use [ComplexComputation].
///
/// **Example:**
/// ```dart
/// class DoubleComputation extends SimplexComputation<int> {
///   DoubleComputation(this.source);
///   final Coral<int> source;
///
///   @override
///   @manifestSync
///   CoralNode manifest() => source;
///
///   @override
///   int compute() => source.data * 2;
/// }
/// ```
abstract base class SimplexComputation<T> extends CoralComputation<T> {
  SimplexComputation() {
    _baseCoral = _SimplexComputationCoral.create(this);
  }

  @override
  late final Coral<T> _baseCoral;

  /// Declares the single upstream dependency node this computation reads from.
  ///
  /// **Ensures:**
  /// * The returned [CoralNode] is attached as the single inbound dependency.
  @manifestSync
  CoralNode manifest();

  /// Performs the actual computation and returns the new value for this node based on the single upstream dependency.
  ///
  /// **Requires:**
  /// * The single node read inside this method MUST match the node returned by [manifest].
  @override
  T compute();
}

/// A versatile custom node computation for handling multiple inbound dependencies (N:1).
///
/// [ComplexComputation] manages an N:1 set of upstream dependencies declared via [manifest].
/// It automatically coordinates dirty propagation and lazy reverse-traversal computation.
///
/// **Design Philosophy:**
/// Complex business logic often requires aggregating multiple data sources.
/// [ComplexComputation] decouples dependency registration from calculation: [manifest] declares
/// the graph connections while [compute] computes the combined result lazily.
///
/// **Data Flow Architecture (Push-Dirty, Pull-Data):**
/// * **Push-Dirty (Downstream Propagation)**: When any upstream node declared in [manifest]
///   becomes dirty, [ComplexComputation] marks itself as dirty and forwards the signal without
///   executing [compute].
/// * **Pull-Data & Lazy Computation (Reverse Traversal)**: When a downstream terminal
///   requests data, [compute] is invoked once per computation cycle, caching the result.
///
/// **AI & Developer Note:**
/// * **Pure Function Constraint**: The [compute] method MUST be pure and synchronous.
///   Do not perform side-effects (e.g., UI updates, network calls) inside [compute].
/// * **Manifest Alignment**: Every node accessed inside [compute] MUST be returned in [manifest].
///
/// **Example:**
/// ```dart
/// class SumComputation extends ComplexComputation<int> {
///   SumComputation(this.a, this.b);
///   final Coral<int> a;
///   final Coral<int> b;
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [a, b];
///
///   @override
///   int compute() => a.data + b.data;
/// }
/// ```
abstract base class ComplexComputation<T> extends CoralComputation<T> {
  ComplexComputation() {
    _baseCoral = _ComplexComputationCoral.create(this);
  }

  @override
  late final Coral<T> _baseCoral;

  /// Declares all upstream dependencies this computation reads from for its computation.
  ///
  /// **Ensures:**
  /// * All returned [CoralNode] instances are attached as inbound dependencies.
  @manifestSync
  Iterable<CoralNode> manifest();

  /// Performs the actual computation and returns the new value for this node based on the upstream dependencies.
  ///
  /// **Requires:**
  /// * Every node read inside this method MUST be declared in the [manifest] iterable.
  @override
  T compute();
}

/// A mixin for computations to intercept and react to downstream lifecycle state changes.
///
/// Mix this into a [SimplexComputation] or [ComplexComputation] to receive notification callbacks
/// (`didActivate`, `didPause`, `didResume`, `didDeactivate`) triggered by downstream terminals.
///
/// **Design Philosophy:**
/// Custom computations frequently manage external resources (e.g., WebSockets, sensors, timers).
/// Initializing these resources in constructor code causes battery and memory leaks.
/// This mixin propagates lifecycle state *in reverse* from downstream consumers, ensuring heavy
/// resources are active only when actively needed by the UI.
///
/// **AI & Developer Note:**
/// * **Synchronous Teardown**: [didDeactivate] MUST cleanly and synchronously release any
///   resources allocated during [didActivate].
/// * **Broadcaster Ref-Counting**: When routed through a `CoralBroadcaster` (1:N split),
///   [didActivate] triggers when the first terminal attaches, and [didDeactivate] triggers
///   when the last terminal detaches.
///
/// **Example:**
/// ```dart
/// class LocationComputation extends ComplexComputation<Location>
///     with CorallineLifecycleAware {
///   LocationComputation(this.gpsService);
///   final GpsService gpsService;
///
///   @override
///   void didActivate() => gpsService.startUpdates();
///
///   @override
///   void didDeactivate() => gpsService.stopUpdates();
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [];
///
///   @override
///   Location compute() => gpsService.currentLocation;
/// }
/// ```
base mixin CorallineLifecycleAware {
  /// Invoked when the first downstream terminal attaches and activates the pipeline.
  ///
  /// **Ensures:**
  /// * Called exactly once when transitioning from zero to one active downstream consumer.
  @mustCallSuper
  void didActivate() {}

  /// Invoked when the last downstream terminal detaches and deactivates the pipeline.
  ///
  /// **Ensures:**
  /// * Called exactly once when active downstream consumers drop to zero.
  @mustCallSuper
  void didDeactivate() {}

  /// Invoked when the downstream pipeline enters a paused state.
  @mustCallSuper
  void didPause() {}

  /// Invoked when the downstream pipeline resumes from a paused state.
  @mustCallSuper
  void didResume() {}
}

/// A mixin for computations to receive contextual metadata intent updates from downstream terminals.
///
/// **Design Philosophy:**
/// While data flows strictly downstream, contextual metadata (`intent`) can propagate *in reverse*
/// from downstream terminals up to this computation. This enables adaptive behavior (e.g., frame
/// dropping when minimized, density-aware image loading) without violating declarative flow rules.
///
/// **AI & Developer Note:**
/// * **Broadcaster Firewall Constraint**: Computations mixing in [CorallineTerminalIntentAware]
///   MUST be positioned downstream of any `CoralBroadcaster`. Broadcasters act as intent firewalls
///   and block intent propagation upstream to prevent 1:N parameter collisions.
/// * **Null Intent Safety**: Downstream terminals may send `null` intents. Always handle `null`
///   gracefully inside [didUpdateIntent].
///
/// **Example:**
/// ```dart
/// class AdaptiveImageComputation extends ComplexComputation<Image>
///     with CorallineTerminalIntentAware {
///   AdaptiveImageComputation(this.source);
///   final Coral<Image> source;
///
///   @override
///   void didUpdateIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
///     if (newIntent is TargetResolutionIntent) {
///       _setResolution(newIntent.resolution);
///     }
///   }
///
///   @override
///   @manifestSync
///   Iterable<CoralNode> manifest() => [source];
///
///   @override
///   Image compute() => _processImage(source.data);
/// }
/// ```
base mixin CorallineTerminalIntentAware {
  /// Invoked when downstream consumer intent metadata changes.
  ///
  /// * [oldIntent]: The previous intent payload sent by the downstream terminal, or `null`.
  /// * [newIntent]: The new intent payload sent by the downstream terminal, or `null`.
  ///
  /// **Requires:**
  /// * Implementations must gracefully handle `null` for both [oldIntent] and [newIntent].
  @mustCallSuper
  void didUpdateIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {}
}

/// Annotation marking `manifest()` methods that require strict dependency synchronization.
///
/// **Design Philosophy:**
/// Ensures static analysis and developer tooling can verify that every node read inside
/// [compute] is declared in [manifest].
///
/// **AI & Developer Note:**
/// * **Verification Checklist**:
///   1. Every node accessed in `compute()` must be declared in `manifest()`.
///   2. Do not return unused nodes in `manifest()`.
///   3. Use list literals `=> [...]` instead of `sync*` / `yield`.
const manifestSync = _ManifestSync();

class _ManifestSync {
  const _ManifestSync();
}

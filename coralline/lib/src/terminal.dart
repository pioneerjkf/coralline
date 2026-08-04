// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// **Core Concept (Error Delegation Intent):**
/// Defines the intended behavior for handling uncaught exceptions that occur
/// asynchronously or unexpectedly within the topological pipeline during its lifecycle.
///
/// **Operational Mechanism:**
/// If an unexpected error occurs during data propagation or lifecycle transitions
/// (e.g., inside an asynchronous mapping or a resource cleanup), the pipeline safely
/// catches it and delegates it to [handleUncaughtError]. By default, this forwards
/// the error to the current `Zone`'s error handler.
///
/// **Intended Usage (Log Collection & Crash Analytics):**
/// Developers can subclass [CorallineTerminalIntent] and provide it to the terminal
/// upon creation. This allows centralized intercepting and logging of silent pipeline
/// errors to services like Sentry, Firebase Crashlytics, or Datadog without crashing the UI.
///
/// **Example:**
/// ```dart
/// final class CrashlyticsIntent extends CorallineTerminalIntent {
///   @override
///   void handleUncaughtError(Object error, StackTrace stackTrace) {
///     FirebaseCrashlytics.instance.recordError(error, stackTrace);
///   }
/// }
///
/// // Inject the custom intent into the terminal
/// final terminal = pipeline.toTerminal(
///   () => setState(() {}),
///   intent: CrashlyticsIntent(),
/// );
/// ```
abstract base class CorallineTerminalIntent {
  /// Invoked when the pipeline encounters an unexpected error that cannot be
  /// safely encapsulated within a `damaged` data snapshot.
  void handleUncaughtError(Object error, StackTrace stackTrace) {
    // In debug mode, log the formatted error cleanly without throwing an assertion cascade.
    assert(() {
      print(
        '\n======================================\n'
        '🚨 [Coralline] Uncaught Error Detected in Pipeline\n'
        'Error: $error\n'
        'StackTrace:\n$stackTrace\n'
        '======================================\n',
      );
      return true;
    }());

    // Delegate to the Zone's error handler.
    Zone.current.handleUncaughtError(error, stackTrace);
  }
}

/// **Core Concept (Separation of Concerns):**
/// The terminal Sink of the topological graph, serving as the definitive bridge
/// between CoralNode's declarative pipelines and external imperative environments
/// (such as Flutter's Widget tree or traditional Dart Streams).
///
/// If [CoralController] is the imperative Source that pushes dynamic data into
/// the pipeline, [CorallineTerminal] is the reactive Sink that pulls data out.
/// It strictly isolates the pure logic of the pipeline from the side-effects of
/// the UI. It listens for lightweight `onDirty` signals from the graph and
/// delegates actual data extraction to the external consumer via Pull-Based computation.
///
/// **Design Philosophy:**
/// - **Strict Lifecycle Synchronization**: In its constructor, the terminal attaches
///   to the upstream pipeline and immediately synchronizes its lifecycle state.
///   Since the terminal is born `Inactive`, it forces the upstream pipeline to
///   instantly sync down to `Inactive` as well. This strict lifecycle handshake
///   ensures that reused or hot-swapped pipelines are properly reset, preventing
///   orphaned active states and resource leaks.
/// - **Optimistic Handshake**: During initialization, it attaches to the upstream
///   optimistically. If the upstream throws a Fail-Fast exception during this
///   handshake, the terminal gracefully catches the exception, cleanly detaches,
///   and falls back to a safe `damaged` state, ensuring zero UI crashes.
/// - **Absolute Lifecycle Authority**: As the final consumer, it holds the master
///   switch for the entire pipeline. Calling [activate] or [deactivate] propagates
///   all the way to the [CoralController], waking up or safely tearing down heavy
///   resources (like WebSockets or Geolocation streams) dynamically.
///
/// **Intended Usage & Data Flow Architecture (Push-Dirty, Pull-Data):**
/// As the destination of CoralNode's efficient architecture, the terminal plays
/// a critical role in the 4-Phase Flow:
///
/// **[Phase 1 & 2] Injection & Propagation (Upstream)**
/// - The controller injects data, and a lightweight "Dirty" flag propagates down
///   the topological graph toward this terminal.
///
/// **[Phase 3] Terminal Notification (Destination)**
/// - Action: The "Dirty" flag hits the [CorallineTerminal].
/// - Result: The terminal triggers its `onDirty` callback (e.g., `setState()`),
///   queuing a UI re-render, but does **NOT** compute or push data payloads.
///
/// **[Phase 4] Pull-Data & Lazy Computation (Reverse Traversal)**
/// - Action: During the UI render cycle, the external consumer explicitly requests
///   `.snapshot` or `.data` from the terminal.
/// - Result: The terminal pulls data from its parent, triggering a reverse traversal
///   UP the graph. Intermediate transformations execute lazily, and the final
///   computed data is handed directly to the UI.
///
/// **Example:**
/// You can instantiate a terminal directly or use convenient extension methods:
/// ```dart
/// // Direct instantiation
/// final terminal = CoralTerminal(pipeline, onDirty: () => setState(() {}));
///
/// // Extension method
/// final terminal = pipeline.toTerminal(() => setState(() {}));
/// ```
sealed class CorallineTerminal<C extends CoralNode> extends _TerminalPoint<C> {
  CorallineTerminal(super.inbound, {required super.onDirty}) : intent = null;

  CorallineTerminal.withIntent(super.inbound, {required CorallineTerminalIntent this.intent, required super.onDirty});

  C get inbound => _inbound;

  @override
  final CorallineTerminalIntent? intent;

  /// **Core Concept (Lifecycle - Activation):**
  /// Activates the terminal, signaling to the topological graph that an external
  /// consumer is now actively observing the data pipeline. This triggers upstream
  /// nodes to allocate resources and begin lazy computation.
  ///
  /// **Operational Mechanism:**
  /// 1. **Idempotency Check:** Guarantees that redundant activation calls are safely
  ///    ignored if the terminal is already active, protecting the graph from duplicate signals.
  /// 2. **Optimistic Propagation:** Immediately and non-blockingly propagates
  ///    the activation state upward through the topology graph to wake up upstream nodes.
  /// 3. **Error Delegation:** If upstream nodes throw unexpected exceptions during this
  ///    optimistic propagation, they are safely caught and routed to [CorallineTerminalIntent.handleUncaughtError].
  void activate() {
    if (_state.isActivated) return;
    _activateOptimistically();
  }

  /// **Core Concept (Lifecycle - Pause):**
  /// Temporarily suspends the terminal. Upstream nodes are notified of the pause
  /// and may choose to halt expensive background work (like animations or polling).
  ///
  /// **Operational Mechanism:**
  /// 1. **Idempotency Check:** Guarantees that redundant pause calls are safely
  ///    ignored if the terminal is already paused or deactivated.
  /// 2. **Optimistic Propagation:** Immediately and non-blockingly propagates
  ///    the pause state upward through the topology graph to suspend upstream operations.
  /// 3. **Error Delegation:** If upstream nodes throw unexpected exceptions during this
  ///    optimistic propagation, they are safely caught and routed to [CorallineTerminalIntent.handleUncaughtError].
  @mustCallSuper
  void pause() {
    if (!_state.isRunning) return;
    _pauseOptimistically();
  }

  /// **Core Concept (Lifecycle - Resume):**
  /// Resumes a paused terminal. Upstream nodes are notified and will restart
  /// their suspended operations.
  ///
  /// **Operational Mechanism:**
  /// 1. **Idempotency Check:** Guarantees that redundant resume calls are safely
  ///    ignored if the terminal is not currently in a paused state.
  /// 2. **Optimistic Propagation:** Immediately and non-blockingly propagates
  ///    the resume state upward through the topology graph to restart upstream operations.
  /// 3. **Error Delegation:** If upstream nodes throw unexpected exceptions during this
  ///    optimistic propagation, they are safely caught and routed to [CorallineTerminalIntent.handleUncaughtError].
  @mustCallSuper
  void resume() {
    if (!_state.isPaused) return;
    _resumeOptimistically();
  }

  /// **Core Concept (Lifecycle - Deactivation):**
  /// Permanently detaches the terminal from the graph, releasing all topological
  /// connections.
  ///
  /// **Operational Mechanism:**
  /// 1. **Idempotency Check:** Guarantees that redundant deactivation calls are safely
  ///    ignored, protecting the graph against multiple teardown attempts.
  /// 2. **Optimistic Propagation:** Immediately and non-blockingly propagates
  ///    the deactivation state upward through the topology graph to initiate cleanup.
  /// 3. **Error Delegation:** If upstream nodes throw unexpected exceptions during this
  ///    optimistic propagation, they are safely caught and routed to [CorallineTerminalIntent.handleUncaughtError].
  ///
  /// ⚠️ **AI & Developer Note (Mandatory Cleanup):**
  /// You MUST call [deactivate] when this terminal is discarded (e.g., in a
  /// Flutter State's `dispose()` method). Failing to do so prevents upstream
  /// nodes from realizing they are orphaned, causing severe memory leaks.
  @mustCallSuper
  void deactivate() {
    if (_state.isDeactivated) return;
    _deactivateOptimistically();
  }

  bool get isActivated => _state.isActivated;

  bool get isRunning => _state.isRunning;

  bool get isPaused => _state.isPaused;

  bool get isDeactivated => _state.isDeactivated;
}

/// **Core Concept:**
/// A concrete [CorallineTerminal] designed specifically for 1:1 [Coral] pipelines.
///
/// It mixes in [CoralSnapshotDelegator] to provide direct, type-safe access
/// to the underlying `T` data payload without manually unwrapping the inbound.
base class CoralTerminal<T> extends CorallineTerminal<Coral<T>> with CoralSnapshotDelegator<T> {
  CoralTerminal(super.inbound, {required super.onDirty});

  CoralTerminal.withIntent(super.inbound, {required super.intent, required super.onDirty}) : super.withIntent();

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;

  @override
  Coral<T> _catchDamaged(Object error, StackTrace? stackTrace) => Coral.damaged(error, stackTrace);
}

/// **Core Concept:**
/// A concrete [CorallineTerminal] designed specifically for [Trunk] pipelines.
///
/// It mixes in [TrunkSnapshotDelegator] to provide direct, type-safe access
/// to the underlying `T` data payload without manually unwrapping the inbound.
base class TrunkTerminal<T> extends CorallineTerminal<Trunk<T>> with TrunkSnapshotDelegator<T> {
  TrunkTerminal(super.inbound, {required super.onDirty});

  TrunkTerminal.withIntent(super.inbound, {required super.intent, required super.onDirty}) : super.withIntent();

  @override
  TrunkSnapshot<T> get snapshot => _inbound.snapshot;

  @override
  Trunk<T> _catchDamaged(Object error, StackTrace? stackTrace) => Trunk.damaged(error, stackTrace);
}

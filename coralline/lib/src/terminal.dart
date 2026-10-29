// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// Defines the handling behavior for uncaught pipeline exceptions.
///
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
/// ## Examples
/// ```dart
/// final class CrashlyticsIntent extends CorallineTerminalIntent {
///   @override
///   void handleUncaughtError(Object error, StackTrace stackTrace) {
///     print('Logged uncaught pipeline error: $error');
///   }
/// }
///
/// final pipeline = Coral.data(42);
///
/// // Inject the custom intent into the terminal
/// final terminal = CoralTerminal.withIntent(
///   pipeline,
///   intent: CrashlyticsIntent(),
///   onDirty: () {},
/// );
/// ```
abstract base class CorallineTerminalIntent {
  /// Creates a [CorallineTerminalIntent].
  CorallineTerminalIntent();

  /// Invoked when the pipeline encounters an unexpected error that cannot be
  /// safely encapsulated within a `damaged` data snapshot.
  ///
  /// * [error]: The uncaught error object thrown during pipeline execution or lifecycle transitions.
  /// * [stackTrace]: The stack trace associated with [error].
  void handleUncaughtError(Object error, StackTrace stackTrace) {
    // In debug mode, log the formatted error cleanly without throwing an assertion cascade.
    assert(() {
      print(
        '\n======================================\n'
        '[Coralline:Error] Uncaught Error Detected in Pipeline\n'
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

/// The terminal Sink of the topological graph, serving as the bridge to external environments.
///
/// Bridges CoralNode's declarative pipelines with external imperative environments
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
/// ## Terminal Push-Pull Lifecycle Flow
/// ```text
/// 1. activate() ──> Propagate Active Upstream ──> Wake Up Sources
///                                                       │
/// 2. onDirty() <── Push Invalidation Signal <───────────┘
///       │
///       ▼
/// 3. terminal.data ──> Pull Evaluation Request ──> Return Resolved Payload
/// ```
///
/// **Phase 1 & 2: Injection & Propagation (Upstream)**
/// - The controller injects data, and a lightweight "Dirty" flag propagates down
///   the topological graph toward this terminal.
///
/// **Phase 3: Terminal Notification (Destination)**
/// - Action: The "Dirty" flag hits the [CorallineTerminal].
/// - Result: The terminal triggers its `onDirty` callback (e.g., `setState()`),
///   queuing a UI re-render, but does **NOT** compute or push data payloads.
///
/// **Phase 4: Pull-Data & Lazy Computation (Reverse Traversal)**
/// - Action: During the UI render cycle, the external consumer explicitly requests
///   `.snapshot` or `.data` from the terminal.
/// - Result: The terminal pulls data from its parent, triggering a reverse traversal
///   UP the graph. Intermediate transformations execute lazily, and the final
///   computed data is handed directly to the UI.
///
/// ## Examples
/// You can instantiate a terminal directly or use convenient extension methods:
/// ```dart
/// final pipeline = Coral.data(10);
///
/// // Direct instantiation
/// final directTerminal = CoralTerminal(pipeline, onDirty: () {});
///
/// // Extension method (for a separate pipeline instance)
/// final extTerminal = Coral.data(20).toTerminal(() {});
/// ```
sealed class CorallineTerminal<C extends CoralNode> extends _TerminalPoint<C> {
  /// Creates a [CorallineTerminal] attached to [inbound] without a terminal intent.
  ///
  /// * [inbound]: The upstream [CoralNode] pipeline to observe.
  /// * [onDirty]: Callback invoked when the upstream pipeline marks this terminal dirty.
  CorallineTerminal(super.inbound, {required super.onDirty}) : intent = null;

  /// Creates a [CorallineTerminal] attached to [inbound] with a custom [intent].
  ///
  /// * [inbound]: The upstream [CoralNode] pipeline to observe.
  /// * [intent]: Contextual metadata and error-handling intent propagated upstream.
  /// * [onDirty]: Callback invoked when the upstream pipeline marks this terminal dirty.
  CorallineTerminal.withIntent(super.inbound, {required CorallineTerminalIntent this.intent, required super.onDirty});

  /// The upstream [CoralNode] attached to this terminal.
  C get inbound => _inbound;

  /// The optional [CorallineTerminalIntent] associated with this terminal.
  @override
  final CorallineTerminalIntent? intent;

  /// Activates the terminal and begins observing the upstream data pipeline.
  ///
  /// **Core Concept (Lifecycle - Activation):**
  /// Signals to the topological graph that an external consumer is now actively
  /// observing the data pipeline. This triggers upstream nodes to allocate resources
  /// and begin lazy computation.
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

  /// Temporarily suspends the terminal.
  ///
  /// **Core Concept (Lifecycle - Pause):**
  /// Upstream nodes are notified of the pause and may choose to halt expensive
  /// background work (like animations or polling).
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

  /// Resumes a paused terminal.
  ///
  /// **Core Concept (Lifecycle - Resume):**
  /// Upstream nodes are notified and will restart their suspended operations.
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

  /// Transitions the terminal and its upstream pipeline into the deactivated (inactive) state.
  ///
  /// **Core Concept (Lifecycle - Deactivation):**
  /// Signals that the external consumer is no longer actively observing the pipeline,
  /// allowing upstream nodes to tear down resources (such as stream subscriptions or
  /// managed [Coral.resource] instances). The [inbound] node remains attached to the
  /// terminal and can be re-activated later by calling [activate].
  ///
  /// **Operational Mechanism:**
  /// 1. **Idempotency Check:** Guarantees that redundant deactivation calls are safely
  ///    ignored, protecting the graph against multiple teardown attempts.
  /// 2. **Optimistic Propagation:** Immediately and non-blockingly propagates
  ///    the deactivation state upward through the topology graph to initiate cleanup.
  /// 3. **Error Delegation:** If upstream nodes throw unexpected exceptions during this
  ///    optimistic propagation, they are safely caught and routed to [CorallineTerminalIntent.handleUncaughtError].
  ///
  /// **Implementation note (Mandatory Cleanup):**
  /// You MUST call [deactivate] when this terminal is discarded (e.g., in a
  /// Flutter State's `dispose()` method). Failing to do so prevents upstream
  /// nodes from observing that this terminal is no longer active. Deactivate
  /// terminals you create when their consumer is disposed.
  @mustCallSuper
  void deactivate() {
    if (_state.isDeactivated) return;
    _deactivateOptimistically();
  }

  /// Whether the terminal has been activated by an external consumer.
  bool get isActivated => _state.isActivated;

  /// Whether the terminal is currently running (activated and not paused).
  bool get isRunning => _state.isRunning;

  /// Whether the terminal is temporarily paused.
  bool get isPaused => _state.isPaused;

  /// Whether the terminal is currently in the deactivated (inactive) state.
  bool get isDeactivated => _state.isDeactivated;
}

/// A concrete [CorallineTerminal] designed specifically for 1:1 [Coral] pipelines.
///
/// It mixes in [CoralSnapshotDelegator] to provide direct, type-safe access
/// to the underlying `T` data payload without manually unwrapping the inbound.
base class CoralTerminal<T> extends CorallineTerminal<Coral<T>> with CoralSnapshotDelegator<T> {
  /// Creates a [CoralTerminal] observing [inbound].
  ///
  /// * [inbound]: The upstream [Coral] node to observe.
  /// * [onDirty]: Callback invoked when [inbound] becomes dirty.
  CoralTerminal(super.inbound, {required super.onDirty});

  /// Creates a [CoralTerminal] observing [inbound] with a custom [intent].
  ///
  /// * [inbound]: The upstream [Coral] node to observe.
  /// * [intent]: Contextual metadata and error-handling intent propagated upstream.
  /// * [onDirty]: Callback invoked when [inbound] becomes dirty.
  CoralTerminal.withIntent(super.inbound, {required super.intent, required super.onDirty}) : super.withIntent();

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;

  @override
  Coral<T> _catchDamaged(Object error, StackTrace? stackTrace) => Coral.damaged(error, stackTrace);
}

/// A concrete [CorallineTerminal] designed specifically for [Trunk] pipelines.
///
/// It mixes in [TrunkSnapshotDelegator] to provide direct, type-safe access
/// to the underlying `T` data payload without manually unwrapping the inbound.
base class TrunkTerminal<T> extends CorallineTerminal<Trunk<T>> with TrunkSnapshotDelegator<T> {
  /// Creates a [TrunkTerminal] observing [inbound].
  ///
  /// * [inbound]: The upstream [Trunk] node to observe.
  /// * [onDirty]: Callback invoked when [inbound] becomes dirty.
  TrunkTerminal(super.inbound, {required super.onDirty});

  /// Creates a [TrunkTerminal] observing [inbound] with a custom [intent].
  ///
  /// * [inbound]: The upstream [Trunk] node to observe.
  /// * [intent]: Contextual metadata and error-handling intent propagated upstream.
  /// * [onDirty]: Callback invoked when [inbound] becomes dirty.
  TrunkTerminal.withIntent(super.inbound, {required super.intent, required super.onDirty}) : super.withIntent();

  @override
  TrunkSnapshot<T> get snapshot => _inbound.snapshot;

  @override
  Trunk<T> _catchDamaged(Object error, StackTrace? stackTrace) => Trunk.damaged(error, stackTrace);
}

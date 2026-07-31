// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// The imperative entry point (Source) that bridges dynamic data into the declarative
/// [Coral] pipeline.
///
/// **Core Concept (Separation of Concerns):**
/// In the CoralNode framework, downstream [Coral] objects are strictly read-only and define
/// an immutable flow of data. To push dynamic data (from UI events, network responses, etc.)
/// into this pipeline, an entity with write-access is required. [CoralController] serves
/// exactly this purpose, analogous to how `StreamController` feeds a `Stream` in Dart.
/// By exposing only the [coral] property to downstream consumers, it enforces a strict
/// separation between the data producer (imperative) and data consumers (declarative).
///
/// **Design Philosophy:**
/// - **Topological Root**: Acts as the absolute source of a topological graph. It can be
///   configured as a [CoralBroadcaster] (1:N) or a regular [CoralProvider] (1:1) via the
///   `broadcast` flag.
/// - **Compile-time / Initialization Fail-Fast**: The constructors contain strict assertions.
///   For instance, if a custom `equals` function is provided but `distinct` is set to `false`,
///   it intentionally throws an assertion error. This prevents "Silent Failures" where a
///   developer's explicit intention (the `equals` rule) would otherwise be silently ignored.
/// - **Lifecycle Awareness**: Using `lifecycle` constructors allows the controller to hook
///   into activation and deactivation events, enabling efficient resource allocation only
///   when active subscribers exist.
///
/// **Intended Usage & Data Flow Architecture (Push-Dirty, Pull-Data):**
/// Unlike traditional Streams that continuously flood data payloads down the pipeline,
/// CoralNode employs a highly efficient **Push-Dirty, Pull-Data** architecture.
///
/// #### The 4-Phase Flow:
///
/// **[Phase 1] Imperative Injection (Source)**
/// - Action: `controller.set(data)` is called.
/// - Result: Data is encapsulated into an immutable [CoralSnapshot] and cached at the root node.
///
/// **[Phase 2] Push-Dirty (Downstream Propagation)**
/// - Action: The root node broadcasts a lightweight "Dirty" flag down the topological graph.
/// - Result: Downstream nodes are marked as dirty, but **NO DATA IS PUSHED**.
///
/// **[Phase 3] Terminal Notification (Destination)**
/// - Action: The "Dirty" flag hits the [CoralTerminal] (e.g., a Flutter UI Widget).
/// - Result: The terminal triggers its `onDirty` callback (e.g., `setState()`), queuing a UI re-render.
///
/// **[Phase 4] Pull-Data & Lazy Computation (Upstream Traversal)**
/// - Action: During the UI render cycle, the terminal explicitly requests `.data`.
/// - Result: The terminal pulls data from its parent, triggering a reverse traversal
///   UP the graph. Only now are intermediate transformations (`map`, `derive`, `aggregate`)
///   executed. The results are cached at each node, and the computed data is handed to UI.
///
/// #### Why this matters?
/// This design guarantees that no matter how complex the pipeline transformations are, they are
/// executed **only once per UI render cycle** and only when strictly necessary, preventing
/// computational flooding and guaranteeing optimal performance.
///
/// **Example:**
/// ```dart
/// final controller = CoralController<int>(0);
///
/// // Imperative Injections
/// controller.set(10);           // Inject valid data
/// controller.empty();           // Inject an Empty state
/// controller.setError(e, s);    // Inject a Damaged state
///
/// // Guarded Injection: Automatically maps thrown exceptions to a Damaged state.
/// controller.setGuarded(() => int.parse('invalid'));
///
/// // Exposing to consumers
/// final Coral<int> pipeline = controller.coral;
/// ```
///
/// **AI & Developer Note:**
/// - **Distinct by Default**: By default, `distinct` is `true`. Injecting the exact same state
///   consecutively will NOT trigger a pipeline propagation. To force propagation on
///   identical data, you must explicitly set `distinct: false`.
/// - **Late Initialization Strictness**: If instantiated via [CoralController.late], the
///   controller starts in a pending/empty state. Attempting to force compute the pipeline
///   before an initial value is injected will trigger a Fail-Fast exception.
/// - **Broadcast Restrictions**: If multiple downstream branches (e.g., multiple UI widgets)
///   need to activate this pipeline independently, you MUST set `broadcast: true` to prevent
///   ownership/state collision errors.
base class CoralController<T> with CoralSnapshotDelegator<T> implements CoralProvider<T> {
  /// The standard constructor for [CoralController].
  ///
  /// Use this when an **initial value must exist** at the moment of creation.
  /// The pipeline becomes immediately valid and downstream consumers can pull
  /// data without exceptions.
  CoralController(
    T data, {
    this.broadcast = false,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
  })  : assert(equals == null || distinct, 'If [equals] is provided, [distinct] MUST be true.'),
        _outbound = distinct ? _DistinctEntryCoral<T>(data, equals: equals) : _EntryCoral<T>(data);

  /// The lazy initialization constructor for [CoralController].
  ///
  /// Use this when the controller must be instantiated early, but the
  /// **first data payload will arrive later** (e.g., after an async operation).
  ///
  /// The pipeline starts in an Empty/Pending state. If downstream attempts
  /// to pull `.data` before an initial [set] is called, it will intentionally
  /// throw a Fail-Fast exception.
  CoralController.late({
    this.broadcast = false,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
  })  : assert(equals == null || distinct, 'If [equals] is provided, [distinct] MUST be true.'),
        _outbound = distinct ? _DistinctEntryCoral<T>.late(equals: equals) : _EntryCoral<T>.late();

  /// The lifecycle-aware constructor for [CoralController].
  ///
  /// In addition to requiring an initial value, this allows the controller
  /// to react to the lifecycle state of its downstream subscribers.
  ///
  /// Use this to **allocate heavy resources (e.g., GPS tracking, WebSockets)
  /// only when a subscriber activates**, and release them upon deactivation.
  CoralController.lifecycle(
    T data, {
    this.broadcast = false,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  })  : assert(equals == null || distinct, 'If [equals] is provided, [distinct] MUST be true.'),
        assert(
          onActivated != null || onPaused != null || onResumed != null || onDeactivated != null,
          'At least one lifecycle callback (onActivated, onPaused, onResumed, or onDeactivated) must be provided. '
          'If you do not need callbacks, use the standard constructor instead.',
        ),
        _outbound = distinct
            ? _LifecycleObservableDistinctEntryCoral<T>(
                data,
                onActivated: onActivated,
                onPaused: onPaused,
                onResumed: onResumed,
                onDeactivated: onDeactivated,
                equals: equals,
              )
            : _LifecycleObservableEntryCoral<T>(
                data,
                onActivated: onActivated,
                onPaused: onPaused,
                onResumed: onResumed,
                onDeactivated: onDeactivated,
              );

  /// The combined late-initialization and lifecycle-aware constructor.
  ///
  /// Use this for the most deferred and heavy initialization patterns.
  /// It starts with no initial value and listens to downstream lifecycle.
  ///
  /// Perfect for scenarios where an API request should only be triggered
  /// upon the first subscriber connecting.
  CoralController.lateLifecycle({
    this.broadcast = false,
    bool distinct = true,
    bool Function(T previous, T next)? equals,
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  })  : assert(equals == null || distinct, 'If [equals] is provided, [distinct] MUST be true.'),
        assert(
          onActivated != null || onPaused != null || onResumed != null || onDeactivated != null,
          'At least one lifecycle callback (onActivated, onPaused, onResumed, or onDeactivated) must be provided. '
          'If you do not need callbacks, use CoralController.late instead.',
        ),
        _outbound = distinct
            ? _LifecycleObservableDistinctEntryCoral<T>.late(
                onActivated: onActivated,
                onPaused: onPaused,
                onResumed: onResumed,
                onDeactivated: onDeactivated,
                equals: equals,
              )
            : _LifecycleObservableEntryCoral<T>.late(
                onActivated: onActivated,
                onPaused: onPaused,
                onResumed: onResumed,
                onDeactivated: onDeactivated,
              );

  final _EntryCoral<T> _outbound;

  final bool broadcast;

  late final CoralProvider<T> _provider = broadcast ? CoralBroadcaster(_outbound) : CoralProvider.coral(_outbound);

  CoralProvider<T> get provider => _provider;

  @override
  bool get isActivated => _outbound._state.isActivated;

  @override
  bool get isRunning => _outbound._state.isRunning;

  @override
  bool get isPaused => _outbound._state.isPaused;

  @override
  bool get isDeactivated => _outbound._state.isDeactivated;

  @override
  Coral<T> get coral => provider.coral;

  @override
  CoralSnapshot<T> get snapshot => _outbound.snapshot;

  /// Injects a new data payload into the pipeline via the setter.
  ///
  /// This is functionally identical to [set] but provides a property-like assignment syntax.
  ///
  /// * [data]: The new data to inject.
  ///
  /// **Ensures:**
  /// * The pipeline encapsulates the data into a [CoralSnapshot] and broadcasts a dirty state downstream.
  set data(T data) => _outbound._performForwarding(CoralSnapshot(data));

  /// Injects a new data payload into the pipeline.
  ///
  /// This pushes dynamic data into the declarative flow.
  ///
  /// * [data]: The new data to inject.
  ///
  /// **Requires:**
  /// * If the controller was initialized with [CoralController.late], ensure this is called
  ///   before downstream attempts to pull the data.
  ///
  /// **Ensures:**
  /// * The data is encapsulated into an immutable [CoralSnapshot].
  /// * A "Dirty" flag is propagated down the topological graph to notify consumers.
  ///
  /// **Example:**
  /// ```dart
  /// final controller = CoralController<String>('initial');
  /// controller.set('new data');
  /// ```
  void set(T data) => _outbound._performForwarding(CoralSnapshot(data));

  /// Safely executes the [test] callback and injects its result.
  ///
  /// If [test] succeeds, the returned data is injected as a valid state.
  /// If [test] throws an exception, the pipeline gracefully catches it and
  /// injects a [CoralSnapshot.damaged] state, preventing app crashes.
  ///
  /// * [test]: A callback function that returns the data of type [T].
  ///
  /// **Ensures:**
  /// * If [test] succeeds, valid data is injected.
  /// * If [test] throws, a damaged state is injected containing the error and stack trace.
  ///
  /// **Example:**
  /// ```dart
  /// final controller = CoralController<int>(0);
  /// controller.setGuarded(() => int.parse('invalid')); // Injects damaged state gracefully
  /// ```
  void setGuarded(T Function() test) {
    late final CoralSnapshot<T> snapshot;
    try {
      snapshot = CoralSnapshot<T>(test.call());
    } catch (error, stackTrace) {
      snapshot = CoralSnapshot.damaged(error, stackTrace);
    }
    _outbound._performForwarding(snapshot);
  }

  /// Manually injects a damaged/error state into the pipeline.
  ///
  /// Use this when an external operation (like a network request) fails
  /// and you want to propagate the error downstream for UI error handling.
  ///
  /// * [error]: The error object representing the failure.
  /// * [stackTrace]: Optional stack trace associated with the error.
  ///
  /// **Ensures:**
  /// * A [CoralSnapshot.damaged] state is injected and propagated downstream.
  ///
  /// **Example:**
  /// ```dart
  /// final controller = CoralController<String>.late();
  /// try {
  ///   final data = await fetchNetworkData();
  ///   controller.set(data);
  /// } catch (e, st) {
  ///   controller.setError(e, st);
  /// }
  /// ```
  void setError(Object error, [StackTrace? stackTrace]) {
    _outbound._performForwarding(CoralSnapshot.damaged(error, stackTrace));
  }

  /// Manually injects an empty state into the pipeline.
  ///
  /// Use this to clear or reset the pipeline's data, which is useful for
  /// triggering loading states or clearing UI elements (e.g., search results).
  ///
  /// **Ensures:**
  /// * A [CoralSnapshot.empty] state is injected and propagated downstream.
  ///
  /// **Example:**
  /// ```dart
  /// final controller = CoralController<List<String>>(['item1', 'item2']);
  /// // Clear the list and trigger an empty UI state
  /// controller.empty();
  /// ```
  void empty() {
    _outbound._performForwarding(CoralSnapshot.empty());
  }
}

/// The imperative entry point (Source) that bridges dynamic collections of [Coral] lines
/// into a declarative [Trunk] pipeline.
///
/// **Core Concept (Separation of Concerns):**
/// In the Coralline framework, downstream [Trunk] objects are strictly read-only and define
/// an immutable flow of multi-line data. To dynamically update or replace the collection
/// of [Coral] lines (e.g., adding/removing form fields, dynamic tab pipelines, etc.),
/// an entity with write-access is required. [TrunkController] serves exactly this purpose
/// for [Trunk] bundles.
///
/// **Design Philosophy:**
/// - **Dynamic Collection Source**: Acts as an updatable root joint for a bundle of [Coral] lines.
///   Calling [set] or assigning [lines] updates the set of active lines in the trunk while
///   maintaining proper lifecycle coupling and detaching removed lines.
/// - **Compile-time / Initialization Fail-Fast**: The constructors contain strict assertions.
///   Using `lifecycle` constructors allows the controller to hook into activation and
///   deactivation events, enabling efficient resource allocation only when active subscribers exist.
///
/// **Intended Usage & Data Flow Architecture (Push-Dirty, Pull-Data):**
/// Functions identically to [CoralController] within the Coralline framework's **Push-Dirty, Pull-Data**
/// architecture, but operates on collections of [Coral] lines.
///
/// **Example:**
/// ```dart
/// final controller = TrunkController<String>([emailCoral, passwordCoral]);
///
/// // Dynamically replace lines (e.g., when switching login method)
/// controller.set([phoneCoral, smsCodeCoral]);
///
/// // Exposing to consumers
/// final Trunk<String> pipeline = controller.trunk;
/// ```
base class TrunkController<T> with TrunkSnapshotDelegator<T> implements TrunkProvider<T> {
  /// The standard constructor for [TrunkController].
  ///
  /// Use this when an **initial collection of lines must exist** at the moment of creation.
  /// The pipeline becomes immediately valid and downstream consumers can pull
  /// data without exceptions.
  ///
  /// * [seal]: If `true` (default), lines are permanently owned by this controller and
  ///   cannot be detached by another parent without explicit release.
  /// * [hotswap]: If `true`, supports hotswapping lines while active using a mooring point safeguard.
  TrunkController(Iterable<Coral<T>> lines, {bool seal = true, bool hotswap = false})
      : _outbound = switch ((seal, hotswap)) {
          (true, true) => _SealedHotswapControlledTrunk<T>(lines),
          (true, false) => _SealedColdswapControlledTrunk<T>(lines),
          (false, true) => _DetachableHotswapControlledTrunk<T>(lines),
          (false, false) => _DetachableColdswapControlledTrunk<T>(lines),
        };

  /// The lazy initialization constructor for [TrunkController].
  ///
  /// Use this when the controller must be instantiated early, but the
  /// **first collection of lines will arrive later** (e.g., after an async operation).
  ///
  /// The pipeline starts in an Empty/Pending state. If downstream attempts
  /// to pull `.lines` before an initial [set] is called, it will intentionally
  /// throw a Fail-Fast exception.
  ///
  /// * [seal]: If `true` (default), lines are permanently owned by this controller.
  /// * [hotswap]: If `true`, supports hotswapping lines while active using a mooring point safeguard.
  TrunkController.late({bool seal = true, bool hotswap = false})
      : _outbound = switch ((seal, hotswap)) {
          (true, true) => _SealedHotswapControlledTrunk<T>.late(),
          (true, false) => _SealedColdswapControlledTrunk<T>.late(),
          (false, true) => _DetachableHotswapControlledTrunk<T>.late(),
          (false, false) => _DetachableColdswapControlledTrunk<T>.late(),
        };

  final _UpdatableTrunk<T> _outbound;

  TrunkProvider<T> get provider => this;

  @override
  bool get isActivated => _outbound._state.isActivated;

  @override
  bool get isRunning => _outbound._state.isRunning;

  @override
  bool get isPaused => _outbound._state.isPaused;

  @override
  bool get isDeactivated => _outbound._state.isDeactivated;

  @override
  Trunk<T> get trunk => _outbound;

  @override
  TrunkSnapshot<T> get snapshot => _outbound.snapshot;

  /// Injects a new collection of lines into the pipeline via the setter.
  ///
  /// This is functionally identical to [set] but provides a property-like assignment syntax.
  ///
  /// * [lines]: The new collection of [Coral<T>] lines to inject.
  ///
  /// **Ensures:**
  /// * A "Dirty" flag is propagated down the topological graph to notify consumers.
  set lines(Iterable<Coral<T>> lines) => _outbound._performUpdate(lines);

  /// Injects a new collection of lines into the pipeline.
  ///
  /// * [lines]: The new collection of [Coral<T>] lines to inject.
  ///
  /// **Requires:**
  /// * If the controller was initialized with [TrunkController.late], ensure this is called
  ///   before downstream attempts to pull the lines.
  ///
  /// **Ensures:**
  /// * A "Dirty" flag is propagated down the topological graph to notify consumers.
  void set(Iterable<Coral<T>> lines) => _outbound._performUpdate(lines);

  /// Safely executes the [test] callback and injects its resulting lines.
  ///
  /// If [test] succeeds, the returned lines are updated into the pipeline.
  /// If [test] throws an exception, the pipeline gracefully catches it and
  /// injects a damaged state, preventing app crashes.
  ///
  /// * [test]: A callback function returning an `Iterable<Coral<T>>`.
  void setGuarded(Iterable<Coral<T>> Function() test) {
    _outbound._performUpdateGuarded(test);
  }

  /// Manually injects a damaged/error state into the pipeline.
  ///
  /// * [error]: The error object representing the failure.
  /// * [stackTrace]: Optional stack trace associated with the error.
  void setError(Object error, [StackTrace? stackTrace]) {
    _outbound._setError(error, stackTrace);
  }

  /// Manually releases the pipeline, putting it into an empty state.
  ///
  /// **Ensures:**
  /// * A [TrunkSnapshot.empty] state is injected and propagated downstream.
  void release() {
    _outbound._performRelease();
  }
}

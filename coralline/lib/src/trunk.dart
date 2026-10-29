// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// A snapshot representing the immutable state of a [Trunk] at a specific point in time.
///
/// **Core Concept (Bundle State):**
/// In the [CoralNode] framework, while a [Coral] represents a single-value reactive node,
/// a [Trunk] represents a composite node managing multiple [Coral] lines.
/// Just as [CoralSnapshot] captures the state of a single payload, this [TrunkSnapshot]
/// captures the macroscopic state of the entire bundle.
///
/// If the foundational process that generates this bundle fails (e.g., a fatal error
/// in the upstream data source or a crash during transformation logic), or if a developer
/// intentionally invalidates the entire bundle due to business logic (Manual Damaging),
/// this snapshot will be marked as damaged. (Note: This is strictly distinct from
/// individual lines failing inside a valid bundle). This design guarantees that downstream
/// consumers cannot accidentally process a structurally compromised pipeline.
@immutable
sealed class TrunkSnapshot<T> extends CorallineSnapshot {
  /// Creates a valid [TrunkSnapshot] holding the specified [lines].
  ///
  /// * [lines]: The collection of [Coral] lines to materialize into an unmodifiable list.
  ///
  /// **Design Philosophy (Constructor-Level Defensive Immutability):**
  /// The underlying implementation (`_TrunkSnapshot`) automatically materializes and freezes
  /// the incoming [lines] using `List.unmodifiable` during initialization.
  ///
  /// **Performance & Memory Guidance:**
  /// Callers SHOULD NOT pre-wrap or pre-convert [lines] into an unmodifiable list prior to passing
  /// it into this factory. Doing so causes redundant list allocations and heap duplication.
  /// Simply pass the raw or lazy [lines] iterable directly; the constructor guarantees complete
  /// immutability and defensive copying safely.
  factory TrunkSnapshot(Iterable<Coral<T>> lines) = _TrunkSnapshot;

  /// Creates a damaged [TrunkSnapshot] encapsulating [error] and optional [stackTrace].
  ///
  /// * [error]: The structural error or exception cause for this damaged state.
  /// * [stackTrace]: Optional stack trace associated with [error].
  const factory TrunkSnapshot.damaged(Object error, [StackTrace? stackTrace]) = _DamagedTrunkSnapshot;

  /// Creates an uninitialized (`empty`) [TrunkSnapshot].
  const factory TrunkSnapshot.empty() = _EmptyTrunkSnapshot;

  /// Extracts the underlying list of multiple [Coral] lines managed by this trunk.
  ///
  /// **Design Philosophy (Fail-Fast Enforcement):**
  /// This property enforces strict topological integrity. If the trunk itself is
  /// uninitialized ([isEmpty]) or has encountered a structural failure ([isDamaged]),
  /// attempting to read [lines] will immediately throw a [CoralSnapshotExtractionException].
  ///
  /// This prevents downstream operations from executing with invalid or missing
  /// topological configurations. If you cannot guarantee the trunk is valid, use
  /// [linesOrNull] or [linesOrEmpty] instead.
  ///
  /// **Requires:**
  /// * The trunk snapshot must be in an [isValid] state.
  ///
  /// **Throws:**
  /// * [CoralSnapshotExtractionException] if [isValid] is `false` (i.e., [isEmpty] or
  ///   [isDamaged] is `true`).
  ///
  /// ## Examples
  /// ```dart
  /// final snapshot = TrunkSnapshot<int>([Coral.data(1), Coral.data(2)]);
  /// if (snapshot.isValid) {
  ///   final activeLines = snapshot.lines;
  ///   print('Trunk has ${activeLines.length} active lines.');
  /// }
  /// ```
  List<Coral<T>> get lines;

  /// Safely extracts the list of multiple [Coral] lines, returning `null` if not in a valid state.
  ///
  /// **Design Philosophy (Graceful Degradation):**
  /// Unlike [lines], this getter acts as a safe fallback that downgrades [isEmpty] or
  /// [isDamaged] states to a simple Dart `null` instead of throwing an exception.
  /// Use this when the absence of lines is a normal, handlable condition in your
  /// downstream logic.
  ///
  /// **Ensures:**
  /// * Returns `null` if [isValid] is `false`.
  /// * Otherwise, returns the non-null list of [Coral] lines.
  ///
  /// ## Examples
  /// ```dart
  /// final snapshot = TrunkSnapshot<int>.empty();
  /// final lines = snapshot.linesOrNull;
  /// if (lines != null) {
  ///   print('Processing ${lines.length} lines.');
  /// } else {
  ///   print('Trunk is empty or damaged.');
  /// }
  /// ```
  List<Coral<T>>? get linesOrNull;

  /// Safely extracts [Coral] lines, returning an empty unmodifiable list if invalid.
  ///
  /// **Design Philosophy (Null-Safety and Empty-Safety):**
  /// Similar to [linesOrNull], this getter avoids throwing exceptions. Instead, it returns
  /// a safe, empty [List] (`const <Coral<T>>[]`), which allows you to perform list operations
  /// (like iteration or mapping) directly without checking for null or validity.
  ///
  /// **Ensures:**
  /// * Returns a valid, read-only [List] of [Coral]s under all circumstances.
  /// * Returns an empty list if [isValid] is `false`.
  ///
  /// ## Examples
  /// ```dart
  /// final snapshot = TrunkSnapshot<String>.empty();
  /// // Safe to map over lines even if the trunk is empty or damaged
  /// final titles = snapshot.linesOrEmpty.map((line) => line.dataOrNull).toList();
  /// ```
  List<Coral<T>> get linesOrEmpty;

  /// Whether this trunk snapshot contains a valid, extractable collection of [Coral] lines.
  ///
  /// **Core Concept & Purpose:**
  /// Enforces topological state integrity by validating that the trunk snapshot is neither empty nor damaged.
  /// Reading `.lines` is guaranteed to be safe and fail-fast exception-free when `isValid` is `true`.
  ///
  /// **Return Value Meaning:**
  /// * `true`: The trunk snapshot holds valid [Coral] lines. Safely read `.lines`.
  /// * `false`: The trunk snapshot is uninitialized ([isEmpty]) or corrupted ([isDamaged]).
  @override
  bool get isValid;

  /// Whether this trunk snapshot is in an uninitialized or dormant state.
  ///
  /// **Core Concept & Purpose:**
  /// Indicates that no multi-line topology or error has been produced yet. Used as a safe initial state for
  /// dynamic trunk sockets like `TrunkCoupler.late()` before a source group is connected.
  ///
  /// **Return Value Meaning:**
  /// * `true`: Uninitialized trunk state (`TrunkSnapshot.empty()`).
  /// * `false`: Holds valid [Coral] lines or an error state.
  ///
  /// **Precautions:**
  /// * Direct access to `.lines` when `isEmpty` is `true` throws a [CoralSnapshotExtractionException].
  ///   Use `.linesOrNull` or `.linesOrEmpty` for safe extraction when `isEmpty` is possible.
  @override
  bool get isEmpty;

  /// Whether this trunk snapshot is in a corrupted state containing a structural error or exception.
  ///
  /// **Core Concept & Purpose:**
  /// Isolates topological trunk failures into a first-class declarative snapshot without crashing application threads.
  ///
  /// **Return Value Meaning:**
  /// * `true`: Holds a structural exception ([error]) and optional stack trace ([stackTrace]).
  /// * `false`: Holds valid [Coral] lines or is uninitialized.
  ///
  /// **Precautions:**
  /// * Reading `.error` or `.stackTrace` when `isDamaged` is `false` throws a [CoralSnapshotStateException].
  ///   Always check `isDamaged` before inspecting error properties.
  @override
  bool get isDamaged;

  /// Extracts the underlying exception or structural failure object from a damaged trunk snapshot.
  ///
  /// **Requires:**
  /// * Must only be called when [isDamaged] is `true`.
  ///
  /// **Throws:**
  /// * [CoralSnapshotStateException] if [isDamaged] is `false`.
  @override
  Object get error;

  /// Extracts the call stack trace at the point of failure from a damaged trunk snapshot.
  ///
  /// **Requires:**
  /// * Must only be called when [isDamaged] is `true`.
  ///
  /// **Throws:**
  /// * [CoralSnapshotStateException] if [isDamaged] is `false`.
  @override
  StackTrace get stackTrace;
}

/// A mixin that forwards all [TrunkSnapshot] properties and accessors directly
/// to the implementing class.
///
/// **Design Philosophy (Ergonomics):**
/// By mixing this into [Trunk] (and related nodes like [TrunkTerminal]), developers
/// can access [isEmpty], [isValid], and [lines] directly on the node instance
/// without having to explicitly unwrap `.snapshot` first (e.g., `trunk.lines`
/// instead of `trunk.snapshot.lines`). This dramatically reduces boilerplate
/// in high-frequency UI computation code.
mixin TrunkSnapshotDelegator<T> implements CorallineSnapshotDelegator<TrunkSnapshot<T>> {
  @override
  TrunkSnapshot<T> get snapshot;

  @override
  @pragma('vm:prefer-inline')
  bool get isEmpty => snapshot.isEmpty;

  @override
  @pragma('vm:prefer-inline')
  bool get isDamaged => snapshot.isDamaged;

  @override
  @pragma('vm:prefer-inline')
  bool get isValid => snapshot.isValid;

  /// Extracts the underlying list of [Coral] lines from [snapshot].
  ///
  /// See [TrunkSnapshot.lines] for details.
  @pragma('vm:prefer-inline')
  List<Coral<T>> get lines => snapshot.lines;

  /// Safely extracts the list of [Coral] lines from [snapshot], or returns `null` if invalid.
  ///
  /// See [TrunkSnapshot.linesOrNull] for details.
  @pragma('vm:prefer-inline')
  List<Coral<T>>? get linesOrNull => snapshot.linesOrNull;

  /// Safely extracts the list of [Coral] lines from [snapshot], or returns an empty unmodifiable list if invalid.
  ///
  /// See [TrunkSnapshot.linesOrEmpty] for details.
  @pragma('vm:prefer-inline')
  List<Coral<T>> get linesOrEmpty => snapshot.linesOrEmpty;

  @override
  @pragma('vm:prefer-inline')
  Object get error => snapshot.error;

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace => snapshot.stackTrace;
}

/// The structural foundation for managing multiple [Coral] pipelines as a single, unified topological entity.
///
/// **Core Concept (Bundle Node):**
/// While a [Coral] node represents a discrete, single-value reactive pipeline (1:1),
/// a [Trunk] groups an `Iterable<Coral<T>>` into a cohesive bundle (1:N). It acts
/// as a macroscopic state manager, allowing downstream nodes to compute or
/// transform the entire collection as a single unit without breaking the reactive graph.
///
/// ## System Architectural Flow
/// ```text
/// [Coral Line 1] ──┐
/// [Coral Line 2] ──┼──> [Trunk<T> Bundle] ──> Push Dirty ──> [Downstream Terminal]
/// [Coral Line N] ──┘         │
///                            └──> Lazy Pull Aggregation / Combine / Converge
/// ```
///
/// **Warning (Anti-Pattern Prevention):**
///
/// * **BAD (Repeatedly calling `.toTrunk()` in high-frequency loops/reads):**
///   ```dart
///   final coralA = Coral.data(1);
///   final coralB = Coral.data(2);
///   // Anti-pattern: Re-bundling corals on every read reallocates topology nodes
///   String renderCombined() {
///     final trunk = [coralA, coralB].toTrunk(); // Re-creates pipeline on every call
///     return '${trunk.combine().data}';
///   }
///   ```
/// * **GOOD (Declare trunk pipeline once):**
///   ```dart
///   final coralA = Coral.data(1);
///   final coralB = Coral.data(2);
///   // Recommended: Bundle lines once during initialization
///   late final Trunk<int> trunk = [coralA, coralB].toTrunk();
///   ```
///
/// **Intended Usage (Static Factories):**
/// Use [Trunk.of] to bundle a collection of [Coral] lines. Use [Trunk.damaged] to
/// represent a structural failure of the bundle, or [Trunk.empty] to create an
/// instant trunk containing an empty list of lines (`const []`, with `isValid == true`;
/// note that an uninitialized trunk snapshot is represented by [TrunkSnapshot.empty]).
sealed class Trunk<T> extends CoralNode with TrunkSnapshotDelegator<T> {
  /// Creates a [Trunk] pipeline bundling the given collection of [lines].
  ///
  /// * [lines]: The collection of [Coral] nodes to bundle into this trunk.
  /// * [seal]: If `true` (default), bundled lines are permanently owned by this trunk
  ///   and cannot be detached or claimed by external downstream parents without explicit release.
  /// * [hotswap]: If `true` (only applicable when [seal] is `false`), enables mooring point
  ///   safeguards for bundled lines when they are swapped or claimed by downstream parent nodes
  ///   while active.
  ///
  /// **Requires:**
  /// * If [seal] is `true`, [hotswap] must be `false`.
  ///
  /// **Note on [hotswap]:**
  /// While [Trunk.of] itself is a read-only bundle and does not expose dynamic write operations,
  /// setting [seal] to `false` permits *external* downstream nodes (e.g., couplers, converging or
  /// diverging trunks) to claim or swap child lines out of this trunk. Setting [hotswap] to `true`
  /// ensures that if an active child line is detached by an external node, it is safely transferred
  /// to a mooring point safeguard rather than immediately deactivated.
  factory Trunk.of(Iterable<Coral<T>> lines, {bool seal = true, bool hotswap = false}) {
    assert(
      !seal || !hotswap,
      'Hotswap cannot be enabled when seal is true because sealed lines cannot be swapped or detached.',
    );
    return seal
        ? _SealedTrunk<T>(lines)
        : hotswap
            ? _DetachableHotswapTrunk<T>(lines)
            : _DetachableColdswapTrunk<T>(lines);
  }

  /// Creates a static, instant [Trunk] in a `damaged` state storing [error] and optional [stackTrace].
  ///
  /// * [error]: The structural error or exception payload causing the damaged state.
  /// * [stackTrace]: Optional stack trace associated with [error].
  factory Trunk.damaged(Object error, [StackTrace? stackTrace]) = _InstantTrunk.damaged;

  /// Creates a static, instant [Trunk] holding an empty list of lines (`const []`, with `isValid == true`).
  factory Trunk.empty() = _InstantTrunk.empty;

  /// Whether this pipeline node has been activated by at least one downstream branch.
  @override
  bool get isActivated;

  /// Whether this pipeline node is currently running.
  @override
  bool get isRunning;

  /// Whether this pipeline node is temporarily paused.
  @override
  bool get isPaused;

  /// Whether this pipeline node is currently in the deactivated (inactive) state.
  @override
  bool get isDeactivated;

  /// The latest snapshot data of this pipeline node.
  @override
  TrunkSnapshot<T> get snapshot;

  /// Whether the snapshot is currently in an uninitialized (empty) state.
  @override
  bool get isEmpty;

  /// Whether the snapshot is currently in a corrupted (damaged) state.
  @override
  bool get isDamaged;

  /// Whether the snapshot currently contains a valid data payload.
  @override
  bool get isValid;

  /// Extracts the underlying list of [Coral] lines from this trunk's [snapshot].
  ///
  /// See [TrunkSnapshot.lines] for details.
  @override
  List<Coral<T>> get lines;

  /// Safely extracts the list of [Coral] lines from this trunk's [snapshot], or returns `null` if invalid.
  ///
  /// See [TrunkSnapshot.linesOrNull] for details.
  @override
  List<Coral<T>>? get linesOrNull;

  /// Safely extracts the list of [Coral] lines from this trunk's [snapshot], or returns an empty unmodifiable list if invalid.
  ///
  /// See [TrunkSnapshot.linesOrEmpty] for details.
  @override
  List<Coral<T>> get linesOrEmpty;

  /// Extracts the structural error object from this trunk's [snapshot] when [isDamaged] is `true`.
  ///
  /// See [TrunkSnapshot.error] for details.
  @override
  Object get error;

  /// Extracts the stack trace from this trunk's [snapshot] when [isDamaged] is `true`.
  ///
  /// See [TrunkSnapshot.stackTrace] for details.
  @override
  StackTrace get stackTrace;
}

/// A read-only provider interface that exposes a reactive [Trunk] bundle and its [CorallineLifecycleStatus].
abstract interface class TrunkProvider<T> implements CorallineLifecycleStatus {
  /// The underlying [Trunk] instance managed by this provider.
  Trunk<T> get trunk;

  /// Whether the underlying [trunk] pipeline node has been activated.
  @override
  bool get isActivated;

  /// Whether the underlying [trunk] pipeline node is currently running.
  @override
  bool get isRunning;

  /// Whether the underlying [trunk] pipeline node is temporarily paused.
  @override
  bool get isPaused;

  /// Whether the underlying [trunk] pipeline node is currently in the deactivated (inactive) state.
  @override
  bool get isDeactivated;
}

/// Convenience conversion methods for [Trunk] pipelines.
extension TrunkExtension<T> on Trunk<T> {
  /// Connects this [Trunk] bundle to a [TrunkTerminal] with the given [onDirty] callback.
  ///
  /// * [onDirty]: Callback invoked when this trunk marks the terminal dirty.
  TrunkTerminal<T> toTerminal(void Function() onDirty) => TrunkTerminal<T>(this, onDirty: onDirty);
}

/// Convenience conversion extensions available directly on any [TrunkProvider].
extension TrunkProviderExtension<T> on TrunkProvider<T> {
  /// Connects this provider's underlying [trunk] to a [TrunkTerminal] with the given [onDirty] callback.
  ///
  /// * [onDirty]: Callback invoked when the underlying [trunk] marks the terminal dirty.
  TrunkTerminal<T> toTerminal(void Function() onDirty) => trunk.toTerminal(onDirty);
}

/// Declarative aggregation, combination, and convergence operators for [Trunk] bundles.
extension TrunkComputationExtension<S> on Trunk<S> {
  /// Computes the contents of the trunk and reduces multiple inbound [Coral] lines into a single scalar value.
  ///
  /// **Core Concept (Scalar Aggregation):**
  /// Acts as the primary bridging operator to convert a [Trunk] (1:N) back into
  /// a standard [Coral] (1:1) node. It exposes the entire collection of inbound
  /// lines so they can be synchronously folded or transformed.
  ///
  /// * [aggregator]: Pure synchronous function folding the inbound [Coral] lines into a single `T` value.
  ///
  /// **Requires:**
  /// * The [aggregator] callback MUST be a pure, synchronous function with no side effects.
  ///
  /// ## Examples
  /// ```dart
  /// final trunk = Trunk.of([Coral.data(10), Coral.data(20)]);
  /// final sumCoral = trunk.aggregate((lines) => lines.fold(0, (sum, line) => sum + line.data));
  /// ```
  Coral<T> aggregate<T>(T Function(Iterable<Coral<S>> lines) aggregator) =>
      _TrunkAggregator(this, aggregator: aggregator);

  /// Extracts the `.data` payload from every inbound line and bundles them into a single `Coral<List<S>>`.
  ///
  /// **Core Concept (Type-Safe Combination):**
  /// Data flowing through the graph must be strictly immutable to guarantee
  /// predictable state. Therefore, this operator ensures the returned list is
  /// explicitly unmodifiable.
  ///
  /// **Ensures:**
  /// * Returns a [Coral] containing an unmodifiable list of the underlying data.
  Coral<List<S>> combine() => _TrunkAggregator<S, List<S>>(this, aggregator: (lines) => List.unmodifiable(lines.data));

  /// Computes the trunk and converges it into a completely new, dynamically generated downstream [Coral] node.
  ///
  /// **Core Concept (Dynamic Topological Convergence):**
  /// While [aggregate] transforms data into a scalar value, [converge] transforms
  /// data into a new topological pipeline. This enables use cases
  /// where the architecture of the downstream graph itself depends on the state
  /// of the upstream trunk (e.g., swapping a repository node based on an auth trunk).
  ///
  /// * [cascade]: Builder callback receiving the inbound [Coral] lines and returning the converged [Coral] node.
  /// * [seal]: If `true`, the converged node is strictly bound to this parent and cannot be stolen. Defaults to `true`.
  /// * [hotswap]: If `true`, defers deactivation of the previous converged node to the end of the microtask. Defaults to `false`.
  /// * [eager]: If `true`, evaluates [cascade] and attaches the converged node eagerly during dirty propagation. Defaults to `false`.
  ///
  /// ## Examples
  /// ```dart
  /// // 1. Define independent validation pipelines (Corals) for each login method
  /// final emailValidationCoral = Coral.data(true);
  /// final phoneValidationCoral = Coral.data(false);
  ///
  /// // 2. A pipeline representing the user's currently selected tab ('email' vs 'phone')
  /// final loginMethodCoral = Coral.data('email');
  ///
  /// // 3. Wrap the state in a Trunk to compute dynamic topological routing
  /// final authStateTrunk = Trunk.of([loginMethodCoral]);
  ///
  /// // 4. Dynamically route to the active validation pipeline
  /// final isSubmitEnabledCoral = authStateTrunk.converge((lines) {
  ///   final method = lines.first.snapshot.data;
  ///   return method == 'email' ? emailValidationCoral : phoneValidationCoral;
  /// }, hotswap: true);
  ///
  /// // 5. Final Terminal observing the actively routed pipeline
  /// final terminal = isSubmitEnabledCoral.toTerminal(() {
  ///   print('Submit enabled: ${isSubmitEnabledCoral.data}');
  /// });
  /// ```
  Coral<T> converge<T>(
    Coral<T> Function(Iterable<Coral<S>> lines) cascade, {
    bool seal = true,
    bool hotswap = false,
    bool eager = false,
  }) =>
      switch ((seal, hotswap, eager)) {
        (true, true, true) => _SealedHotswapEagerConvergingCoral<S, T>(this, cascade: cascade),
        (true, true, false) => _SealedHotswapLazyConvergingCoral<S, T>(this, cascade: cascade),
        (true, false, true) => _SealedColdswapEagerConvergingCoral<S, T>(this, cascade: cascade),
        (true, false, false) => _SealedColdswapLazyConvergingCoral<S, T>(this, cascade: cascade),
        (false, true, true) => _DetachableHotswapEagerConvergingCoral<S, T>(this, cascade: cascade),
        (false, true, false) => _DetachableHotswapLazyConvergingCoral<S, T>(this, cascade: cascade),
        (false, false, true) => _DetachableColdswapEagerConvergingCoral<S, T>(this, cascade: cascade),
        (false, false, false) => _DetachableColdswapLazyConvergingCoral<S, T>(this, cascade: cascade),
      };
}

/// Computation operators available directly on any [TrunkProvider].
///
/// Automatically delegates operations to the underlying [Trunk] node.
extension TrunkProviderComputationExtension<S> on TrunkProvider<S> {
  /// Delegates [TrunkComputationExtension.aggregate] to the underlying [Trunk].
  ///
  /// * [aggregate]: Pure synchronous function folding the inbound [Coral] lines into a single `T` value.
  Coral<T> aggregate<T>(T Function(Iterable<Coral<S>> lines) aggregate) => trunk.aggregate(aggregate);

  /// Delegates [TrunkComputationExtension.combine] to the underlying [Trunk].
  Coral<List<S>> combine() => trunk.combine();

  /// Delegates [TrunkComputationExtension.converge] to the underlying [Trunk].
  ///
  /// * [cascade]: Builder callback receiving the inbound [Coral] lines and returning the converged [Coral] node.
  /// * [seal]: If `true`, the converged node is strictly bound to this parent.
  /// * [hotswap]: If `true`, defers deactivation of the previous converged node to the end of the microtask.
  /// * [eager]: If `true`, evaluates [cascade] eagerly during dirty propagation.
  Coral<T> converge<T>(
    Coral<T> Function(Iterable<Coral<S>> lines) cascade, {
    bool seal = true,
    bool hotswap = false,
    bool eager = false,
  }) =>
      trunk.converge(cascade, seal: seal, hotswap: hotswap, eager: eager);
}

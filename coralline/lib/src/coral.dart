// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// An immutable, atomic container that encapsulates the precise state and data of a
/// [Coral] node at a specific point in time.
///
/// **Core Concept (State Integrity & Determinism):**
/// In the CoralNode framework, data never flows as raw values; it is always strictly packaged
/// inside a [CoralSnapshot]. This architectural decision guarantees absolute state
/// determinism across the topological graph. A snapshot can exist in exactly one of three
/// mutually exclusive states at any given moment:
/// - **Valid**: Contains safely resolvable data (even if that data is `null`).
/// - **Empty**: Represents a state where data has not yet been provided or has been cleared.
/// - **Damaged**: Contains an error and an optional stack trace resulting from a failed computation.
///
/// By coupling the data payload with its explicit state, the framework prevents "Silent Failures"
/// — scenarios where errors or empty conditions are inadvertently swallowed, causing
/// downstream nodes to compute on polluted or missing data.
///
/// **Design Philosophy (Pipeline-Level Null Safety):**
/// This class elevates **Dart's Sound Null Safety philosophy** from the language level
/// to the pipeline level. In traditional reactive programming (like `Stream`), developers
/// frequently use `null` as a makeshift indicator for "loading", "no data yet", or
/// "uninitialized". This conflation creates critical ambiguity: does `null` mean the
/// pipeline hasn't emitted yet, or did the pipeline explicitly emit a `null` value?
///
/// CoralNode completely eradicates this ambiguity. In a [CoralSnapshot], **`null` is NEVER
/// treated as a missing state.** Instead, `null` is respected as a perfectly valid, explicit
/// data payload (e.g., `CoralSnapshot<String?>(null)`). The concept of "no data" is completely
/// segregated into its own dedicated type ([CoralSnapshot.empty]). This allows the
/// framework to safely and accurately process nullable data flows without logical overlap.
///
/// **Implementation note (Fail-Fast Enforcement):**
/// The snapshot acts as a physical barrier that stops the pipeline from blindly computing
/// incomplete or corrupted data. If a developer attempts to directly extract the [data]
/// property from an `empty` or `damaged` snapshot, the framework triggers a **Fail-Fast**
/// exception immediately.
///
/// This is not a bug, but a core design choice:
/// - It prevents unhandled errors from propagating deep into the UI or business logic.
/// - It forces developers to handle anomalies *at the extraction site*.
///
/// To bypass this strict validation, developers must explicitly declare their intent by using:
/// - [dataOrNull]: Safely downgrades an `empty` or `damaged` state to a Dart `null` (returning `T?`).
/// - [dataOrElse]: Provides a fallback value if the snapshot is not valid.
///
/// **Example:**
/// ```dart
/// final snapshot = CoralSnapshot<int?>(null); // Valid state containing 'null'
///
/// if (snapshot.isValid) {
///   // Safe to extract. In this case, prints 'null'.
///   print(snapshot.data);
/// } else if (snapshot.isDamaged) {
///   print('Pipeline is in an error state.');
/// }
///
/// // Explicit anomaly handling without manual type checks
/// final safeValue = snapshot.dataOrNull;
/// final fallbackValue = snapshot.dataOrElse(() => 0);
/// ```
@immutable
sealed class CoralSnapshot<T> extends CorallineSnapshot {
  /// Creates a valid [CoralSnapshot] encapsulating [data].
  ///
  /// * [data]: The payload value held by this snapshot (may be `null` if `T` is nullable).
  const factory CoralSnapshot(T data) = _CoralSnapshot;

  /// Creates a damaged [CoralSnapshot] encapsulating [error] and optional [stackTrace].
  ///
  /// * [error]: The error or exception cause for this damaged state.
  /// * [stackTrace]: Optional stack trace associated with [error].
  const factory CoralSnapshot.damaged(Object error, [StackTrace? stackTrace]) = _DamagedCoralSnapshot;

  /// Creates an uninitialized (`empty`) [CoralSnapshot].
  const factory CoralSnapshot.empty() = _EmptyCoralSnapshot;

  /// Extracts the underlying data synchronously from this node's snapshot.
  ///
  /// **Design Philosophy (Fail-Fast Enforcement):**
  /// This property enforces strict state integrity at the extraction site. If the
  /// snapshot is currently uninitialized ([isEmpty]) or has encountered a failure
  /// ([isDamaged]), reading this property will immediately throw a
  /// [CoralSnapshotExtractionException].
  ///
  /// This fail-fast mechanism prevents upstream errors or empty states from silently
  /// cascading and polluting downstream operations. If the node state might not be
  /// valid, explicitly handle it using [dataOrNull] or [dataOrElse].
  ///
  /// **Requires:**
  /// * The snapshot must be in an [isValid] state.
  ///
  /// **Throws:**
  /// * [CoralSnapshotExtractionException] if [isValid] is `false` (i.e., [isEmpty] or
  ///   [isDamaged] is `true`).
  ///
  /// ## Examples
  /// ```dart
  /// final snapshot = CoralSnapshot<int>(42);
  /// if (snapshot.isValid) {
  ///   final val = snapshot.data;
  ///   print('Data: $val');
  /// }
  /// ```
  T get data;

  /// Safely extracts the underlying data, returning `null` if the snapshot is not in a valid state.
  ///
  /// **Design Philosophy (Graceful Degradation):**
  /// Unlike [data], this getter downgrades [isEmpty] or [isDamaged] states to a simple
  /// Dart `null` instead of throwing an exception. Use this when a missing value or
  /// error is expected and can be gracefully handled with null-safety operators.
  ///
  /// **Ensures:**
  /// * Returns `null` if [isValid] is `false`.
  /// * Otherwise, returns the non-null (or nullable if type `T` is nullable) data payload.
  ///
  /// ## Examples
  /// ```dart
  /// final snapshot = CoralSnapshot<int>.empty();
  /// final value = snapshot.dataOrNull;
  /// if (value != null) {
  ///   print('Received value: $value');
  /// } else {
  ///   print('Node is uninitialized or in a failed state.');
  /// }
  /// ```
  T? get dataOrNull;

  /// Safely extracts the underlying data, returning the result of [fallback] if not in a valid state.
  ///
  /// **Design Philosophy (Default-Value Integration):**
  /// Provides an inline, semantic way to handle missing or corrupted data by supplying
  /// a fallback generator function. This allows pipelines to continue computing with
  /// default/mock data without breaking.
  ///
  /// * [fallback]: Callback invoked to produce a replacement value when [isValid] is `false`.
  ///
  /// **Ensures:**
  /// * Returns the underlying data if [isValid] is `true`.
  /// * Otherwise, invokes and returns the result of [fallback].
  ///
  /// ## Examples
  /// ```dart
  /// final snapshot = CoralSnapshot<String>.empty();
  /// final value = snapshot.dataOrElse(() => 'Default Value');
  /// print('Result: $value');
  /// ```
  T dataOrElse(T Function() fallback);

  /// Whether this snapshot contains a valid, extractable data payload.
  ///
  /// **Core Concept & Purpose:**
  /// Enforces state integrity by validating that the snapshot is neither empty nor damaged.
  /// Reading `.data` is guaranteed to be safe and fail-fast exception-free when `isValid` is `true`.
  ///
  /// **Return Value Meaning:**
  /// * `true`: The snapshot holds a valid data payload. Safely read `.data`.
  /// * `false`: The snapshot is uninitialized ([isEmpty]) or corrupted ([isDamaged]).
  ///
  /// **Precautions:**
  /// * Note that even if `data` is a Dart `null` value (e.g., `CoralSnapshot<int?>(null)`), `isValid`
  ///   returns `true` because `null` is a valid payload for nullable types.
  @override
  bool get isValid;

  /// Whether this snapshot is in an uninitialized or dormant state.
  ///
  /// **Core Concept & Purpose:**
  /// Indicates that no data or error has been produced yet. Used as a safe initial state for
  /// dynamic controllers and sockets like `CoralController.late()` or `CoralCoupler.late()`
  /// before an initial data payload or source node is supplied.
  ///
  /// **Return Value Meaning:**
  /// * `true`: Uninitialized state (`CoralSnapshot.empty()`).
  /// * `false`: Holds valid data or an error state.
  ///
  /// **Precautions:**
  /// * Direct access to `.data` when `isEmpty` is `true` throws a [CoralSnapshotExtractionException].
  ///   Use `.dataOrNull` or `.dataOrElse()` for safe extraction when `isEmpty` is possible.
  @override
  bool get isEmpty;

  /// Whether this snapshot is in a corrupted state containing an error or exception.
  ///
  /// **Core Concept & Purpose:**
  /// Isolates failures into a first-class declarative snapshot without crashing application threads.
  ///
  /// **Return Value Meaning:**
  /// * `true`: Holds an exception ([error]) and optional stack trace ([stackTrace]).
  /// * `false`: Holds valid data or is uninitialized.
  ///
  /// **Precautions:**
  /// * Reading `.error` or `.stackTrace` when `isDamaged` is `false` throws a [CoralSnapshotStateException].
  ///   Always check `isDamaged` before inspecting error properties.
  @override
  bool get isDamaged;

  /// Extracts the underlying exception or failure object from a damaged snapshot.
  ///
  /// **Requires:**
  /// * Must only be called when [isDamaged] is `true`.
  ///
  /// **Throws:**
  /// * [CoralSnapshotStateException] if [isDamaged] is `false`.
  @override
  Object get error;

  /// Extracts the call stack trace at the point of failure from a damaged snapshot.
  ///
  /// **Requires:**
  /// * Must only be called when [isDamaged] is `true`.
  ///
  /// **Throws:**
  /// * [CoralSnapshotStateException] if [isDamaged] is `false`.
  @override
  StackTrace get stackTrace;

  /// Determines if this snapshot is equivalent to [other] by comparing their validity
  /// and underlying payloads.
  ///
  /// * [other]: The snapshot to compare against this snapshot.
  /// * [equals]: Optional custom equality predicate for comparing two valid payloads.
  bool isEquivalent(covariant CoralSnapshot<T> other, [bool Function(T previous, T next)? equals]);
}

/// A mixin that forwards all [CoralSnapshot] properties and accessors directly to the implementing class.
///
/// **Core Concept (Snapshot Delegation):**
/// Similar to [TrunkSnapshotDelegator], this mixin drastically reduces boilerplate
/// by allowing nodes to expose their snapshot properties (like [isValid], [data])
/// directly on the instance (e.g., `coral.data` instead of `coral.snapshot.data`).
mixin CoralSnapshotDelegator<T> implements CorallineSnapshotDelegator<CoralSnapshot<T>> {
  @override
  CoralSnapshot<T> get snapshot;

  @override
  @pragma('vm:prefer-inline')
  bool get isEmpty => snapshot.isEmpty;

  @override
  @pragma('vm:prefer-inline')
  bool get isDamaged => snapshot.isDamaged;

  @override
  @pragma('vm:prefer-inline')
  bool get isValid => snapshot.isValid;

  /// Extracts the underlying data synchronously from [snapshot].
  ///
  /// See [CoralSnapshot.data] for details.
  @pragma('vm:prefer-inline')
  T get data => snapshot.data;

  /// Safely extracts the underlying data from [snapshot], or returns `null` if invalid.
  ///
  /// See [CoralSnapshot.dataOrNull] for details.
  @pragma('vm:prefer-inline')
  T? get dataOrNull => snapshot.dataOrNull;

  /// Safely extracts the underlying data from [snapshot], or returns the result of [fallback] if invalid.
  ///
  /// * [fallback]: Callback invoked to produce a replacement value when [isValid] is `false`.
  ///
  /// See [CoralSnapshot.dataOrElse] for details.
  @pragma('vm:prefer-inline')
  T dataOrElse(T Function() fallback) => snapshot.dataOrElse(fallback);

  @override
  @pragma('vm:prefer-inline')
  Object get error => snapshot.error;

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace => snapshot.stackTrace;
}

/// The fundamental declarative node in the CoralNode topological graph that represents
/// an observable, typed data flow.
///
/// **Core Concept (Reactive Node):**
/// [Coral] is the core building block of the framework. Unlike a traditional `Stream`,
/// a [Coral] does not actively push data payloads down the pipeline. Instead, it adheres
/// to the **Push-Dirty, Pull-Data** architecture. It acts as a reactive node that holds
/// a [CoralSnapshot] (via [CoralSnapshotDelegator]) and signals downstream nodes when
/// its data needs to be re-computed.
///
/// ## System Architectural Flow
/// ```text
/// [Upstream / Controller] ──> Push Dirty ──> [Coral<T>] ──> Push Dirty ──> [Downstream Terminal]
///                                              │
/// Downstream Consumer <────── Lazy Pull Data <─┘
/// ```
///
/// **Warning (Anti-Pattern Prevention):**
///
/// * **BAD (Repeatedly allocating pipelines in render/read methods):**
///   ```dart
///   final counterCoral = Coral.data(1);
///   // Anti-pattern: Instantiating transformation nodes inside high-frequency read cycles
///   String renderCounter() {
///     final doubledCoral = counterCoral.map((count) => count * 2); // Re-creates nodes on every call
///     return '${doubledCoral.data}';
///   }
///   ```
/// * **GOOD (Declare pipeline topology once and observe reactively):**
///   ```dart
///   final counterCoral = Coral.data(1);
///   // Recommended: Declare the derived pipeline once and read from the same node
///   late final Coral<int> doubledCoral = counterCoral.map((count) => count * 2);
///   ```
///
/// **Design Philosophy (Topological Integration):**
/// By extending [CoralNode], [Coral] fully integrates into the topological lifecycle.
/// It knows when it has active listeners and when it is dormant. This allows it to
/// lazily allocate or release resources only when necessary. The data transformation
/// (mapping, cascading) only occurs when a terminal node explicitly pulls the data,
/// guaranteeing optimal execution.
///
/// **Leaf Node Factories Overview:**
/// The class provides factory constructors to instantiate source leaf nodes:
/// - **[Coral.data]**: Creates a static node carrying a valid data payload.
/// - **[Coral.empty]**: Creates a dormant node in an uninitialized state.
/// - **[Coral.damaged]**: Creates a node carrying an error or exception.
/// - **[Coral.resource]**: Creates a dynamic node binding resource creation and cleanup to the topological lifecycle.
///
/// **Implementation note (Lifecycle Management):**
/// Value-mapping operators (e.g., [CoralComputationExtension.map], [CoralKeyedIterableElements.map]) are designed purely for
/// **data transformation** in the middle of the pipeline. They do **not** assume
/// topological ownership of the objects they instantiate, and will **not** automatically call
/// `dispose` or `cancel` on them when evicted or cleared.
///
/// In `Coralline`, resource disposal is strictly managed through **topological node lifecycles**:
/// 1. **Using [Coral.resource] (Source Edge)**: Provides a built-in `dispose` callback
///    that triggers when the node deactivates.
/// 2. **Using a [CoralController] (Source Edge)**: Manage and dispose of resources
///    manually within its `onDeactivated` lifecycle hook.
/// 3. **Topological Branching (`cascade`, `diverge`, `keyed.diverge`, `converge`)**:
///    When dynamically constructing child nodes that wrap stateful resources, use topological
///    branching operators ([CoralComputationExtension.cascade], [CoralComputationExtension.diverge],
///    [CoralKeyedIterableElements.diverge], or [TrunkComputationExtension.converge]) to return a
///    [Coral.resource]. The framework attaches the returned node to the graph and automatically
///    invokes its `dispose` callback when the branch is swapped out, evicted, or deactivated.
sealed class Coral<T> extends CoralNode with CoralSnapshotDelegator<T> {
  /// Creates a static, instant leaf node holding a valid [data] payload.
  ///
  /// * [data]: The static value payload encapsulated by this node.
  ///
  /// **Core Concept & Purpose:**
  /// Represents a static, immutable source leaf node in the reactive topology that carries a valid
  /// [CoralSnapshot] with data `T`. It allows developers to inject constant values or mock state
  /// into a pipeline without the overhead of creating a full [CoralController].
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Zero Controller Overhead:** Avoids creating event controllers, stream subscriptions, or
  ///    listener registration allocations. Internally wraps [data] in a lightweight, static snapshot node.
  /// 2. **Pipeline Composability:** Seamlessly chains with downstream operators (`map`, `cascade`, `combine`)
  ///    and terminals with identical syntax as dynamic nodes.
  ///
  /// **Use Cases:**
  /// * **Constant / Static Value Injection:** Inject constant settings, titles, or static configuration into a pipeline:
  ///   ```dart
  ///   final staticTitleCoral = Coral.data('Dashboard');
  ///   ```
  /// * **Conditional Dynamic vs. Static Resolution:** Return a static value when data is known locally:
  ///   ```dart
  ///   Coral<String> fetchTitleFromNetwork() => Coral.data('Remote Dashboard');
  ///
  ///   Coral<String> resolveTitle(String? customTitle) {
  ///     return customTitle != null ? Coral.data(customTitle) : fetchTitleFromNetwork();
  ///   }
  ///   ```
  /// * **Testing & Mock Fixtures:** Provide fixed test fixtures in unit and widget tests:
  ///   ```dart
  ///   final mockUserCoral = Coral.data((id: 1, name: 'Alice'));
  ///   ```
  factory Coral.data(T data) = _InstantCoral;

  /// Creates a static, instant leaf node in an uninitialized (empty) state.
  ///
  /// **Core Concept & Purpose:**
  /// Represents an uninitialized, dormant node state (`CoralSnapshot.empty()`). It serves as a dormant placeholder
  /// when data or upstream connections are not yet available.
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Initial Socket & Controller Placeholder:** Serves as the safe, default initial state for dynamic
  ///    controllers and sockets like `CoralController.late()` or `CoralCoupler.late()` before an initial payload or live inbound node is supplied.
  /// 2. **Fail-Fast & Pattern-Matching Safety:** Throws a fail-fast [CoralSnapshotExtractionException] if `.data`
  ///    is accessed directly on an empty snapshot, encouraging safe pattern-matching via `.isEmpty` or `.dataOrNull`.
  ///
  /// **Use Cases:**
  /// * **Late Controllers & Dynamic Sockets:** Initial state for late controllers or dynamic couplers before coupling a data source:
  ///   ```dart
  ///   final controller = CoralController<String>.late(); // Starts in Coral.empty() state
  ///   final coupler = CoralCoupler<String>.late(); // Starts in Coral.empty() state
  ///   ```
  /// * **Lazy Loading & Placeholder Routing:** Render loading indicators or placeholders when empty:
  ///   ```dart
  ///   String renderStatus(CoralSnapshot<String> snapshot) {
  ///     if (snapshot.isEmpty) return 'Loading...';
  ///     return snapshot.data;
  ///   }
  ///   ```
  /// * **Pipeline Resets on Lifecycle Events:** Reset user state safely upon logout:
  ///   ```dart
  ///   final userCoupler = CoralCoupler<String>(Coral.data('Alice'), hotswap: true);
  ///   userCoupler.couple(Coral.empty()); // Safely reset pipeline state on logout
  ///   ```
  factory Coral.empty() = _InstantCoral.empty;

  /// Creates a static, instant leaf node in a corrupted (damaged) state, storing [error] and optional [stackTrace].
  ///
  /// * [error]: The error or exception payload causing the damaged state.
  /// * [stackTrace]: Optional stack trace associated with [error].
  ///
  /// **Core Concept & Purpose:**
  /// Represents a corrupted, damaged node state (`CoralSnapshot.damaged()`). It promotes errors and exceptions
  /// into first-class, declarative topology nodes within the reactive graph.
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Declarative Error Containment:** Isolates failures without crashing the application thread. Damaged nodes
  ///    cascade downstream dirty signals, allowing terminals and UI components to safely render fallbacks.
  /// 2. **Error Pipeline Integration:** Integrates seamlessly with [CoralComputationExtension.fallback] and terminal error handlers.
  ///
  /// **Use Cases:**
  /// * **Declarative Failure Return:** Explicitly return an error state from input validation or parsing:
  ///   ```dart
  ///   Coral<int> parseInput(String raw) {
  ///     if (raw.isEmpty) return Coral.damaged(const FormatException('Input cannot be empty'));
  ///     return Coral.data(int.parse(raw));
  ///   }
  ///   ```
  /// * **Manual Coupler Error Injection:** Inject network or API errors directly into dynamic couplers:
  ///   ```dart
  ///   final userCoupler = CoralCoupler<String>.late();
  ///   userCoupler.setError(StateError('Network timeout'));
  ///   ```
  /// * **Fallback & Error Rendering Verification:** Test and verify error fallbacks:
  ///   ```dart
  ///   final errorCoral = Coral<String>.damaged(StateError('Server under maintenance'));
  ///   ```
  factory Coral.damaged(Object error, [StackTrace? stackTrace]) = _InstantCoral.damaged;

  /// Creates a dynamic, topology-aware leaf node that generates and manages data only when active.
  ///
  /// * [create]: Resource factory invoked when the node becomes active.
  /// * [dispose]: Teardown callback invoked when the node deactivates.
  ///
  /// **Requires:**
  /// * [create] MUST return the valid `T` data and is invoked when the node becomes active.
  /// * [dispose] is invoked when the node deactivates, ensuring the previously created data is properly cleaned up.
  ///
  /// ## Examples
  /// ```dart
  /// class EventClient {
  ///   Stream<String> connect(Uri uri) => Stream.value('event:$uri');
  ///   void close() {}
  /// }
  ///
  /// // Safely manage a client resource for a streaming connection
  /// final clientCoral = Coral.resource(
  ///   create: () => EventClient(),
  ///   dispose: (client) => client.close(),
  /// );
  ///
  /// // Cascade the active client into a reactive Stream Coral node
  /// final streamCoral = clientCoral.cascade(
  ///   (client) => client.connect(Uri.parse('https://api.example.com/stream')).toCoral(),
  /// );
  /// ```
  factory Coral.resource({required T Function() create, required void Function(T resource) dispose}) = _ResourceCoral;

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
  CoralSnapshot<T> get snapshot;

  /// Whether the snapshot is currently in an uninitialized (empty) state.
  @override
  bool get isEmpty;

  /// Whether the snapshot is currently in a corrupted (damaged) state.
  @override
  bool get isDamaged;

  /// Whether the snapshot currently contains a valid data payload.
  @override
  bool get isValid;

  /// Extracts the underlying data synchronously from this node's [snapshot].
  ///
  /// See [CoralSnapshot.data] for details.
  @override
  T get data;

  /// Safely extracts the underlying data from this node's [snapshot], or returns `null` if invalid.
  ///
  /// See [CoralSnapshot.dataOrNull] for details.
  @override
  T? get dataOrNull;

  /// Safely extracts the underlying data from this node's [snapshot], or returns the result of [fallback] if invalid.
  ///
  /// * [fallback]: Callback invoked to produce a replacement value when [isValid] is `false`.
  ///
  /// See [CoralSnapshot.dataOrElse] for details.
  @override
  T dataOrElse(T Function() fallback);

  /// Extracts the error object from this node's [snapshot] when [isDamaged] is `true`.
  ///
  /// See [CoralSnapshot.error] for details.
  @override
  Object get error;

  /// Extracts the stack trace from this node's [snapshot] when [isDamaged] is `true`.
  ///
  /// See [CoralSnapshot.stackTrace] for details.
  @override
  StackTrace get stackTrace;
}

/// A read-only provider interface that exposes a reactive [Coral] node and its [CorallineLifecycleStatus].
abstract interface class CoralProvider<T> implements CorallineLifecycleStatus {
  /// Creates a static, lightweight [CoralProvider] holding a fixed [data] payload.
  ///
  /// * [data]: The static value payload encapsulated by this provider.
  ///
  /// **Core Concept & Purpose:**
  /// Encapsulates static, immutable data into the [CoralProvider<T>] interface specification
  /// without needing a [CoralController].
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Zero Controller Overhead:** Avoids creating event controllers or stream subscription
  ///    allocations. Internally wraps [data] in a lightweight, static snapshot node.
  /// 2. **API Uniformity & Decoupling:** Allows downstream consumers to consume state with identical
  ///    syntax regardless of whether the state is static or driven by a dynamic controller.
  ///
  /// **Use Cases:**
  /// * **Static App Configuration & Themes:** Inject constant settings or configuration objects:
  ///   ```dart
  ///   final appConfigProvider = CoralProvider.data((env: 'production'));
  ///   ```
  /// * **Testing & Mocking:** Supply constant test fixtures without setting up controllers:
  ///   ```dart
  ///   final mockUserProvider = CoralProvider.data((name: 'TestUser'));
  ///   ```
  /// * **Default Fallback Providers:** Supply default static fallbacks when optional providers are omitted.
  factory CoralProvider.data(T data) = _InstantCoralProvider.data;

  /// Creates a [CoralProvider] by wrapping an existing [coral] reactive pipeline.
  ///
  /// * [coral]: The reactive [Coral] node to wrap in this read-only provider.
  ///
  /// **Core Concept & Purpose:**
  /// Promotes any arbitrary [Coral<T>] node—such as a transformed operator pipeline (`map`, `cascade`),
  /// a resource node (`Coral.resource`), or a read-only view—into the [CoralProvider<T>] interface specification.
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Read-Only Encapsulation & Mutability Isolation:** Protects underlying controllers from being
  ///    mutated externally. Exposing `CoralProvider.coral(controller.coral)` grants downstream consumers
  ///    read-only access while preventing arbitrary `.set()` updates.
  /// 2. **Pipeline Promotion:** Elevates derived computation pipelines or dynamic resource nodes into first-class
  ///    dependency-injection providers.
  ///
  /// **Use Cases:**
  /// * **Derived / Computed State Providers:** Expose transformed pipelines as providers:
  ///   ```dart
  ///   final rawCounterCoral = Coral.data(1);
  ///   final formattedProvider = CoralProvider.coral(
  ///     rawCounterCoral.map((count) => 'Count: $count'),
  ///   );
  ///   ```
  /// * **Resource Node Providers:** Wrap lifecycle-managed resources:
  ///   ```dart
  ///   final resourceProvider = CoralProvider.coral(
  ///     Coral.resource(create: () => <String>[], dispose: (list) => list.clear()),
  ///   );
  ///   ```
  /// * **Read-Only State Exposure:** Expose internal controller state as a read-only provider to consumers.
  factory CoralProvider.coral(Coral<T> coral) = _InstantCoralProvider.coral;

  /// The underlying [Coral] instance managed by this provider.
  ///
  /// **Implementation note (Broadcaster Line Node & Caching Warning):**
  /// - **Multi-Cast Line Generation:** When this provider is a [CoralBroadcaster] (e.g., created via a
  ///   [CoralController] with `broadcast: true`), every access to [coral] creates and returns a **new,
  ///   distinct branch (Line) node instance**.
  /// - **Do Not Call Repeatedly in Lifecycle / Compute Methods:** Calling `provider.coral` repeatedly in separate
  ///   hooks—such as calling `provider.coral` once inside `manifest()` and again inside `compute()`—will
  ///   register one line node (Node A) in the reactive topology while pulling data from a completely unattached
  ///   or separate line node (Node B) during evaluation. This causes topological desynchronization, lost dirty updates,
  ///   or [CoralBroadcasterLineDormantAccessError].
  /// - **Best Practice (Single Instance Caching):** Always cache the result of [coral] into a `final` or `late final`
  ///   field (initialized in the constructor initializer list) and reuse that exact instance across `manifest()` and `compute()`.
  ///
  /// ## Examples
  /// ```dart
  /// base class FormattedComputation extends SimplexComputation<String> {
  ///   FormattedComputation({required CoralProvider<int> provider})
  ///       : countCoral = provider.coral; // Cache once in initializer list
  ///
  ///   final Coral<int> countCoral;
  ///
  ///   @override
  ///   @manifestSync
  ///   CoralNode manifest() => countCoral;
  ///
  ///   @override
  ///   String compute() {
  ///     final count = countCoral.data; // Reuse the same cached node
  ///     return 'Count: $count';
  ///   }
  /// }
  /// ```
  Coral<T> get coral;

  /// Whether the underlying [coral] pipeline node has been activated.
  @override
  bool get isActivated;

  /// Whether the underlying [coral] pipeline node is currently running.
  @override
  bool get isRunning;

  /// Whether the underlying [coral] pipeline node is temporarily paused.
  @override
  bool get isPaused;

  /// Whether the underlying [coral] pipeline node is currently in the deactivated (inactive) state.
  @override
  bool get isDeactivated;
}

/// Convenience conversion and lifecycle observation methods for [Coral] nodes.
extension CoralExtension<S> on Coral<S> {
  /// Converts this 1:1 pipeline node into a 1:N [CoralBroadcaster].
  CoralBroadcaster<S> toBroadcaster() => CoralBroadcaster<S>(this);

  /// Connects this [Coral] node to a [CoralTerminal] with the given [onDirty] callback.
  ///
  /// * [onDirty]: Callback invoked when this pipeline marks the terminal dirty.
  CoralTerminal<S> toTerminal(void Function() onDirty) => CoralTerminal<S>(this, onDirty: onDirty);

  /// Attaches lifecycle event observers to this [Coral] pipeline.
  ///
  /// * [onActivated]: Invoked when the returned node transitions to active.
  /// * [onPaused]: Invoked when the returned node transitions to paused.
  /// * [onResumed]: Invoked when the returned node resumes from a paused state.
  /// * [onDeactivated]: Invoked when the returned node transitions to deactivated.
  Coral<S> observeLifecycle({
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  }) =>
      _LifecycleObservableCoral<S>(
        this,
        onActivated: onActivated,
        onPaused: onPaused,
        onResumed: onResumed,
        onDeactivated: onDeactivated,
      );
}

/// Convenience conversion extensions available directly on any [CoralProvider].
extension CoralProviderExtension<S> on CoralProvider<S> {
  /// Converts this provider's underlying [coral] into a 1:N [CoralBroadcaster].
  CoralBroadcaster<S> toBroadcaster() => coral.toBroadcaster();

  /// Connects this provider's underlying [coral] to a [CoralTerminal] with the given [onDirty] callback.
  ///
  /// * [onDirty]: Callback invoked when the underlying [coral] marks the terminal dirty.
  CoralTerminal<S> toTerminal(void Function() onDirty) => CoralTerminal<S>(coral, onDirty: onDirty);
}

/// Declarative transformation, branching, recovery, and filtering operators for [Coral] nodes.
extension CoralComputationExtension<S> on Coral<S> {
  /// Dynamically constructs and attaches a new downstream [Coral] node based on the computed data.
  ///
  /// **Core Concept (Dynamic Topological Cascading):**
  /// Enables dynamic pipelines where the architecture of the topological graph can morph
  /// at runtime depending on the computed data payload.
  ///
  /// * [cascade]: A builder callback that yields the next [Coral] node.
  /// * [seal]: If `true`, this cascading node permanently owns the inner [Coral] returned by [cascade],
  ///   preventing external nodes from detaching it. Defaults to `true`.
  /// * [hotswap]: If `true`, defers deactivation of swapped-out inner nodes to the end of the microtask. Defaults to `false`.
  /// * [eager]: If `true`, evaluates [cascade] and attaches the inner node eagerly during dirty propagation. Defaults to `false`.
  ///
  /// **Ensures:**
  /// * Returns a new [Coral] node whose snapshot represents the computed state of the active branch.
  /// * Automatically propagates state updates from both the source node and the active branch.
  ///
  /// ## Examples
  /// ```dart
  /// // Dynamically switch to a different branch Coral based on the user's role
  /// final roleCoral = Coral.data('admin');
  /// final repositoryCoral = roleCoral.cascade((role) {
  ///   if (role == 'admin') return Coral.data('AdminRepository');
  ///   return Coral.data('GuestRepository');
  /// }, hotswap: true);
  /// ```
  Coral<T> cascade<T>(
    Coral<T> Function(S data) cascade, {
    bool seal = true,
    bool hotswap = false,
    bool eager = false,
  }) =>
      switch ((seal, hotswap, eager)) {
        (true, true, true) => _SealedHotswapEagerCascadingCoral<S, T>(this, cascade: cascade),
        (true, true, false) => _SealedHotswapLazyCascadingCoral<S, T>(this, cascade: cascade),
        (true, false, true) => _SealedColdswapEagerCascadingCoral<S, T>(this, cascade: cascade),
        (true, false, false) => _SealedColdswapLazyCascadingCoral<S, T>(this, cascade: cascade),
        (false, true, true) => _DetachableHotswapEagerCascadingCoral<S, T>(this, cascade: cascade),
        (false, true, false) => _DetachableHotswapLazyCascadingCoral<S, T>(this, cascade: cascade),
        (false, false, true) => _DetachableColdswapEagerCascadingCoral<S, T>(this, cascade: cascade),
        (false, false, false) => _DetachableColdswapLazyCascadingCoral<S, T>(this, cascade: cascade),
      } as Coral<T>;

  /// Filters out consecutive duplicate payloads to prevent redundant downstream computations.
  ///
  /// **Core Concept (Distinct Filtering):**
  /// Intercepts updates from the source node and blocks propagation if the new snapshot is
  /// equivalent to the previous snapshot, determined by the [equals] comparator.
  ///
  /// * [equals]: An optional custom equality comparison function.
  ///
  /// **Ensures:**
  /// * Returns a new [Coral] node that only signals dirty state when the payload changes.
  ///
  /// ## Examples
  /// ```dart
  /// final searchQueryCoral = Coral.data('hello');
  /// // Downstream pipelines will only be triggered when the query actually changes
  /// final distinctSearchCoral = searchQueryCoral.distinct();
  /// ```
  Coral<S> distinct([bool Function(S previous, S next)? equals]) => _DistinctCoral(this, equals: equals);

  /// Transforms a single [Coral] data payload into a dynamically generated [Trunk].
  ///
  /// **Core Concept (Dynamic Topological Divergence):**
  /// Splits a single upstream source node into a bundle of multiple child nodes (1:N divergence).
  /// The child nodes are dynamically updated when the parent node's payload changes.
  ///
  /// * [cascade]: A builder callback that yields the iterable of child nodes.
  /// * [seal]: If `true`, this diverging trunk permanently owns the child nodes returned by [cascade]. Defaults to `true`.
  /// * [hotswap]: If `true`, defers deactivation of removed child nodes to the end of the microtask. Defaults to `false`.
  /// * [eager]: If `true`, evaluates [cascade] and attaches child nodes eagerly during dirty propagation. Defaults to `false`.
  ///
  /// **Ensures:**
  /// * Returns a [Trunk] bundle representing the diverged child [Coral] nodes.
  ///
  /// ## Examples
  /// ```dart
  /// // Split a single list of IDs into individual Coral nodes for concurrent processing
  /// final userIdsCoral = Coral.data(['user1', 'user2', 'user3']);
  /// final userTrunk = userIdsCoral.diverge(
  ///   (ids) => ids.map((id) => Coral.data('Profile($id)')),
  /// );
  /// ```
  Trunk<T> diverge<T>(
    Iterable<Coral<T>> Function(S data) cascade, {
    bool seal = true,
    bool hotswap = false,
    bool eager = false,
  }) =>
      switch ((seal, hotswap, eager)) {
        (true, true, true) => _SealedHotswapEagerDivergingTrunk<S, T>(this, cascade: cascade),
        (true, true, false) => _SealedHotswapLazyDivergingTrunk<S, T>(this, cascade: cascade),
        (true, false, true) => _SealedColdswapEagerDivergingTrunk<S, T>(this, cascade: cascade),
        (true, false, false) => _SealedColdswapLazyDivergingTrunk<S, T>(this, cascade: cascade),
        (false, true, true) => _DetachableHotswapEagerDivergingTrunk<S, T>(this, cascade: cascade),
        (false, true, false) => _DetachableHotswapLazyDivergingTrunk<S, T>(this, cascade: cascade),
        (false, false, true) => _DetachableColdswapEagerDivergingTrunk<S, T>(this, cascade: cascade),
        (false, false, false) => _DetachableColdswapLazyDivergingTrunk<S, T>(this, cascade: cascade),
      };

  /// Intercepts empty or damaged states and recovers by providing fallback payloads.
  ///
  /// **Core Concept (Safe Recovery):**
  /// Guarantees that the downstream pipeline continues computing even when the upstream
  /// node is uninitialized or has failed, by applying the recovery generator callbacks.
  ///
  /// * [onEmpty]: Triggers when the source is empty to return a fallback payload.
  /// * [onDamage]: Triggers when the source is damaged to return a fallback payload.
  ///
  /// **Requires:**
  /// * At least one of [onEmpty] or [onDamage] must be non-null.
  ///
  /// **Ensures:**
  /// * Returns a new [Coral] node that contains a valid payload if the respective
  ///   fallback callback is provided and resolves without throwing.
  ///
  /// ## Examples
  /// ```dart
  /// final networkCoral = Coral<String>.empty();
  /// final safeCoral = networkCoral.fallback(
  ///   onEmpty: () => 'Loading...',
  ///   onDamage: (err, [stack]) => 'Error occurred: $err',
  /// );
  /// ```
  Coral<S> fallback({
    S Function()? onEmpty,
    S Function(Object error, [StackTrace? stackTrace])? onDamage,
  }) =>
      _FallbackCoral<S>(this, onEmpty: onEmpty, onDamage: onDamage);

  /// Recovers from an empty state by converting it into a valid null payload.
  ///
  /// **Core Concept (Null Recovery):**
  /// A convenience operator specifically designed to handle uninitialized/empty pipelines
  /// by downgrading them into a valid `null` value, allowing downstream operations to proceed.
  ///
  /// **Ensures:**
  /// * Returns a new [Coral] node of type `S?` where empty snapshots become valid nulls.
  /// * Propagates damaged states as-is.
  ///
  /// ## Examples
  /// ```dart
  /// final uninitializedCoral = Coral<String>.empty();
  /// final nullCoral = uninitializedCoral.fallbackEmptyToNull(); // Payload is now 'null'
  /// ```
  Coral<S?> fallbackEmptyToNull() => _FallbackEmptyToNullCoral<S?>(this);

  /// Conditionally blocks downstream computation based on validation checks.
  ///
  /// **Core Concept (Pipeline Guard):**
  /// Prevents downstream computation from continuing when [canProceed] returns `false`.
  /// When blocked, the node transitions to [CoralSnapshot.empty] if [getReason] is omitted
  /// or returns `null`, or transitions to [CoralSnapshot.damaged] with the non-null error
  /// object returned by [getReason].
  ///
  /// * [canProceed]: A callback validation function that must return `true` to allow the upstream snapshot through.
  /// * [getReason]: An optional callback returning the error object for a `damaged` snapshot when [canProceed] returns `false`; if `null` or returning `null`, an `empty` snapshot is produced instead.
  ///
  /// **Ensures:**
  /// * Returns a new [Coral] node that forwards the upstream snapshot only when [canProceed] resolves to `true`.
  /// * Produces an `empty` snapshot (when reason is `null`) or a `damaged` snapshot (when reason is non-null) if [canProceed] returns `false`.
  ///
  /// ## Examples
  /// ```dart
  /// var hasFilePermissions = false;
  /// final fileReaderCoral = Coral.data('file-contents');
  /// final safeFileReader = fileReaderCoral.guard(
  ///   canProceed: () => hasFilePermissions,
  ///   getReason: () => 'Permission denied',
  /// );
  /// ```
  Coral<S> guard({required bool Function() canProceed, Object? Function()? getReason}) =>
      _GuardedCoral<S>(this, canProceed: canProceed, getReason: getReason);

  /// Synchronously transforms the computed data payload from type `S` to type `T`.
  ///
  /// **Core Concept (Synchronous Transformation):**
  /// Applies the [convert] function to the resolved data payload of this node.
  /// If the upstream node is empty or damaged, that state is propagated downstream
  /// without invoking [convert].
  ///
  /// * [convert]: Pure synchronous function transforming a valid `S` value into `T`.
  ///
  /// ## Examples
  /// ```dart
  /// final countCoral = Coral.data(5);
  /// final stringCoral = countCoral.map((count) => 'Count is $count');
  /// ```
  Coral<T> map<T>(T Function(S source) convert) => _MapCoral<S, T>(this, convert: convert);
}

/// Computation operators available directly on any [CoralProvider].
///
/// A convenience extension that allows computation operators to be called directly
/// on any [CoralProvider] (such as [CoralController] or custom components), automatically
/// delegating the operation to the underlying [Coral] node.
extension CoralProviderComputationExtension<S> on CoralProvider<S> {
  /// Delegates [CoralComputationExtension.cascade] to the underlying [Coral].
  ///
  /// * [cascade]: Builder callback yielding the next [Coral] node.
  /// * [eager]: If `true`, evaluates [cascade] eagerly during dirty propagation.
  Coral<T> cascade<T>(
    Coral<T> Function(S data) cascade, {
    bool eager = false,
  }) =>
      coral.cascade(cascade, eager: eager);

  /// Delegates [CoralComputationExtension.distinct] to the underlying [Coral].
  ///
  /// * [equals]: Optional custom equality comparison function.
  Coral<S> distinct([bool Function(S previous, S next)? equals]) => coral.distinct(equals);

  /// Delegates [CoralComputationExtension.diverge] to the underlying [Coral].
  ///
  /// * [cascade]: Builder callback yielding the iterable of child [Coral] nodes.
  /// * [seal]: If `true`, the resulting [Trunk] permanently owns its child nodes.
  /// * [hotswap]: If `true`, defers deactivation of removed child nodes to the end of the microtask.
  /// * [eager]: If `true`, evaluates [cascade] eagerly during dirty propagation.
  Trunk<T> diverge<T>(
    Iterable<Coral<T>> Function(S data) cascade, {
    bool seal = true,
    bool hotswap = false,
    bool eager = false,
  }) =>
      coral.diverge(cascade, seal: seal, hotswap: hotswap, eager: eager);

  /// Delegates [CoralComputationExtension.fallback] to the underlying [Coral].
  ///
  /// * [onEmpty]: Fallback value generator when the source is `empty`.
  /// * [onDamage]: Fallback value generator when the source is `damaged`.
  Coral<S> fallback({
    S Function()? onEmpty,
    S Function(Object error, [StackTrace? stackTrace])? onDamage,
  }) =>
      coral.fallback(onEmpty: onEmpty, onDamage: onDamage);

  /// Delegates [CoralComputationExtension.fallbackEmptyToNull] to the underlying [Coral].
  Coral<S?> fallbackEmptyToNull() => coral.fallbackEmptyToNull();

  /// Delegates [CoralComputationExtension.guard] to the underlying [Coral].
  ///
  /// * [canProceed]: Validation callback that must return `true` to allow the upstream snapshot through.
  /// * [getReasonIfCannotProceed]: Optional callback returning the error object when [canProceed] returns `false`.
  Coral<S> guard({required bool Function() canProceed, Object? Function()? getReasonIfCannotProceed}) =>
      coral.guard(canProceed: canProceed, getReason: getReasonIfCannotProceed);

  /// Delegates [CoralComputationExtension.map] to the underlying [Coral].
  ///
  /// * [convert]: Pure synchronous function transforming a valid `S` value into `T`.
  Coral<T> map<T>(T Function(S source) convert) => coral.map(convert);
}

/// Utility extensions for operating on an `Iterable` of [Coral] nodes.
///
/// Provides convenience methods to inspect and manipulate an `Iterable` of [Coral] nodes
/// as a cohesive group, without needing to manually map over their snapshots.
extension CoralCollectionExtension<T> on Iterable<Coral<T>> {
  /// Extracts the underlying data from all Corals in this collection.
  ///
  /// **Implementation note (Fail-Fast Enforcement):**
  /// This extension property enforces Coralline's Fail-Fast design at the collection level.
  /// If any [Coral] in the iteration is in an `empty` or `damaged` state, reading `coral.data`
  /// will immediately throw an exception.
  ///
  /// This guarantees that downstream processes do not inadvertently operate on partial or
  /// corrupted data sets, preserving structural integrity.
  Iterable<T> get data => map((coral) => coral.data);

  /// Bundles this collection of individual [Coral] nodes into a single [Trunk].
  ///
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
  /// Setting [seal] to `false` permits *external* downstream nodes (e.g., couplers, converging or
  /// diverging trunks) to claim or swap child lines out of this trunk. Setting [hotswap] to `true`
  /// ensures that if an active child line is detached by an external node, it is safely transferred
  /// to a mooring point safeguard rather than immediately deactivated.
  Trunk<T> toTrunk({bool seal = true, bool hotswap = false}) => Trunk.of(this, seal: seal, hotswap: hotswap);
}

/// Utility extensions for operating on an `Iterable` of [CoralSnapshot] instances.
///
/// Provides convenience methods to inspect and manipulate an `Iterable` of [CoralSnapshot]s
/// as a cohesive group.
extension CoralSnapshotCollectionExtension<T> on Iterable<CoralSnapshot<T>> {
  /// Extracts the underlying data from all snapshots in this collection.
  ///
  /// **Implementation note (Fail-Fast Enforcement):**
  /// Inherits strict validation. Throws an exception if any snapshot in the collection
  /// is [CorallineSnapshot.isEmpty] or [CorallineSnapshot.isDamaged].
  Iterable<T> get data => map((snapshot) => snapshot.data);
}

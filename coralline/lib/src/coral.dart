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
/// **AI & Developer Note (Fail-Fast Enforcement):**
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
  const factory CoralSnapshot(T data) = _CoralSnapshot;

  const factory CoralSnapshot.damaged(Object error, [StackTrace? stackTrace]) = _DamagedCoralSnapshot;

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
  /// **Preconditions:**
  /// * The snapshot must be in a [isValid] state.
  ///
  /// **Throws:**
  /// * [CoralSnapshotExtractionException] if [isValid] is false (i.e., [isEmpty] or
  ///   [isDamaged] is true).
  ///
  /// **Example:**
  /// ```dart
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
  /// * Returns `null` if [isValid] is false.
  /// * Otherwise, returns the non-null (or nullable if type `T` is nullable) data payload.
  ///
  /// **Example:**
  /// ```dart
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
  /// **Ensures:**
  /// * Returns the underlying data if [isValid] is true.
  /// * Otherwise, invokes and returns the result of [fallback].
  ///
  /// **Example:**
  /// ```dart
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
  /// **Preconditions:**
  /// * Must only be called when [isDamaged] is `true`.
  ///
  /// **Throws:**
  /// * [CoralSnapshotStateException] if [isDamaged] is `false`.
  @override
  Object get error;

  /// Extracts the call stack trace at the point of failure from a damaged snapshot.
  ///
  /// **Preconditions:**
  /// * Must only be called when [isDamaged] is `true`.
  ///
  /// **Throws:**
  /// * [CoralSnapshotStateException] if [isDamaged] is `false`.
  @override
  StackTrace get stackTrace;

  /// Determines if this snapshot is equivalent to [other] by comparing their validity
  /// and underlying payloads.
  bool isEquivalent(covariant CoralSnapshot<T> other, [bool Function(T previous, T next)? equals]);
}

/// **Core Concept (Snapshot Delegation):**
/// A mixin that forwards all [CoralSnapshot] properties and accessors directly
/// to the implementing class.
///
/// **Design Philosophy (Ergonomics):**
/// Similar to `TrunkSnapshotDelegator`, this mixin drastically reduces boilerplate
/// by allowing nodes to expose their snapshot properties (like `isValid`, `data`)
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

  /// See [CoralSnapshot.data] for details.
  @pragma('vm:prefer-inline')
  T get data => snapshot.data;

  /// See [CoralSnapshot.dataOrNull] for details.
  @pragma('vm:prefer-inline')
  T? get dataOrNull => snapshot.dataOrNull;

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
/// **Design Philosophy (Topological Integration):**
/// By extending [CoralNode], [Coral] fully integrates into the topological lifecycle.
/// It knows when it has active listeners and when it is dormant. This allows it to
/// lazily allocate or release resources only when necessary. The data transformation
/// (mapping, deriving) only occurs when a terminal node explicitly pulls the data,
/// guaranteeing optimal execution.
///
/// **Leaf Node Factories Overview:**
/// The class provides factory constructors to instantiate source leaf nodes:
/// - **[Coral.data]**: Creates a static node carrying a valid data payload.
/// - **[Coral.empty]**: Creates a dormant node in an uninitialized state.
/// - **[Coral.damaged]**: Creates a node carrying an error or exception.
/// - **[Coral.resource]**: Creates a dynamic node binding resource creation and cleanup to the topological lifecycle.
///
/// **AI & Developer Note (Lifecycle Management):**
/// Coral operators (e.g., [map], [cachedMap], [keyedDiverge]) are designed purely for
/// **data transformation** in the middle of the pipeline. They do **not** assume
/// ownership of the objects they instantiate, and will **not** automatically call
/// `dispose` or `cancel` on them when evicted or cleared.
///
/// In `Coralline`, resource disposal is strictly pushed to the **edges (endpoints)**
/// of the topological graph. If you need to manage stateful resources that require
/// explicit cleanup (like `StreamController` or `Timer`), you must handle their
/// lifecycle at the endpoints:
/// 1. **Using [Coral.resource] (Source Edge)**: Provides a built-in `dispose` callback
///    that triggers when the node deactivates.
/// 2. **Using a `CoralController` (Source Edge)**: Manage and dispose of resources
///    manually within its `deactivate` lifecycle hook.
/// 3. Resource Cleanup Support (`map`, `keyedDiverge`):
///    When converting objects using stateful nodes, developers must be careful not to
///    leak resources. Coralline provides operators like [map] and
///    [keyedDiverge] to generate and return a new [Coral.resource]. The framework will
///    automatically call its `dispose` callback when the returned node is evicted or
///    loses its downstream listeners (deactivates).
sealed class Coral<T> extends CoralNode with CoralSnapshotDelegator<T> {
  /// Creates a static, instant leaf node holding a valid [data] payload.
  ///
  /// **Core Concept & Purpose:**
  /// Represents a static, immutable source leaf node in the reactive topology that carries a valid
  /// [CoralSnapshot] with data `T`. It allows developers to inject constant values or mock state
  /// into a pipeline without the overhead of creating a full `CoralController`.
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Zero Controller Overhead:** Avoids creating event controllers, stream subscriptions, or
  ///    listener registration allocations. Internally wraps [data] in a lightweight, static snapshot node.
  /// 2. **Pipeline Composability:** Seamlessly chains with downstream operators (`map`, `cascade`, `combine`)
  ///    and UI components (`CoralWidget`) with identical syntax as dynamic nodes.
  ///
  /// **Use Cases:**
  /// * **Constant / Static Value Injection:** Inject constant settings, titles, or static configuration into a pipeline:
  ///   ```dart
  ///   final staticTitleCoral = Coral.data("Dashboard");
  ///   ```
  /// * **Conditional Dynamic vs. Static Resolution:** Return a static value when data is known locally:
  ///   ```dart
  ///   Coral<String> resolveTitle(String? customTitle) {
  ///     return customTitle != null ? Coral.data(customTitle) : fetchTitleFromNetwork();
  ///   }
  ///   ```
  /// * **Testing & Mock Fixtures:** Provide fixed test fixtures in unit and widget tests:
  ///   ```dart
  ///   final mockUserCoral = Coral.data(User(id: 1, name: 'Alice'));
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
  ///   final controller = CoralController<UserSession>.late(); // Starts in Coral.empty() state
  ///   final coupler = CoralCoupler<UserSession>.late(); // Starts in Coral.empty() state
  ///   ```
  /// * **Lazy Loading & Placeholder UI Routing:** Render loading indicators or placeholders when empty:
  ///   ```dart
  ///   Widget buildUI(CoralSnapshot<UserData> snapshot) {
  ///     if (snapshot.isEmpty) return const CircularProgressIndicator();
  ///     return Text(snapshot.data.name);
  ///   }
  ///   ```
  /// * **Pipeline Resets on Lifecycle Events:** Reset user state safely upon logout:
  ///   ```dart
  ///   userCoupler.couple(Coral.empty()); // Safely reset pipeline state on logout
  ///   ```
  factory Coral.empty() = _InstantCoral.empty;

  /// Creates a static, instant leaf node in a corrupted (damaged) state, storing [error] and optional [stackTrace].
  ///
  /// **Core Concept & Purpose:**
  /// Represents a corrupted, damaged node state (`CoralSnapshot.damaged()`). It promotes errors and exceptions
  /// into first-class, declarative topology nodes within the reactive graph.
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Declarative Error Containment:** Isolates failures without crashing the application thread. Damaged nodes
  ///    cascade downstream dirty signals, allowing terminals and UI components to safely render fallbacks.
  /// 2. **Error Pipeline Integration:** Integrates seamlessly with `CoralWidget.errorBuilder` and `toTerminal` handlers.
  ///
  /// **Use Cases:**
  /// * **Declarative Failure Return:** Explicitly return an error state from input validation or parsing:
  ///   ```dart
  ///   Coral<Data> parseInput(String raw) {
  ///     if (raw.isEmpty) return Coral.damaged(FormatException('Input cannot be empty'));
  ///     return Coral.data(Data.parse(raw));
  ///   }
  ///   ```
  /// * **Manual Coupler Error Injection:** Inject network or API errors directly into dynamic couplers:
  ///   ```dart
  ///   userCoupler.setError(NetworkTimeoutException());
  ///   ```
  /// * **UI Fallback & Error Rendering Verification:** Test and verify `CoralWidget.errorBuilder` fallbacks in UI:
  ///   ```dart
  ///   final errorCoral = Coral.damaged(ServerMaintenanceException());
  ///   ```
  factory Coral.damaged(Object error, [StackTrace? stackTrace]) = _InstantCoral.damaged;

  /// **Core Concept (Resource Node):**
  /// Creates a dynamic, topology-aware leaf node that generates and manages
  /// data only when active.
  ///
  /// **Requires:**
  /// * [create] MUST return the valid `T` data and is invoked when the node becomes active.
  /// * [dispose] is invoked when the node deactivates, ensuring the previously created data is properly cleaned up.
  ///
  /// **Example:**
  /// ```dart
  /// // 1. Safely manage an HTTP client for a streaming connection
  /// final httpClientCoral = Coral.resource(
  ///   create: () => HttpClient(),
  ///   dispose: (client) => client.close(force: true),
  /// );
  ///
  /// // Fetch the HTTP response asynchronously, then cascade to convert
  /// // the resulting byte Stream into a reactive Coral node.
  /// final streamCoral = httpClientCoral.cascade((client) {
  ///   final responseFuture = client.getUrl(Uri.parse('https://api.example.com/stream'))
  ///       .then((request) => request.close());
  ///
  ///   return responseFuture.toCoral().cascade(
  ///     (responseStream) => responseStream.toCoral(),
  ///   );
  /// });
  ///
  /// // 2. Asynchronously open a file, resolve the Future into a file handle,
  /// // and then asynchronously read a chunk of data, all within a reactive pipeline.
  /// final fileFutureCoral = Coral.resource(
  ///   create: () => File('data.txt').open(mode: FileMode.read),
  ///   dispose: (fileFuture) => fileFuture.then((file) => file.close()),
  /// );
  ///
  /// // The resulting contentCoral has type Coral<Uint8List>,
  /// // cleanly abstracting away all intermediate Futures.
  /// final Coral<Uint8List> contentCoral = fileFutureCoral
  ///   // Cascade 1: Convert the Future<RandomAccessFile> into a reactive Coral
  ///   .cascade((fileFuture) => fileFuture.toCoral())
  ///   // Cascade 2: Read from the resolved file, converting the new Future into a Coral
  ///   .cascade((file) => file.read(1024).toCoral());
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

  /// Whether this pipeline node has been permanently deactivated.
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

  /// See [CoralSnapshot.data] for details.
  @override
  T get data;

  /// See [CoralSnapshot.dataOrNull] for details.
  @override
  T? get dataOrNull;

  /// See [CoralSnapshot.dataOrElse] for details.
  @override
  T dataOrElse(T Function() fallback);

  /// See [CoralSnapshot.error] for details.
  @override
  Object get error;

  /// See [CoralSnapshot.stackTrace] for details.
  @override
  StackTrace get stackTrace;
}

abstract interface class CoralProvider<T> implements CorallineLifecycleStatus {
  /// Creates a static, lightweight [CoralProvider] holding a fixed [data] payload.
  ///
  /// **Core Concept & Purpose:**
  /// Encapsulates static, immutable data into the [CoralProvider<T>] interface specification
  /// without needing a `CoralController`.
  ///
  /// **Design Philosophy & Architectural Benefits:**
  /// 1. **Zero Controller Overhead:** Avoids creating event controllers or stream subscription
  ///    allocations. Internally wraps [data] in a lightweight, static snapshot node.
  /// 2. **API Uniformity & Decoupling:** Allows downstream consumers (e.g., `coralOf<T>()` or
  ///    components) to consume state with identical syntax regardless of whether the state is
  ///    static or driven by a dynamic controller.
  ///
  /// **Use Cases:**
  /// * **Static App Configuration & Themes:** Inject constant settings or theme objects into the widget tree:
  ///   ```dart
  ///   final appConfigProvider = CoralProvider.data(AppConfig(env: 'production'));
  ///   ```
  /// * **Testing & Mocking:** Supply constant test fixtures in widget tests without setting up controllers:
  ///   ```dart
  ///   final mockUserProvider = CoralProvider.data(UserSession(name: 'TestUser'));
  ///   ```
  /// * **Default Fallback Providers:** Supply default static fallbacks when optional providers are omitted.
  factory CoralProvider.data(T data) = _InstantCoralProvider.data;

  /// Creates a [CoralProvider] by wrapping an existing [coral] reactive pipeline.
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
  ///   final formattedProvider = CoralProvider.coral(
  ///     rawCounterCoral.map((count) => 'Count: $count'),
  ///   );
  ///   ```
  /// * **Resource Node Providers:** Wrap lifecycle-managed resources (e.g., WebSocket, HTTP streams):
  ///   ```dart
  ///   final socketProvider = CoralProvider.coral(
  ///     Coral.resource(create: () => connectSocket(), dispose: (s) => s.close()),
  ///   );
  ///   ```
  /// * **Read-Only ViewModel State Exposure:** Expose internal controller state as a read-only provider to the UI.
  factory CoralProvider.coral(Coral<T> coral) = _InstantCoralProvider.coral;

  /// The underlying [Coral] instance managed by this provider.
  ///
  /// **AI & Developer Note (Broadcaster Line Node & Caching Warning):**
  /// - **Multi-Cast Line Generation:** When this provider is a [CoralBroadcaster] (e.g., created via a
  ///   `CoralController` with `broadcast: true`), every access to [coral] creates and returns a **new,
  ///   distinct branch (Line) node instance**.
  /// - **Do Not Call Repeatedly in Lifecycle / Build Methods:** Calling `provider.coral` repeatedly in separate
  ///   lifecycle hooks—such as calling `provider.coral` once inside `manifest()` and again inside `build()`—will
  ///   register one line node (Node A) in the reactive topology while pulling data from a completely unattached
  ///   or separate line node (Node B) during rendering. This causes topological desynchronization, lost dirty updates,
  ///   or `CoralBroadcasterLineDormantAccessError`.
  /// - **Best Practice (Single Instance Caching):** Always cache the result of [coral] into a `final` or `late final`
  ///   field (or initialize it once in the constructor) and reuse that exact instance across all reactive methods
  ///   (`manifest()`, `build()`, etc.).
  ///
  /// **Example:**
  /// ```dart
  /// base class MyComponent extends BuildComponent {
  ///   MyComponent({required CoralProvider<MyData> provider})
  ///       : dataCoral = provider.coral; // Cache once at instantiation
  ///
  ///   final Coral<MyData> dataCoral;
  ///
  ///   @override
  ///   @manifestSync
  ///   Iterable<CoralNode> manifest() => [dataCoral];
  ///
  ///   @override
  ///   Widget build() {
  ///     final data = dataCoral.data; // Reuse the same cached node
  ///     return Text(data.title);
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

  /// Whether the underlying [coral] pipeline node has been permanently deactivated.
  @override
  bool get isDeactivated;
}

extension CoralExtension<S> on Coral<S> {
  CoralBroadcaster<S> toBroadcaster() => CoralBroadcaster<S>(this);

  CoralTerminal<S> toTerminal(void Function() onDirty) => CoralTerminal<S>(this, onDirty: onDirty);

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

extension CoralProviderExtension<S> on CoralProvider<S> {
  CoralBroadcaster<S> toBroadcaster() => coral.toBroadcaster();

  CoralTerminal<S> toTerminal(void Function() onDirty) => CoralTerminal<S>(coral, onDirty: onDirty);
}

extension CoralComputationExtension<S> on Coral<S> {
  /// Dynamically constructs and attaches a new downstream [Coral] node based on the computed data.
  ///
  /// **Core Concept (Dynamic Topological Cascading):**
  /// Enables dynamic pipelines where the architecture of the topological graph can morph
  /// at runtime depending on the computed data payload.
  ///
  /// * [cascade]: A builder callback that yields the next [Coral] node.
  /// * [seal]: If `true`, the resulting node cannot be detached from the source. Defaults to `true`.
  /// * [hotswap]: If `true`, allows swapping the downstream sub-graph smoothly. Defaults to `false`.
  /// * [eager]: If `true`, computes the downstream sub-graph eagerly. Defaults to `false`.
  ///
  /// **Ensures:**
  /// * Returns a new [Coral] node whose snapshot represents the computed state of the active branch.
  /// * Automatically propagates state updates from both the source node and the active branch.
  ///
  /// **Example:**
  /// ```dart
  /// // Dynamically switch to a different repository based on the user's role
  /// final roleCoral = Coral.data(UserRole.admin);
  /// final repositoryCoral = roleCoral.cascade((role) {
  ///   if (role == UserRole.admin) return AdminRepositoryCoral();
  ///   return GuestRepositoryCoral();
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
  /// **Example:**
  /// ```dart
  /// final searchQueryCoral = Coral.data("hello");
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
  /// * [seal]: If `true`, the resulting [Trunk] is sealed and cannot be modified. Defaults to `true`.
  /// * [hotswap]: If `true`, allows swapping component nodes. Defaults to `false`.
  /// * [eager]: If `true`, computes child nodes eagerly. Defaults to `false`.
  ///
  /// **Ensures:**
  /// * Returns a [Trunk] bundle representing the diverged child [Coral] nodes.
  ///
  /// **Example:**
  /// ```dart
  /// // Split a single list of IDs into individual Coral nodes for concurrent processing
  /// final userIdsCoral = Coral.data(["user1", "user2", "user3"]);
  /// final userTrunk = userIdsCoral.diverge(
  ///   (ids) => ids.map((id) => UserProfileCoral(id)),
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
  /// **Ensures:**
  /// * Returns a new [Coral] node that is guaranteed to contain a valid payload if the respective
  ///   fallback callback is provided and resolves successfully.
  ///
  /// **Example:**
  /// ```dart
  /// final networkCoral = fetchNetworkData();
  /// final safeCoral = networkCoral.fallback(
  ///   onEmpty: () => "Loading...",
  ///   onDamage: (err, stack) => "Error occurred: $err",
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
  /// **Example:**
  /// ```dart
  /// final uninitializedCoral = Coral<String>.empty();
  /// final nullCoral = uninitializedCoral.fallbackEmptyToNull(); // Payload is now 'null'
  /// ```
  Coral<S?> fallbackEmptyToNull() => _FallbackEmptyToNullCoral<S?>(this);

  /// Conditionally blocks downstream computation based on validation checks.
  ///
  /// **Core Concept (Pipeline Guard):**
  /// Prevents downstream computation from continuing under invalid contexts. If [canProceed]
  /// returns false, the pipeline transitions immediately into a damaged state.
  ///
  /// * [canProceed]: A callback validation function that must return `true` to allow computation.
  /// * [getReason]: A callback returning the error object to store in the damaged state.
  ///
  /// **Ensures:**
  /// * Returns a new [Coral] node that remains valid only if [canProceed] resolves to `true`.
  /// * Transitions to a damaged state if the guard condition fails.
  ///
  /// **Example:**
  /// ```dart
  /// final fileReaderCoral = readFileCoral();
  /// final safeFileReader = fileReaderCoral.guard(
  ///   canProceed: () => hasFilePermissions(),
  ///   getReason: () => "Permission denied",
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
  /// **Example:**
  /// ```dart
  /// final countCoral = Coral.data(5);
  /// final stringCoral = countCoral.map((count) => "Count is $count");
  /// ```
  Coral<T> map<T>(T Function(S source) convert) => _MapCoral<S, T>(this, convert: convert);
}

/// **Core Concept (Provider Delegation):**
/// A convenience extension that allows computation operators to be called directly
/// on any [CoralProvider] (such as `Coralline` or custom components), automatically
/// delegating the operation to the underlying [Coral] node.
extension CoralProviderComputationExtension<S> on CoralProvider<S> {
  /// Delegates [CoralComputationExtension.cascade] to the underlying [Coral].
  Coral<T> cascade<T>(
    Coral<T> Function(S data) cascade, {
    bool eager = false,
  }) =>
      coral.cascade(cascade, eager: eager);

  /// Delegates [CoralComputationExtension.distinct] to the underlying [Coral].
  Coral<S> distinct([bool Function(S previous, S next)? equals]) => coral.distinct(equals);

  /// Delegates [CoralComputationExtension.diverge] to the underlying [Coral].
  Trunk<T> diverge<T>(
    Iterable<Coral<T>> Function(S data) cascade, {
    bool seal = true,
    bool hotswap = false,
    bool eager = false,
  }) =>
      coral.diverge(cascade, seal: seal, hotswap: hotswap, eager: eager);

  /// Delegates [CoralComputationExtension.fallback] to the underlying [Coral].
  Coral<S> fallback({
    S Function()? onEmpty,
    S Function(Object error, [StackTrace? stackTrace])? onDamage,
  }) =>
      coral.fallback(onEmpty: onEmpty, onDamage: onDamage);

  /// Delegates [CoralComputationExtension.fallbackEmptyToNull] to the underlying [Coral].
  Coral<S?> fallbackEmptyToNull() => coral.fallbackEmptyToNull();

  /// Delegates [CoralComputationExtension.guard] to the underlying [Coral].
  Coral<S> guard({required bool Function() canProceed, Object? Function()? getReasonIfCannotProceed}) =>
      coral.guard(canProceed: canProceed, getReason: getReasonIfCannotProceed);

  /// Delegates [CoralComputationExtension.map] to the underlying [Coral].
  Coral<T> map<T>(T Function(S source) convert) => coral.map(convert);
}

/// **Core Concept (Collection Utility):**
/// Provides convenience methods to inspect and manipulate an `Iterable` of [Coral] nodes
/// as a cohesive group, without needing to manually map over their snapshots.
extension CoralCollectionExtension<T> on Iterable<Coral<T>> {
  /// **Core Concept:**
  /// Extracts the underlying data from all Corals in this collection.
  ///
  /// **AI & Developer Note (Fail-Fast Enforcement):**
  /// This extension property enforces Coralline's Fail-Fast design at the collection level.
  /// If any [Coral] in the iteration is in an `empty` or `damaged` state, reading `coral.data`
  /// will immediately throw an exception.
  ///
  /// This guarantees that downstream processes do not inadvertently operate on partial or
  /// corrupted data sets, preserving structural integrity.
  Iterable<T> get data => map((coral) => coral.data);

  /// **Core Concept:**
  /// Bundles this collection of individual [Coral] nodes into a single [Trunk].
  ///
  /// * [seal]: If `true` (default), bundled lines are permanently owned by this trunk
  ///   and cannot be detached or claimed by external downstream parents without explicit release.
  /// * [hotswap]: If `true` (only applicable when [seal] is `false`), enables mooring point
  ///   safeguards for bundled lines when they are swapped or claimed by downstream parent nodes
  ///   while active.
  ///
  /// **Note on [hotswap]:**
  /// Setting [seal] to `false` permits *external* downstream nodes (e.g., couplers, converging or
  /// diverging trunks) to claim or swap child lines out of this trunk. Setting [hotswap] to `true`
  /// ensures that if an active child line is detached by an external node, it is safely transferred
  /// to a mooring point safeguard rather than immediately deactivated.
  Trunk<T> toTrunk({bool seal = true, bool hotswap = false}) => Trunk.of(this, seal: seal, hotswap: hotswap);
}

/// **Core Concept (Snapshot Collection Utility):**
/// Provides convenience methods to inspect and manipulate an `Iterable` of [CoralSnapshot]s
/// as a cohesive group.
extension CoralSnapshotCollectionExtension<T> on Iterable<CoralSnapshot<T>> {
  /// **Core Concept:**
  /// Extracts the underlying data from all snapshots in this collection.
  ///
  /// **AI & Developer Note (Fail-Fast Enforcement):**
  /// Inherits strict validation. Throws an exception if any snapshot in the collection
  /// is `isEmpty` or `isDamaged`.
  Iterable<T> get data => map((snapshot) => snapshot.data);
}

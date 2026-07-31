// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// Provides a dynamic connector that allows hotswapping or coldswapping the middle
/// section of a [Coral] pipeline at runtime.
///
/// **Core Concept (Dynamic Topology Mutation):**
/// Standard [Coral] pipelines are statically linked and immutable in their structure.
/// [CoralCoupler] introduces a dynamic socket into the pipeline. This allows developers
/// to seamlessly switch the inbound source node at runtime without tearing down and
/// rebuilding the entire downstream pipeline.
///
/// **Common Use Cases:**
/// * **Environment Swapping:** Dynamically swapping a mock data source with a live API
///   source during testing.
/// * **Session Management:** Changing the current user's profile stream when a new user
///   logs in, while keeping the UI subscribed to the same downstream coupler.
/// * **Feature Toggles:** Rerouting data flows based on remote configuration changes.
///
/// **Design Philosophy & Safety:**
/// * **Lifecycle Guarantees:** Swapping handles all lifecycle transitions automatically.
///   If the coupler is active, the newly coupled node is immediately activated. The old
///   node is gracefully deactivated and detached.
/// * **Mooring Point (GC Safety):** Swapped-out nodes are safely detached and sent to
///   a mooring scheduler to ensure they can be cleanly garbage collected, preventing
///   memory leaks.
///
/// **AI & Developer Note:**
/// Swapping nodes during active execution requires `hotswap: true` to be set during
/// initialization. Attempting to couple a node strongly owned by a non-detachable parent
/// will throw a [CoralNodeReleaseViolationException].
///
/// ## Example: Hotswapping Data Sources
/// ```dart
/// // 1. Define two different data sources
/// final mockApi = Coral.value(UserProfile(name: 'Guest', isPremium: false));
/// final liveApi = Coral.stream(
///   webSocketClient.stream.map((json) => UserProfile.fromJson(json)),
/// );
///
/// // 2. Create a coupler starting with the mock source (Guest state)
/// final coupler = CoralCoupler<UserProfile>(mockApi, hotswap: true);
///
/// // 3. Build a downstream pipeline connected to the coupler
/// final greetingPipeline = coupler.coral.map((profile) {
///   return 'Welcome, ${profile.name}!';
/// });
///
/// // 4. Activate the pipeline (it will pull 'Guest' data)
/// greetingPipeline.activate();
/// print(greetingPipeline.snapshot.data); // Outputs: "Welcome, Guest!"
///
/// // 5. Hotswap the source to the live API when the user logs in
/// coupler.couple(liveApi);
/// ```
sealed class CoralCoupler<T> implements CoralProvider<T> {
  /// Creates a [CoralCoupler] with an initial [inbound] node.
  ///
  /// * [seal]: If `true`, the coupler permanently owns the attached node, and it cannot
  ///   be detached by another coupler.
  /// * [hotswap]: If `true`, allows swapping nodes while the coupler is actively running.
  factory CoralCoupler(Coral<T> inbound, {bool seal, bool hotswap}) = _CoralCouplerBase;

  /// Creates a [CoralCoupler] in a late/empty state.
  ///
  /// The coupler will remain in an empty state until a valid node is coupled.
  factory CoralCoupler.late({bool seal, bool hotswap}) = _CoralCouplerBase.late;

  /// Returns whether the coupler and its downstream pipeline have been activated.
  @override
  bool get isActivated;

  /// Returns whether the coupler is currently running and processing data.
  @override
  bool get isRunning;

  /// Returns whether the coupler is temporarily paused.
  @override
  bool get isPaused;

  /// Returns whether the coupler has been permanently deactivated.
  @override
  bool get isDeactivated;

  /// Retrieves the most recent data snapshot from the currently coupled node.
  CoralSnapshot<T> get snapshot;

  /// Exposes the underlying [Coral] proxy node for downstream chaining.
  @override
  Coral<T> get coral;

  /// Swaps the currently attached inbound source node with [newInbound].
  ///
  /// **Core Concept (Dynamic Node Swapping):**
  /// Replaces the active upstream provider with a new one at runtime.
  ///
  /// Returns the old inbound node that was detached, or `null` if no node was attached.
  ///
  /// **Requires:**
  /// * The [newInbound] node MUST NOT be already attached to another non-detachable (sealed)
  ///   parent node or terminal.
  ///
  /// **Ensures:**
  /// * If this coupler is currently active, the [newInbound] node is automatically activated.
  /// * The previously attached node is decoupled and transferred to a mooring scheduler
  ///   for safe garbage collection.
  ///
  /// **AI & Developer Note (Ownership Constraints):**
  /// Attempting to couple a node strongly owned by a non-detachable parent will throw a
  /// [CoralNodeReleaseViolationException]. However, if the old parent is detachable
  /// (e.g., another coupler with `seal: false`), the node will release itself and transfer
  /// ownership safely to this coupler.
  ///
  /// ## Example
  /// ```dart
  /// final oldNode = coupler.couple(newLiveApiNode);
  /// print('Detached: $oldNode');
  /// ```
  Coral<T>? couple(Coral<T> newInbound);

  /// Swaps the inbound node safely using a callback.
  ///
  /// **Core Concept (Safe Swapping):**
  /// Automatically catches and wraps any synchronous exceptions into a `damaged` state
  /// to prevent pipeline crashes.
  ///
  /// ## Example
  /// ```dart
  /// coupler.coupleGuarded(() {
  ///   return buildComplexSourceNode();
  /// });
  /// ```
  Coral<T>? coupleGuarded(Coral<T> Function() callback);

  /// Immediately releases the currently attached inbound node.
  ///
  /// **Core Concept (Manual Release):**
  /// Decouples the active node. Once decoupled, the coupler enters an empty state
  /// until a new node is coupled.
  void decouple();

  /// Decouples the node only if the currently attached inbound matches [coralNode].
  ///
  /// **Core Concept (Conditional Release):**
  /// Compares the currently attached node reference and decouples it if it matches.
  ///
  /// Returns `true` if the node matched and was successfully decoupled.
  bool tryDecoupling(CoralNode coralNode);

  /// Sets the coupler's state to damaged with the provided [error].
  ///
  /// **Core Concept (Manual Damage Injection):**
  /// Injecting errors into the pipeline manually is useful during testing
  /// or when an external error occurs that should be reflected in the pipeline.
  Coral<T> setError(Object error, [StackTrace? stackTrace]);
}

/// Provides a dynamic connector that allows hotswapping or coldswapping the middle
/// section of a [Trunk] (multi-node) pipeline at runtime.
///
/// **Core Concept (Dynamic Topology Mutation):**
/// Just as [CoralCoupler] provides a dynamic socket for a single [Coral] node,
/// [TrunkCoupler] provides a dynamic socket for a complex [Trunk] group.
/// This allows you to replace an entire sub-graph of nodes with another
/// sub-graph without breaking the downstream connections.
///
/// **Common Use Cases:**
/// * **Form Flow Changes:** Swapping an entire group of input validation nodes when the
///   user switches authentication methods (e.g., from Email to Phone).
/// * **Complex State Swapping:** Replacing a complex dashboard data trunk with a
///   different configuration dynamically.
///
/// **Design Philosophy & Safety:**
/// Follows the identical lifecycle guarantees and garbage collection (Mooring)
/// safety mechanisms as [CoralCoupler].
///
/// **AI & Developer Note:**
/// Swapping trunks during active execution requires `hotswap: true` to be set during
/// initialization. Attempting to couple a trunk strongly owned by a non-detachable parent
/// will throw a [CoralNodeReleaseViolationException].
///
/// ## Example: Swapping Input Validation Trunks
/// ```dart
/// // 1. Define two different trunk pipelines for inputs (assuming String values)
/// final emailTrunk = Trunk.of([emailCoral, passwordCoral]);
/// final phoneTrunk = Trunk.of([phoneCoral, smsCodeCoral]);
///
/// // 2. Create a trunk coupler starting with the email trunk
/// final authCoupler = TrunkCoupler<String>(emailTrunk, hotswap: true);
///
/// // 3. Build a downstream pipeline that aggregates the active trunk
/// final loginPipeline = authCoupler.aggregate((lines) {
///   final id = lines.first.snapshot.data;
///   final secret = lines.last.snapshot.data;
///   return submitLogin(id, secret);
/// });
///
/// // 4. Later, swap to the phone authentication trunk dynamically
/// authCoupler.couple(phoneTrunk);
/// ```
sealed class TrunkCoupler<T> implements TrunkProvider<T> {
  /// Creates a [TrunkCoupler] with an initial [inbound] group.
  ///
  /// * [seal]: If `true`, the coupler permanently owns the attached group, and it
  ///   cannot be detached by another coupler.
  /// * [hotswap]: If `true`, allows swapping groups while the coupler is actively running.
  factory TrunkCoupler(Trunk<T> inbound, {bool seal, bool hotswap}) = _TrunkCouplerBase;

  /// Creates a [TrunkCoupler] in a late/empty state.
  ///
  /// The coupler will remain in an empty state until a valid group is coupled.
  factory TrunkCoupler.late({bool seal, bool hotswap}) = _TrunkCouplerBase.late;

  /// Whether the coupler and its downstream pipeline have been activated.
  @override
  bool get isActivated;

  /// Whether the coupler is currently running and processing data.
  @override
  bool get isRunning;

  /// Whether the coupler is temporarily paused.
  @override
  bool get isPaused;

  /// Whether the coupler has been permanently deactivated.
  @override
  bool get isDeactivated;

  /// Retrieves the most recent data snapshot from the currently coupled group.
  TrunkSnapshot<T> get snapshot;

  /// Exposes the underlying [Trunk] proxy group for downstream chaining.
  @override
  Trunk<T> get trunk;

  /// Swaps the currently attached inbound source group with [newInbound].
  ///
  /// **Core Concept (Dynamic Node Swapping):**
  /// Replaces the active upstream provider group with a new one at runtime.
  ///
  /// Returns the old inbound group that was detached, or `null` if no group was attached.
  ///
  /// **Requires:**
  /// * The [newInbound] group MUST NOT be already attached to another non-detachable
  ///   (sealed) parent node or terminal.
  ///
  /// **Ensures:**
  /// * If this coupler is currently active, the [newInbound] group is automatically activated.
  /// * The previously attached group is decoupled and transferred to a mooring scheduler
  ///   for safe garbage collection.
  ///
  /// **AI & Developer Note (Ownership Constraints):**
  /// Attempting to couple a group strongly owned by a non-detachable parent will throw a
  /// [CoralNodeReleaseViolationException]. However, if the old parent is detachable
  /// (e.g., another coupler with `seal: false`), the group will release itself and transfer
  /// ownership safely to this coupler.
  ///
  /// ## Example
  /// ```dart
  /// final oldGroup = trunkCoupler.couple(newFormValidationTrunk);
  /// print('Detached: $oldGroup');
  /// ```
  Trunk<T>? couple(Trunk<T> newInbound);

  /// Safely swaps the inbound group using a callback.
  ///
  /// **Core Concept (Safe Swapping):**
  /// Automatically catches and wraps any synchronous exceptions into a `damaged` state
  /// to prevent pipeline crashes.
  ///
  /// ## Example
  /// ```dart
  /// trunkCoupler.coupleGuarded(() {
  ///   return buildComplexFormTrunk();
  /// });
  /// ```
  Trunk<T>? coupleGuarded(Trunk<T> Function() callback);

  /// Immediately releases the currently attached inbound group.
  ///
  /// **Core Concept (Manual Release):**
  /// Decouples the active group. Once decoupled, the coupler enters an empty state
  /// until a new group is coupled.
  void decouple();

  /// Attempts to decouple only if the currently attached inbound exactly matches [coralNode].
  ///
  /// **Core Concept (Conditional Release):**
  /// Compares the currently attached node reference and decouples it if it matches.
  ///
  /// Returns `true` if the node matched and was successfully decoupled.
  bool tryDecoupling(CoralNode coralNode);

  /// Forcibly sets the coupler's state to damaged with the provided [error].
  ///
  /// **Core Concept (Manual Damage Injection):**
  /// Injecting errors into the pipeline manually is useful during testing
  /// or when an external error occurs that should be reflected in the pipeline.
  Trunk<T> setError(Object error, [StackTrace? stackTrace]);
}

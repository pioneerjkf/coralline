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
/// ## Dynamic Socket Hotswap Diagram
/// ```text
/// [Initial Inbound] ──(Detach & Deactivate)──┐
///                                            ├──> [CoralCoupler Socket] ──> [Downstream Pipeline]
/// [New Inbound]     ──(Attach & Activate)────┘
/// ```
///
/// **Warning (Anti-Pattern Prevention):**
///
/// * **BAD (Using `hotswap: false` when swapping pipelines that share upstream resources):**
///   ```dart
///   final sourceA = Coral.data(1);
///   final sourceB = Coral.data(2);
///   // Coldswap (hotswap: false) synchronously deactivates and detaches sourceA immediately
///   // during couple(sourceB), before the current microtask finishes re-wiring.
///   final coupler = CoralCoupler<int>(sourceA, hotswap: false);
///   final terminal = coupler.coral.toTerminal(() {});
///   terminal.activate();
///   coupler.couple(sourceB);
///   ```
/// * **GOOD (Enable `hotswap: true` to defer old-node deactivation to the microtask boundary):**
///   ```dart
///   final sourceA = Coral.data(1);
///   final sourceB = Coral.data(2);
///   // Hotswap (hotswap: true) transfers sourceA to the internal mooring point so its
///   // deactivation is deferred until the end of the microtask, avoiding premature teardown.
///   final coupler = CoralCoupler<int>(sourceA, hotswap: true);
///   final terminal = coupler.coral.toTerminal(() {});
///   terminal.activate();
///   coupler.couple(sourceB);
///   ```
///
/// **Implementation note:**
/// Both `hotswap: false` (coldswap) and `hotswap: true` (hotswap) permit calling [couple]
/// while the coupler is active. With `hotswap: false`, the outgoing node is synchronously
/// deactivated and detached during [couple]; with `hotswap: true`, the outgoing node is
/// held in an internal mooring queue and deactivated at the end of the microtask.
/// If [couple] is given a node strongly owned by a non-detachable (`seal: true`) parent,
/// the resulting [CoralNodeReleaseViolationException] is caught internally and transitions
/// the coupler into a `damaged` state rather than crashing the caller.
///
/// ## Examples
/// ```dart
/// class UserProfile {
///   const UserProfile({required this.name, required this.isPremium});
///   final String name;
///   final bool isPremium;
/// }
///
/// // 1. Define two different data sources
/// final mockApi = Coral.data(const UserProfile(name: 'Guest', isPremium: false));
/// final liveApi = Stream.value(
///   const UserProfile(name: 'Alice', isPremium: true),
/// ).toCoral();
///
/// // 2. Create a coupler starting with the mock source (Guest state)
/// final coupler = CoralCoupler<UserProfile>(mockApi, hotswap: true);
///
/// // 3. Build a downstream pipeline connected to the coupler
/// final greetingPipeline = coupler.coral.map((profile) {
///   return 'Welcome, ${profile.name}!';
/// });
///
/// // 4. Activate the pipeline via a terminal (it will pull 'Guest' data)
/// final terminal = greetingPipeline.toTerminal(() {});
/// terminal.activate();
/// print(terminal.data); // Outputs: "Welcome, Guest!"
///
/// // 5. Hotswap the source to the live API when the user logs in
/// coupler.couple(liveApi);
/// ```
sealed class CoralCoupler<T> implements CoralProvider<T> {
  /// Creates a [CoralCoupler] with an initial [inbound] node.
  ///
  /// * [inbound]: The initial upstream [Coral] node to attach.
  /// * [seal]: If `true`, the coupler permanently owns the attached node, and it cannot
  ///   be stolen by another coupler without first calling [decouple].
  /// * [hotswap]: If `true`, defers deactivation and detachment of swapped-out nodes to the
  ///   end of the current microtask via the internal mooring scheduler.
  factory CoralCoupler(Coral<T> inbound, {bool seal, bool hotswap}) = _CoralCouplerBase;

  /// Creates a [CoralCoupler] in a late/empty state.
  ///
  /// The coupler remains in an `empty` state until a valid node is coupled via [couple].
  ///
  /// * [seal]: If `true`, the coupler permanently owns any subsequently coupled node.
  /// * [hotswap]: If `true`, defers deactivation and detachment of swapped-out nodes to the
  ///   end of the current microtask via the internal mooring scheduler.
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

  /// Returns whether the coupler is currently in the deactivated (inactive) state.
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
  /// * [newInbound]: The new upstream [Coral] node to attach to this coupler.
  ///
  /// Returns `null` if [newInbound] is identical to the currently attached node;
  /// otherwise returns the previously attached [Coral] node (which is an empty
  /// sentinel node when the coupler was previously uncoupled or initialized via [CoralCoupler.late]).
  ///
  /// **Requires:**
  /// * The [newInbound] node should not already be attached to a non-detachable (`seal: true`)
  ///   parent node or terminal.
  ///
  /// **Ensures:**
  /// * If this coupler is currently active, [newInbound] is automatically synchronized to the coupler's lifecycle state.
  /// * With `hotswap: false`, the outgoing node is synchronously deactivated and detached; with `hotswap: true`,
  ///   its deactivation and detachment are deferred to the end of the microtask via the mooring scheduler.
  /// * If attaching [newInbound] fails (for example, with a [CoralNodeReleaseViolationException] because
  ///   [newInbound] is sealed to another parent), the exception is caught and stored as a `damaged` snapshot
  ///   on this coupler, and the previous inbound node is returned.
  ///
  /// ## Examples
  /// ```dart
  /// final coupler = CoralCoupler<int>(Coral.data(1), hotswap: true);
  /// final oldNode = coupler.couple(Coral.data(2));
  /// print('Detached: $oldNode');
  /// ```
  Coral<T>? couple(Coral<T> newInbound);

  /// Swaps the inbound node safely using a [callback].
  ///
  /// **Core Concept (Safe Swapping):**
  /// Automatically catches and wraps any synchronous exceptions thrown by [callback]
  /// into a `damaged` state to prevent pipeline crashes.
  ///
  /// * [callback]: A function that constructs and returns the new [Coral] node to couple.
  ///
  /// ## Examples
  /// ```dart
  /// final coupler = CoralCoupler<int>.late(hotswap: true);
  /// coupler.coupleGuarded(() => Coral.data(42));
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
  /// * [coralNode]: The candidate node reference to compare against the currently attached inbound node.
  ///
  /// Returns `true` if the node matched and was successfully decoupled.
  bool tryDecoupling(CoralNode coralNode);

  /// Sets the coupler's state to damaged with the provided [error] and optional [stackTrace].
  ///
  /// **Core Concept (Manual Damage Injection):**
  /// Injecting errors into the pipeline manually is useful during testing
  /// or when an external error occurs that should be reflected in the pipeline.
  ///
  /// * [error]: The error object to store in the coupler's damaged snapshot.
  /// * [stackTrace]: Optional stack trace associated with [error].
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
/// **Implementation note:**
/// Both `hotswap: false` (coldswap) and `hotswap: true` (hotswap) permit calling [couple]
/// while the coupler is active. With `hotswap: true`, deactivation of the outgoing trunk
/// is deferred until the end of the microtask. If [couple] is given a trunk strongly owned
/// by a non-detachable (`seal: true`) parent, the [CoralNodeReleaseViolationException] is
/// caught internally and transitions the coupler into a `damaged` state.
///
/// ## Examples
/// ```dart
/// final emailCoral = Coral.data('user@example.com');
/// final passwordCoral = Coral.data('secret');
/// final phoneCoral = Coral.data('+1234567890');
/// final smsCodeCoral = Coral.data('123456');
///
/// // 1. Define two different trunk pipelines for inputs
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
///   return '$id:$secret';
/// });
///
/// // 4. Later, swap to the phone authentication trunk dynamically
/// authCoupler.couple(phoneTrunk);
/// ```
sealed class TrunkCoupler<T> implements TrunkProvider<T> {
  /// Creates a [TrunkCoupler] with an initial [inbound] group.
  ///
  /// * [inbound]: The initial upstream [Trunk] group to attach.
  /// * [seal]: If `true`, the coupler permanently owns the attached group, and it
  ///   cannot be stolen by another coupler without first calling [decouple].
  /// * [hotswap]: If `true`, defers deactivation and detachment of swapped-out groups to the
  ///   end of the current microtask via the internal mooring scheduler.
  factory TrunkCoupler(Trunk<T> inbound, {bool seal, bool hotswap}) = _TrunkCouplerBase;

  /// Creates a [TrunkCoupler] in a late/empty state.
  ///
  /// The coupler remains in an `empty` state until a valid group is coupled via [couple].
  ///
  /// * [seal]: If `true`, the coupler permanently owns any subsequently coupled group.
  /// * [hotswap]: If `true`, defers deactivation and detachment of swapped-out groups to the
  ///   end of the current microtask via the internal mooring scheduler.
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

  /// Whether the coupler is currently in the deactivated (inactive) state.
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
  /// * [newInbound]: The new upstream [Trunk] group to attach to this coupler.
  ///
  /// Returns `null` if [newInbound] is identical to the currently attached group;
  /// otherwise returns the previously attached [Trunk] group (which is an empty
  /// sentinel trunk when the coupler was previously uncoupled or initialized via [TrunkCoupler.late]).
  ///
  /// **Requires:**
  /// * The [newInbound] group should not already be attached to a non-detachable
  ///   (`seal: true`) parent node or terminal.
  ///
  /// **Ensures:**
  /// * If this coupler is currently active, [newInbound] is automatically synchronized to the coupler's lifecycle state.
  /// * With `hotswap: false`, the outgoing group is synchronously deactivated and detached; with `hotswap: true`,
  ///   its deactivation and detachment are deferred to the end of the microtask via the mooring scheduler.
  /// * If attaching [newInbound] fails (for example, with a [CoralNodeReleaseViolationException] because
  ///   [newInbound] is sealed to another parent), the exception is caught and stored as a `damaged` snapshot
  ///   on this coupler, and the previous inbound group is returned.
  ///
  /// ## Examples
  /// ```dart
  /// final trunkCoupler = TrunkCoupler<int>(Trunk.of([Coral.data(1)]), hotswap: true);
  /// final oldGroup = trunkCoupler.couple(Trunk.of([Coral.data(2)]));
  /// print('Detached: $oldGroup');
  /// ```
  Trunk<T>? couple(Trunk<T> newInbound);

  /// Safely swaps the inbound group using a [callback].
  ///
  /// **Core Concept (Safe Swapping):**
  /// Automatically catches and wraps any synchronous exceptions thrown by [callback]
  /// into a `damaged` state to prevent pipeline crashes.
  ///
  /// * [callback]: A function that constructs and returns the new [Trunk] group to couple.
  ///
  /// ## Examples
  /// ```dart
  /// final trunkCoupler = TrunkCoupler<int>.late(hotswap: true);
  /// trunkCoupler.coupleGuarded(() => Trunk.of([Coral.data(1)]));
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
  /// * [coralNode]: The candidate node reference to compare against the currently attached inbound group.
  ///
  /// Returns `true` if the node matched and was successfully decoupled.
  bool tryDecoupling(CoralNode coralNode);

  /// Forcibly sets the coupler's state to damaged with the provided [error] and optional [stackTrace].
  ///
  /// **Core Concept (Manual Damage Injection):**
  /// Injecting errors into the pipeline manually is useful during testing
  /// or when an external error occurs that should be reflected in the pipeline.
  ///
  /// * [error]: The error object to store in the coupler's damaged snapshot.
  /// * [stackTrace]: Optional stack trace associated with [error].
  Trunk<T> setError(Object error, [StackTrace? stackTrace]);
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

/// The foundational mixin that defines topological joint capabilities and ownership contracts for reactive nodes.
///
/// [_Joint] acts as the common base abstraction for all reactive parent nodes (such as single-inbound
/// [_Coralline] and multi-inbound [_Trunkline]). It manages upstream dependency resolution,
/// clearance routing, terminal intent resolution, and graph ownership release policy.
///
/// **Design Philosophy:**
/// Strict Single-Parent Topology. Every [CoralNode] in the reactive graph strictly belongs to a single
/// parent [_Joint]. This strict ownership model prevents multi-parent references, diamond dependency
/// bugs, and silent state corruption during declarative graph mutations.
///
/// **AI & Developer Note:**
/// Do not bypass [_releaseCoralNodeOrThrow] when transferring or detaching nodes. If a joint needs
/// dynamic node detachment (e.g., hotswapping or coldswapping), override [_releaseCoralNodeOrThrow] in a
/// specialized mixin rather than mutating `_joint` references directly.
base mixin _Joint on _CorallineLifecycle implements _CorallineTopology {
  /// Resolves the nearest clearance point for dirty signal propagation.
  ///
  /// **Requires:**
  /// * The joint must be placed within a valid topological graph hierarchy.
  ///
  /// **Ensures:**
  /// * Returns the active [_ClearancePoint] or `null` if no clearance point is bound upstream.
  _ClearancePoint? _resolveClearancePoint();

  /// Resolves the current terminal execution intent.
  ///
  /// **Ensures:**
  /// * Returns the active [CorallineTerminalIntent] or `null` if no terminal is bound.
  CorallineTerminalIntent? _resolveTerminalIntent();

  /// Enforces the strict ownership release contract for graph mutations.
  ///
  /// This method acts as a strict defense mechanism against illegal graph mutations,
  /// enforcing a Topological Security Policy across the pipeline.
  ///
  /// * [coralNode]: The node requesting ownership release from this joint.
  ///
  /// **Requires:**
  /// * [coralNode] must be an existing inbound dependency of this joint.
  ///
  /// **Ensures:**
  /// * If overridden by dynamic joints (e.g., [_DetachableHotswapCorallineMixin]), gracefully
  ///   releases [coralNode] and resets inbound references without crashing.
  ///
  /// **Throws:**
  /// * Throws [CoralNodeReleaseViolationException] by default if an illegal ownership transfer is attempted.
  void _releaseCoralNodeOrThrow(CoralNode coralNode) => throw CoralNodeReleaseViolationException(this, coralNode);

  /// Returns an iterable over all direct upstream [CoralNode] dependencies attached to this joint.
  ///
  /// **Ensures:**
  /// * Returns an iterable containing all direct inbound node references.
  Iterable<CoralNode> _iterateInbound();
}

/// Abstract base node class that combines [CoralNode] with [_Joint] topology capabilities.
///
/// [_JointNode] serves as the concrete structural foundation for all intermediate and terminal nodes
/// in the reactive graph. It connects [CoralNode]'s fasttrack property resolution (`_clearancePoint`
/// and `_terminalIntent`) to [_Joint]'s contract resolution methods.
///
/// **Design Philosophy:**
/// Zero-Overhead Delegated Property Resolution. Delegates clearance and terminal intent resolution
/// directly to inlined property reads (`_clearancePoint` and `_terminalIntent`), ensuring minimal stack
/// frame overhead during high-frequency reactive updates.
///
/// **AI & Developer Note:**
/// Subclasses extending [_JointNode] must mix in a specific inbound handler (such as [_Coralline] or [_Trunkline])
/// to complete the inbound topology contract.
abstract base class _JointNode extends CoralNode with _Joint {
  @override
  @pragma('vm:prefer-inline')
  _ClearancePoint? _resolveClearancePoint() => _clearancePoint;
  @override
  @pragma('vm:prefer-inline')
  CorallineTerminalIntent? _resolveTerminalIntent() => _terminalIntent;
}

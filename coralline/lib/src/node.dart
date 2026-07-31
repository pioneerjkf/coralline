// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// **Core Concept:**
/// The abstract base class representing any reactive node participating in the CORAL architecture.
/// It acts as the common base for all single-value nodes ([Coral]) and bundled nodes ([Trunk]).
///
/// `CoralNode` is a combination of **`CORAL`** (the acronym representing the architecture)
/// and **`Node`** (representing a reactive component):
/// - **`CORAL`**: **C**hain **o**f **R**eactivity **a**nd **L**azy-computation.
/// - **`Node`**: The topological node structure carrying data flow and dirty signals.
///
/// **Design Philosophy (Separating "Nodes" from "Lines"):**
/// To minimize cognitive load for developers using or contributing to the framework, the naming
/// follows a strict semantic separation between topological **"Points" (Nodes)** and **"Connections" (Lines/Environment)**:
///
/// * **`Coral` Prefix (`CoralNode`, [Coral], `CoralController`, [Trunk])**:
///   Represents **discrete node/data-centric abstractions**. These are the actual topological
///   elements that carry states, hold snapshots, or wrap values (e.g., `Coral<T> extends CoralNode`).
///   - *Why not `CorallineNode`?* Individually, a node is a single topological point, not a pipeline ("line") itself.
///     Furthermore, `Coral extends CorallineNode` would break class hierarchy symmetry and introduce semantic redundancy.
///
/// * **`Coralline` Prefix ([CorallineTerminal], [CorallineLifecycleStatus], internal [_CorallineNode] joints)**:
///   Represents **pipeline/infrastructure/environmental abstractions** (CORAL + line). These represent
///   the actual pipelines, connection links, and environments that coordinate how multiple nodes interact.
///   - For example, [CorallineTerminal] acts as the pipeline's exit interface, and `_CorallineNode` acts as
///     the connection pipe/joint binding an inbound node to a parent.
sealed class CoralNode extends _CorallineLifecycle with _CorallineFasttrack implements _CorallineTopology {
  @override
  _Joint? _joint;

  @mustCallSuper
  void _attach(_Joint joint) {
    assert(
        !identical(this, joint),
        'A self-referencing attachment was detected: '
        'a coralNode(-> $this) cannot be attached to itself.');

    assert(
        !joint._debugIterateDownstream()._containsIdentical(this),
        'A cyclic attachment was detected: '
        'the target joint(-> $joint) already forwards to this coralNode(-> $this). '
        'This attachment request is rejected to prevent an infinite loop.');

    if (!identical(_joint, joint)) {
      _joint?._releaseCoralNodeOrThrow(this);
      _joint = joint;
      final rerouted = _rerouteClearancePoint();
      if (rerouted) {
        _suspendBasedOnCorallineOptimistically();
        _updateTerminalIntent();
      }
    } else {
      assert(
          false,
          'A redundant attachment was detected: '
          'the target joint(-> $joint) is already attached to this coralNode(-> $this).');
    }
  }

  @mustCallSuper
  void _detachOptimistically(_Joint joint) {
    try {
      if (identical(joint, _joint)) {
        _joint = null;
        final rerouted = _rerouteClearancePoint();
        if (rerouted) {
          _updateTerminalIntent();
        }
      } else {
        assert(
            false,
            null == _joint
                ? 'An invalid detach request was detected: '
                    'there is no active attachment, but the target joint(-> $joint) '
                    'attempted to detach this coralNode(-> $this).'
                : 'A mismatched detach request was detected: '
                    'the target joint(-> $joint) attempted to detach this coralNode(-> $this) '
                    'which is currently attached to another joint(-> $_joint).');
      }
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  void _suspendBasedOnCorallineOptimistically() {
    try {
      final basePhase = _joint?._state ?? _CoralNodeLifecycleState.inactive;
      switch (basePhase) {
        case _CoralNodeLifecycleState.inactive:
          if (_state.isActivated) _deactivateOptimistically();
          break;

        case _CoralNodeLifecycleState.paused:
          if (_state.isRunning) _pauseOptimistically();
          break;

        case _CoralNodeLifecycleState.running:
          break;
      }
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  void _syncLifecycleBasedOnCorallineOptimistically() {
    try {
      final basePhase = _joint?._state ?? _CoralNodeLifecycleState.inactive;
      switch (basePhase) {
        case _CoralNodeLifecycleState.inactive:
          if (_state.isActivated) _deactivateOptimistically();
          break;

        case _CoralNodeLifecycleState.paused:
          if (_state.isDeactivated) _activateOptimistically();
          if (_state.isRunning) _pauseOptimistically();
          break;

        case _CoralNodeLifecycleState.running:
          if (_state.isDeactivated) _activateOptimistically();
          if (_state.isPaused) _resumeOptimistically();

          break;
      }
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  Iterable<_CorallineTopology> _debugIterateDownstream() sync* {
    _CorallineTopology? joint = _joint;
    while (null != joint) {
      yield joint;
      joint = joint is CoralNode ? joint._joint : null;
    }
  }

  @override
  void _handleUncaughtError(Object error, StackTrace stackTrace) {
    try {
      final terminalIntent = _terminalIntent;
      if (terminalIntent != null) {
        try {
          terminalIntent.handleUncaughtError(error, stackTrace);
          return;
        } catch (handlerError, handlerStack) {
          // If the handler fails, loudly warn in debug mode.
          assert(
            false,
            '🚨 [Coralline] terminalIntent.handleUncaughtError failed!\n'
            'Handler Error: $handlerError\n'
            'Handler StackTrace:\n$handlerStack',
          );
          // BUG FIX: Report the original pipeline error, not the handler's error.
          Zone.current.handleUncaughtError(error, stackTrace);
          return;
        }
      }

      Zone.current.handleUncaughtError(error, stackTrace);
    } catch (fatalError, fatalStack) {
      // The absolute worst-case scenario: Zone's error handler itself threw an exception.
      // We swallow it here to prevent the reactive framework's core loops (broadcaster/scheduler) from crashing.
      assert(
        false,
        '🚨 [Coralline] Fatal error inside _handleUncaughtError!\n'
        'Zone Error: $fatalError\n'
        'Zone StackTrace:\n$fatalStack',
      );
    }
  }

  bool get isActivated => _state.isActivated;

  bool get isRunning => _state.isRunning;

  bool get isPaused => _state.isPaused;

  bool get isDeactivated => _state.isDeactivated;
}

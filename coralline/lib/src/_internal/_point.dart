// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base mixin _DirtyPoint on CoralNode {
  /// **Core Concept (Coalescing Buffer Flag):**
  /// Serves as the core defense mechanism against synchronous notification floods.
  ///
  /// **Operational Mechanism:**
  /// When this node is not running (e.g., during setup or paused state), incoming
  /// [_pushDirty] calls are not propagated down the graph. Instead, this flag is
  /// simply set to `true`. Once the node resumes or activates, it checks this flag
  /// and fires a single, coalesced notification if needed.
  ///
  /// **Performance Characteristics:**
  /// Ensures O(1) flush complexity regardless of how many redundant updates were
  /// received while the node was dormant.
  bool _isDirtyPending = false;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    super._activate();
    if (_isDirtyPending) {
      _isDirtyPending = false;
      _pushDirty();
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _resume() {
    super._resume();
    if (_isDirtyPending) {
      _isDirtyPending = false;
      _pushDirty();
    }
  }

  bool _isPushingDirty = false;

  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _pushDirty() {
    if (!_state.isRunning) {
      _isDirtyPending = true;
      return;
    }

    if (_isPushingDirty) {
      throw CoralNodeReentrancyError('Reentrant call to _pushDirty detected. A dirty point cannot '
          'push again while it is currently in its push phase.');
    }

    try {
      _isPushingDirty = true;
      assert(
          null != _clearancePoint,
          'Cannot notify dirty state because no clearance point is assigned. '
          'The joint must be properly attached before notifying.');
      _clearancePoint!._needClearance(this);
    } finally {
      _isPushingDirty = false;
    }
  }
}

/// A mixin that provides the capability to temporarily suppress dirty signal propagation.
base mixin _SuppressibleDirtyPoint on _DirtyPoint {
  int _suppressedDirtyPushCount = 0;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _pushDirty() {
    if (0 < _suppressedDirtyPushCount) return;
    super._pushDirty();
  }
}

/// Handles cache invalidation and dirty signal propagation (the Clearance phase).
/// See `doc/manual_en/ch2_reactivity.md` for details on the Clearance mechanics.
base mixin _ClearancePoint on _Joint {
  @override
  _ClearancePoint? _resolveClearancePoint() => this;

  bool _markedNeedsClearance = false;

  bool _duringClearancePointActivate = false;

  /// Lifecycle Guard & Mixin Ordering Requirement:
  ///
  /// This [_activate] method acts as a protective shield during the activation phase.
  /// It MUST be the outermost wrapper in the mixin chain (e.g., placed at the end:
  /// `with _Coralline<C>, _ClearancePoint`) to guarantee it executes
  /// BEFORE any inner joints activate their children.
  ///
  /// When `super._activate()` is called, inner joints will activate their child nodes.
  /// Activating children can synchronously trigger a flood of dirty notifications
  /// leading back to `_needClearance()`.
  ///
  /// By setting `_duringClearancePointActivate = true` upfront, any incoming clearance
  /// requests are safely deferred (`_markedNeedsClearance = true`) instead of being
  /// executed immediately on a partially initialized object. Once all activations
  /// finish, the deferred clearance is safely executed at the end.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    try {
      _duringClearancePointActivate = true;
      super._activate();

      // Safely perform any clearance requests that were deferred during the activation phase.
      if (_markedNeedsClearance) {
        _markedNeedsClearance = false;
        try {
          _performClearance();
        } catch (error, stackTrace) {
          _handleUncaughtError(error, stackTrace);
        }
      }
    } finally {
      _duringClearancePointActivate = false;
    }
  }

  bool _isPerformingClearance = false;

  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _needClearance(final _DirtyPoint dirtyPoint) {
    assert(
        dirtyPoint._debugIterateDownstream()._containsIdentical(this),
        'Detached clearance request detected. The dirtyPoint ($dirtyPoint) must '
        'be part of the attached chain leading to this CoralNode ($this). '
        'Handling requests from unrelated points indicates a structural '
        'connectivity failure and may cause resource leaks.');

    assert(
        dirtyPoint._isPushingDirty,
        'Invalid clearance request timing. The dirtyPoint ($dirtyPoint) must '
        'be actively within its dirty push phase to request clearance.');

    // Lifecycle Guard (Deferred Execution):
    // If a clearance request is triggered while this point is in the middle of
    // its activation phase (i.e., super._activate() has not yet fully completed),
    // executing _performClearance() synchronously could cause unpredictable
    // side effects on a partially initialized object.
    // To prevent this, we defer the clearance by marking it and returning immediately.
    // The pending clearance will be safely executed at the very end of _activate().
    if (_duringClearancePointActivate) {
      _markedNeedsClearance = true;
      return;
    }

    assert(
        _state.isRunning,
        'Clearance requests can only be performed while the activity phase is running. '
        'Current phase is $_state.');

    // A clearance request is already in progress.
    // Ignoring duplicate requests to prevent redundant operations,
    // resource waste, and potential stack overflows.
    if (_isPerformingClearance) return;

    try {
      _isPerformingClearance = true;
      _performClearance();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    } finally {
      _isPerformingClearance = false;
    }
  }

  void _performClearance();
}

/// A safe, temporary anchor node in the topological graph designed to prevent
/// lifecycle conflicts and memory leaks during [Hotswap] (dynamic node swapping).
///
/// For detailed mechanics on Hotswapping and Mooring Points, see `doc/manual_en/ch6_dynamic_topology.md`.
base class _MooringPoint extends CoralNode with _Joint, _ClearancePoint {
  @override
  @pragma('vm:prefer-inline')
  CorallineTerminalIntent? _resolveTerminalIntent() => null;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {}

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (!_CorallineScheduler.instance._removeMooring(coralNode)) {
      throw CoralNodeReleaseViolationException(this, coralNode);
    }
  }

  @override
  Iterable<CoralNode> _iterateInbound() => const [];

  @override
  @pragma('vm:prefer-inline')
  void _performClearance() {
    assert(_state.isRunning, 'Mooring point must be in running state to perform clearance.');
  }

  @pragma('vm:prefer-inline')
  bool add(CoralNode coralNode) {
    try {
      if (_joint == null) return false;

      if (!identical(_joint, coralNode._joint)) {
        assert(false, 'A coralNode can only be moored if it shares the same parent joint...');
        return false;
      }

      if (_CorallineScheduler.instance._scheduleMooring(coralNode)) {
        coralNode._attach(this);
        return true;
      }

      return false;
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
      return false;
    }
  }

  @pragma('vm:prefer-inline')
  bool remove(CoralNode? coralNode) {
    return _CorallineScheduler.instance._removeMooring(coralNode);
  }
}

base mixin _JointMooringMixin on _JointNode {
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    _mooringPoint._activateOptimistically();
    super._activate();
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _pause() {
    super._pause();
    _mooringPoint._pauseOptimistically();
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _resume() {
    _mooringPoint._resumeOptimistically();
    super._resume();
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _deactivate() {
    super._deactivate();
    _mooringPoint._deactivateOptimistically();
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {
    super._didRerouteClearancePoint(oldClearance: oldClearance, newClearance: newClearance);
    _mooringPoint._rerouteClearancePoint();
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _propagateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    _mooringPoint._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
    super._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
  }

  _MooringPoint get _mooringPoint;
}

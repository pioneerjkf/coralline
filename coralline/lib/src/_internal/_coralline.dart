// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base mixin _Coralline<C extends CoralNode> on _Joint {
  @override
  Iterable<CoralNode> _iterateInbound() => [_inbound];

  /// Setup Phase Ordering (Coalescing Buffer):
  ///
  /// Upstream nodes MUST be processed BEFORE calling `super`.
  /// By deferring `super._activate()` to the end, this joint remains in a non-running
  /// state (`isRunning == false`), acting as a perfect coalescing buffer (`_isDirtyPending = true`)
  /// that safely absorbs any synchronous notification flood from the upstream nodes.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    _inbound._activateOptimistically();
    super._activate();
  }

  /// Teardown Phase Ordering (Symmetrical Safety):
  ///
  /// `super` MUST be called BEFORE processing upstream nodes.
  /// This symmetrical teardown ensures that this joint is fully turned off before
  /// dismantling dependencies, safely ignoring any events emitted during upstream teardown.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _pause() {
    super._pause();
    _inbound._pauseOptimistically();
  }

  /// Setup Phase Ordering (Coalescing Buffer):
  ///
  /// Like [_activate], `super._resume()` is deferred to safely absorb any
  /// synchronous dirty notifications triggered by the resuming upstream node.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _resume() {
    _inbound._resumeOptimistically();
    super._resume();
  }

  /// Teardown Phase Ordering (Symmetrical Safety):
  ///
  /// `super` MUST be called BEFORE processing upstream nodes.
  /// This symmetrical teardown ensures that this joint is fully turned off before
  /// dismantling dependencies, safely ignoring any events emitted during upstream teardown.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _deactivate() {
    super._deactivate();
    _inbound._deactivateOptimistically();
  }

  C get _inbound;
}

abstract base class _CorallineNode<C extends CoralNode> extends _JointNode with _Coralline<C> {
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {
    _inbound._rerouteClearancePoint();
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _propagateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    _inbound._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
    super._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
  }
}

abstract base class _SealedCoralline<C extends CoralNode> extends _CorallineNode<C> {
  _SealedCoralline(C inbound) {
    C? resolved;
    try {
      resolved = inbound;
      resolved
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
    } catch (error, stackTrace) {
      if (resolved != null && identical(resolved._joint, this)) {
        resolved
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }

      final damaged = _catchDamaged(error, stackTrace);
      damaged
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
      resolved = damaged;
    }

    _inbound = resolved;
  }

  @override
  late C _inbound;

  C _catchDamaged(Object error, StackTrace? stackTrace);
}

// ignore: unused_element
abstract base class _DetachableCoralline<C extends CoralNode> extends _CorallineNode<C> with _DirtyPoint {
  _DetachableCoralline(C inbound) {
    C? resolved;
    try {
      resolved = inbound;
      resolved
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
    } catch (error, stackTrace) {
      if (resolved != null && identical(resolved._joint, this)) {
        resolved
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }

      final damaged = _catchDamaged(error, stackTrace);
      damaged
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
      resolved = damaged;
    }

    _inbound = resolved;
  }

  @override
  late C _inbound;

  C _catchEmpty();

  C _catchDamaged(Object error, StackTrace? stackTrace);

  @mustCallSuper
  @override
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (!identical(coralNode, _inbound)) {
      throw CoralNodeReleaseViolationException(this, coralNode);
    }

    _inbound = _catchEmpty();
    _inbound
      .._attach(this)
      .._syncLifecycleBasedOnCorallineOptimistically();

    _pushDirty();
  }
}

abstract base class _SwappableCoralline<C extends CoralNode> extends _CorallineNode<C> with _DirtyPoint {
  _SwappableCoralline(C inbound) {
    C? resolved;
    try {
      resolved = inbound;
      resolved
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
    } catch (error, stackTrace) {
      if (resolved != null && identical(resolved._joint, this)) {
        resolved
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }

      final damaged = _catchDamaged(error, stackTrace);
      damaged
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
      resolved = damaged;
    }

    _inbound = resolved;
  }

  _SwappableCoralline.late() {
    C? resolved;
    try {
      resolved = _catchEmpty();
      resolved
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
    } catch (error, stackTrace) {
      if (resolved != null && identical(resolved._joint, this)) {
        resolved
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }

      final damaged = _catchDamaged(error, stackTrace);
      damaged
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
      resolved = damaged;
    }

    _inbound = resolved;
  }

  @override
  late C _inbound;

  C _catchEmpty();

  C _catchDamaged(Object error, StackTrace? stackTrace);

  @mustCallSuper
  C? _performSwap(C newInbound) {
    final oldInbound = _inbound;

    if (identical(oldInbound, newInbound)) return null;

    try {
      newInbound._attach(this);
    } catch (error, stackTrace) {
      _setError(error, stackTrace);
      return oldInbound;
    }

    _inbound = newInbound;

    _discardOptimistically(oldInbound);

    _inbound._syncLifecycleBasedOnCorallineOptimistically();

    _pushDirty();
    return oldInbound;
  }

  @mustCallSuper
  C? _performSwapGuarded(C Function() callback) {
    try {
      return _performSwap(callback());
    } catch (error, stackTrace) {
      return _setError(error, stackTrace);
    }
  }

  @mustCallSuper
  C _performRelease() {
    final oldInbound = _discardOptimistically(_inbound);
    _inbound = _catchEmpty();
    _inbound
      .._attach(this)
      .._syncLifecycleBasedOnCorallineOptimistically();
    _pushDirty();
    return oldInbound;
  }

  @mustCallSuper
  bool _tryPerformRelease(CoralNode coralNode) {
    if (!identical(coralNode, _inbound)) return false;

    _performRelease();
    return true;
  }

  @mustCallSuper
  C _setError(Object error, [StackTrace? stackTrace]) {
    final oldInbound = _discardOptimistically(_inbound);
    _inbound = _catchDamaged(error, stackTrace);
    _inbound
      .._attach(this)
      .._syncLifecycleBasedOnCorallineOptimistically();
    _pushDirty();
    return oldInbound;
  }

  C _discardOptimistically(C inbound);
}

base mixin _SealedColdswapCorallineMixin<C extends CoralNode> on _SwappableCoralline<C> {
  @mustCallSuper
  @override
  C _discardOptimistically(C inbound) {
    return inbound
      .._deactivateOptimistically()
      .._detachOptimistically(this);
  }
}

base mixin _SealedHotswapCorallineMixin<C extends CoralNode> on _SwappableCoralline<C>, _JointMooringMixin {
  @override
  late final _mooringPoint = _MooringPoint().._attach(this);

  @mustCallSuper
  @override
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (identical(_discardingInbound, coralNode)) return;
    super._releaseCoralNodeOrThrow(coralNode);
  }

  /// **Core Concept (Ownership Validation Bypass):**
  /// A transient state flag used to safely bypass graph ownership validation.
  ///
  /// **Design Philosophy (Legitimate Transfers):**
  /// By default, [_releaseCoralNodeOrThrow] throws an exception when a node attempts
  /// to link to a new parent, which prevents unauthorized ownership transfers (stealing).
  /// However, when a node is discarded in a hotswap scenario, it is not completely
  /// destroyed. Instead, it is safely moved to the [_mooringPoint], which involves a
  /// legitimate ownership transfer.
  ///
  /// **Operational Mechanism:**
  /// To prevent an exception from being thrown during this transfer, the node that is
  /// currently being explicitly discarded is temporarily stored in this variable,
  /// permitting the release. This flag is immediately reset to `null` once the
  /// discard process is complete.
  C? _discardingInbound;

  @mustCallSuper
  @override
  C _discardOptimistically(C inbound) {
    assert(
        null == _discardingInbound,
        'Re-entrancy detected in _discardOptimistically. '
        'The suffix "Optimistically" implies a pure, atomic, and synchronous topology mutation '
        'without any side-effects. This assertion being triggered means that this core '
        'philosophy has been shattered by an unintended re-entrant mutation. '
        'Since nodes are sent directly to the mooring point, this serves as a strict '
        'structural safeguard against broken refactoring.');
    _discardingInbound = inbound;

    try {
      if (inbound is _InstantCoral) {
        return inbound
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }

      _mooringPoint.add(inbound);
      return inbound;
    } finally {
      _discardingInbound = null;
    }
  }
}

base mixin _DetachableColdswapCorallineMixin<C extends CoralNode> on _SwappableCoralline<C> {
  @mustCallSuper
  @override
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (!identical(coralNode, _inbound)) {
      throw CoralNodeReleaseViolationException(this, coralNode);
    }

    _inbound = _catchEmpty();
    _inbound
      .._attach(this)
      .._syncLifecycleBasedOnCorallineOptimistically();

    _pushDirty();
  }

  @mustCallSuper
  @override
  C _discardOptimistically(C inbound) {
    return inbound
      .._deactivateOptimistically()
      .._detachOptimistically(this);
  }
}

base mixin _DetachableHotswapCorallineMixin<C extends CoralNode> on _SwappableCoralline<C>, _JointMooringMixin {
  @override
  late final _mooringPoint = _MooringPoint().._attach(this);

  @mustCallSuper
  @override
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (identical(_discardingInbound, coralNode)) return;

    if (!identical(_inbound, coralNode)) {
      throw CoralNodeReleaseViolationException(this, coralNode);
    }

    _inbound = _catchEmpty();
    _inbound
      .._attach(this)
      .._syncLifecycleBasedOnCorallineOptimistically();

    _CorallineScheduler.instance._scheduleDirtyPush(this);
  }

  /// A transient state flag used to safely bypass graph ownership validation.
  ///
  /// By default, [_releaseCoralNodeOrThrow] throws an exception when a node attempts
  /// to link to a new parent, which prevents unauthorized ownership transfers (stealing).
  /// However, when a node is discarded in a hotswap scenario, it is not completely
  /// destroyed. Instead, it is safely moved to the [_mooringPoint], which involves a
  /// legitimate ownership transfer.
  ///
  /// To prevent an exception from being thrown during this transfer, the node that is
  /// currently being explicitly discarded is temporarily stored in this variable,
  /// permitting the release. This flag is immediately reset to `null` once the
  /// discard process is complete.
  C? _discardingInbound;

  @mustCallSuper
  @override
  C _discardOptimistically(C inbound) {
    assert(
        null == _discardingInbound,
        'Re-entrancy detected in _discardOptimistically. '
        'The suffix "Optimistically" implies a pure, atomic, and synchronous topology mutation '
        'without any side-effects. This assertion being triggered means that this core '
        'philosophy has been shattered by an unintended re-entrant mutation. '
        'Since nodes are sent directly to the mooring point, this serves as a strict '
        'structural safeguard against broken refactoring.');
    _discardingInbound = inbound;

    try {
      if (inbound is _InstantCoral) {
        return inbound
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }

      _mooringPoint.add(inbound);
      return inbound;
    } finally {
      _discardingInbound = null;
    }
  }
}

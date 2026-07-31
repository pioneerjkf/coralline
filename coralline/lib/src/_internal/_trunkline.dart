// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base mixin _Trunkline<C extends CoralNode> on _Joint {
  @override
  Iterable<CoralNode> _iterateInbound() => _inbound;

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
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._activateOptimistically();
    }
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
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._pauseOptimistically();
    }
  }

  /// Setup Phase Ordering (Coalescing Buffer):
  ///
  /// Like [_activate], `super._resume()` is deferred to safely absorb any
  /// synchronous dirty notifications triggered by the resuming upstream node.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _resume() {
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._resumeOptimistically();
    }
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
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._deactivateOptimistically();
    }
  }

  List<C> get _inbound;
}

abstract base class _TrunklineNode<C extends CoralNode> extends _JointNode with _Trunkline<C> {
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._rerouteClearancePoint();
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _propagateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
    }
    super._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
  }
}

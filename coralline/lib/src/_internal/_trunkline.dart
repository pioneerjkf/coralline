// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base mixin _Trunkline<C extends CoralNode> on _Joint {
  @override
  Iterable<CoralNode> _iterateInbound() => _inbound;

  /// Activates all inbound lines in [_inbound] before activating this joint.
  ///
  /// See [_Coralline._activate] for setup phase ordering and coalescing details.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._activateOptimistically();
    }
    super._activate();
  }

  /// Pauses this joint before pausing all inbound lines in [_inbound].
  ///
  /// See [_Coralline._pause] for teardown phase ordering details.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _pause() {
    super._pause();
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._pauseOptimistically();
    }
  }

  /// Resumes all inbound lines in [_inbound] before resuming this joint.
  ///
  /// See [_Coralline._resume] for setup phase ordering details.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _resume() {
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._resumeOptimistically();
    }
    super._resume();
  }

  /// Deactivates this joint before deactivating all inbound lines in [_inbound].
  ///
  /// See [_Coralline._deactivate] for teardown phase ordering details.
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

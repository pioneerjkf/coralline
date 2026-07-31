// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

abstract base class _StrictSimplexNode extends _CorallineNode<CoralNode> {
  _StrictSimplexNode(CoralNode node) {
    CoralNode? resolved;
    try {
      resolved = node;
      resolved
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
    } catch (error) {
      if (resolved != null && identical(resolved._joint, this)) {
        resolved
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }
      rethrow;
    }
    _inbound = resolved;
  }

  @override
  late final CoralNode _inbound;
}

abstract base class _StrictComplexNode extends _TrunklineNode {
  _StrictComplexNode(Iterable<CoralNode> inbound) {
    List<CoralNode>? frozenInbound;
    try {
      frozenInbound = List<CoralNode>.unmodifiable(inbound);
      _inbound = frozenInbound;
      for (int i = 0; i < _inbound.length; i++) {
        _inbound[i]._attach(this);
      }
    } catch (error) {
      frozenInbound?.where((e) => identical(e._joint, this)).forEach((e) => e
        .._deactivateOptimistically()
        .._detachOptimistically(this));

      rethrow;
    }
    for (int i = 0; i < _inbound.length; i++) {
      _inbound[i]._syncLifecycleBasedOnCorallineOptimistically();
    }
  }

  @override
  late final List<CoralNode> _inbound;
}

base mixin _ComputationCoralMixin<T> on _ClearancePoint, _DirtyPoint implements Coral<T> {
  CoralComputation<T> get _computation;

  CoralSnapshot<T>? _snapshot;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _performClearance() {
    _snapshot = null;
    _pushDirty();
  }

  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _computeGuarded() {
    try {
      return CoralSnapshot(_computation.compute());
    } catch (error, stackTrace) {
      return CoralSnapshot.damaged(error, stackTrace);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> get snapshot => _snapshot ??= _computeGuarded();
}

base class _SimplexComputationCoral<T> extends _StrictSimplexNode
    with _ClearancePoint, _DirtyPoint, _ComputationCoralMixin<T>, CoralSnapshotDelegator<T> {
  _SimplexComputationCoral(this._computation) : super(_computation.manifest());

  static Coral<T> create<T>(SimplexComputation<T> computation) {
    try {
      final isLifecycleAware = computation is CorallineLifecycleAware;
      final isIntentAware = computation is CorallineTerminalIntentAware;

      if (!isLifecycleAware && !isIntentAware) {
        return _SimplexComputationCoral<T>(computation);
      } else if (isIntentAware) {
        return !isLifecycleAware
            ? _TerminalIntentAwareSimplexComputationCoral<T>(computation)
            : _LifecycleAndTerminalIntentAwareSimplexComputationCoral<T>(computation);
      } else {
        return _LifecycleAwareSimplexComputationCoral<T>(computation);
      }
    } catch (error, stackTrace) {
      return Coral.damaged(error, stackTrace);
    }
  }

  @override
  final SimplexComputation<T> _computation;
}

base mixin _LifecycleAwareSimplexComputationCoralMixin<T> on _SimplexComputationCoral<T> {
  CorallineLifecycleAware get _lifecycleAwareComputation => _computation as CorallineLifecycleAware;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    super._activate();
    try {
      _lifecycleAwareComputation.didActivate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _pause() {
    super._pause();
    try {
      _lifecycleAwareComputation.didPause();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _resume() {
    super._resume();
    try {
      _lifecycleAwareComputation.didResume();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _deactivate() {
    super._deactivate();
    try {
      _lifecycleAwareComputation.didDeactivate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}

base mixin _TerminalIntentAwareSimplexComputationCoralMixin<T> on _SimplexComputationCoral<T> {
  CorallineTerminalIntentAware get _intentAwareComputation => _computation as CorallineTerminalIntentAware;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _attach(_Joint joint) {
    super._attach(joint);
    assert(() {
      for (final forward in _debugIterateDownstream()) {
        if (forward is _IntentFirewall) {
          throw CorallineTopologyError(
              'Topology Error: CorallineTerminalIntentAware computation is placed upstream of a CoralBroadcaster. '
              'Broadcasters act as an Intent Firewall and drop all downstream intents to prevent 1:N collisions. '
              'Consequently, this upstream computation will never receive intent updates. '
              'If this computation must react to UI intents, it MUST be placed on a downstream branch (after the broadcaster).');
        }
      }
      return true;
    }());
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _propagateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    super._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
    _didUpdateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
  }

  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _didUpdateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    try {
      _intentAwareComputation.didUpdateIntent(oldIntent: oldIntent, newIntent: newIntent);
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}

base class _LifecycleAwareSimplexComputationCoral<T> extends _SimplexComputationCoral<T>
    with _LifecycleAwareSimplexComputationCoralMixin<T> {
  _LifecycleAwareSimplexComputationCoral(super.computation);
}

base class _TerminalIntentAwareSimplexComputationCoral<T> extends _SimplexComputationCoral<T>
    with _TerminalIntentAwareSimplexComputationCoralMixin<T> {
  _TerminalIntentAwareSimplexComputationCoral(super.computation);
}

base class _LifecycleAndTerminalIntentAwareSimplexComputationCoral<T> extends _SimplexComputationCoral<T>
    with _LifecycleAwareSimplexComputationCoralMixin<T>, _TerminalIntentAwareSimplexComputationCoralMixin<T> {
  _LifecycleAndTerminalIntentAwareSimplexComputationCoral(super.computation);
}

base class _ComplexComputationCoral<T> extends _StrictComplexNode
    with _ClearancePoint, _DirtyPoint, _ComputationCoralMixin<T>, CoralSnapshotDelegator<T> {
  _ComplexComputationCoral(this._computation) : super(_computation.manifest());

  static Coral<T> create<T>(ComplexComputation<T> computation) {
    try {
      final isLifecycleAware = computation is CorallineLifecycleAware;
      final isIntentAware = computation is CorallineTerminalIntentAware;

      if (!isLifecycleAware && !isIntentAware) {
        return _ComplexComputationCoral<T>(computation);
      } else if (isIntentAware) {
        return !isLifecycleAware
            ? _TerminalIntentAwareComplexComputationCoral<T>(computation)
            : _LifecycleAndTerminalIntentAwareComplexComputationCoral<T>(computation);
      } else {
        return _LifecycleAwareComplexComputationCoral<T>(computation);
      }
    } catch (error, stackTrace) {
      return Coral.damaged(error, stackTrace);
    }
  }

  @override
  final ComplexComputation<T> _computation;
}

base mixin _LifecycleAwareComplexComputationCoralMixin<T> on _ComplexComputationCoral<T> {
  CorallineLifecycleAware get _lifecycleAwareComputation => _computation as CorallineLifecycleAware;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    super._activate();
    try {
      _lifecycleAwareComputation.didActivate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _pause() {
    super._pause();
    try {
      _lifecycleAwareComputation.didPause();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _resume() {
    super._resume();
    try {
      _lifecycleAwareComputation.didResume();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _deactivate() {
    super._deactivate();
    try {
      _lifecycleAwareComputation.didDeactivate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}

base mixin _TerminalIntentAwareComplexComputationCoralMixin<T> on _ComplexComputationCoral<T> {
  CorallineTerminalIntentAware get _intentAwareComputation => _computation as CorallineTerminalIntentAware;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _attach(_Joint joint) {
    super._attach(joint);
    assert(() {
      for (final forward in _debugIterateDownstream()) {
        if (forward is _IntentFirewall) {
          throw CorallineTopologyError(
              'Topology Error: CorallineTerminalIntentAware computation is placed upstream of a CoralBroadcaster. '
              'Broadcasters act as an Intent Firewall and drop all downstream intents to prevent 1:N collisions. '
              'Consequently, this upstream computation will never receive intent updates. '
              'If this computation must react to UI intents, it MUST be placed on a downstream branch (after the broadcaster).');
        }
      }
      return true;
    }());
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _propagateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    super._propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
    _didUpdateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
  }

  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _didUpdateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    try {
      _intentAwareComputation.didUpdateIntent(oldIntent: oldIntent, newIntent: newIntent);
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}

base class _LifecycleAwareComplexComputationCoral<T> extends _ComplexComputationCoral<T>
    with _LifecycleAwareComplexComputationCoralMixin<T> {
  _LifecycleAwareComplexComputationCoral(super.computation);
}

base class _TerminalIntentAwareComplexComputationCoral<T> extends _ComplexComputationCoral<T>
    with _TerminalIntentAwareComplexComputationCoralMixin<T> {
  _TerminalIntentAwareComplexComputationCoral(super.computation);
}

base class _LifecycleAndTerminalIntentAwareComplexComputationCoral<T> extends _ComplexComputationCoral<T>
    with _LifecycleAwareComplexComputationCoralMixin<T>, _TerminalIntentAwareComplexComputationCoralMixin<T> {
  _LifecycleAndTerminalIntentAwareComplexComputationCoral(super.computation);
}

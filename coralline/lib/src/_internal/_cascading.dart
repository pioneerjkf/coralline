// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

abstract base class _CascadingCoralline<S extends CoralNode, T extends CoralNode> extends _SwappableCoralline<T> {
  _CascadingCoralline() : super.late();

  CorallineTerminal<S> get _sourceTerminal;

  void _onSourceDirty();

  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    _sourceTerminal.activate();
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _sourceTerminal.deactivate();
    super._deactivate();
  }

  @mustCallSuper
  void _performCascadeGuarded();
}

/// ### Why [_SuppressibleDirtyPoint]?
///
/// In lazy cascading, when the source changes, we do NOT compute immediately.
/// Instead, we call [_performRelease] inside [_onSourceDirty], which drops the
/// current inner node and pushes a single `Dirty` signal down the graph to notify
/// downstream nodes.
///
/// Later, when a downstream terminal actually pulls the data, it triggers a
/// deferred cascade ([_performCascadeGuarded]). This process swaps the
/// internal node, an action that natively triggers another `_pushDirty()`.
///
/// If we do not suppress this second dirty signal, the framework will emit a
/// duplicate dirty push *while the graph is already in the middle of a Pull phase
/// (computing)*. This would cause a computation flood or infinite recursive loops.
/// Therefore, we temporarily suppress the duplicate signal during the deferred swap.
base mixin _LazyCascadingCorallineMixin<S extends CoralNode, T extends CoralNode>
    on _CascadingCoralline<S, T>, _SuppressibleDirtyPoint {
  @override
  void _onSourceDirty() {
    _needsCascade = true;
    _performRelease();
  }

  bool _needsCascade = true;

  T _pull() {
    if (_needsCascade) {
      // Update the flag before the cascade to prevent an infinite loop (Stack Overflow).
      // If a cyclic read occurs during `_performCascadeGuarded()`
      // (e.g., the user mistakenly reads this snapshot again inside the `cascade` callback),
      // it will safely return the pre-cascade state instead of recursing endlessly.
      _needsCascade = false;

      try {
        _suppressedDirtyPushCount++;
        _performCascadeGuarded();
      } finally {
        _suppressedDirtyPushCount--;
      }
    }
    return _inbound;
  }
}

base mixin _EagerCascadingCorallineMixin<S extends CoralNode, T extends CoralNode> on _CascadingCoralline<S, T> {
  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    _performCascadeGuarded();
  }

  @override
  void _onSourceDirty() {
    _performCascadeGuarded();
  }
}

abstract base class _CascadingCoral<S, T> extends _CascadingCoralline<Coral<S>, Coral<T>>
    with CoralSnapshotDelegator<T>
    implements Coral<T> {
  _CascadingCoral(Coral<S> source, {required Coral<T> Function(S data) cascade}) : _cascade = cascade {
    _sourceTerminal = CoralTerminal<S>(source, onDirty: _onSourceDirty);
  }

  @override
  late final CoralTerminal<S> _sourceTerminal;

  @override
  Coral<T> _catchEmpty() => Coral.empty();

  @override
  Coral<T> _catchDamaged(Object error, StackTrace? stackTrace) => Coral.damaged(error, stackTrace);

  final Coral<T> Function(S data) _cascade;

  @mustCallSuper
  @override
  void _performCascadeGuarded() {
    try {
      final newSource = _sourceTerminal._inbound.snapshot;
      if (newSource.isValid) {
        _performSwap(_cascade.call(newSource.data));
      } else if (newSource.isEmpty) {
        _performSwap(_catchEmpty());
      } else if (newSource.isDamaged) {
        _performSwap(_catchDamaged(newSource.error, newSource.stackTrace));
      }
    } catch (error, stackTrace) {
      _setError(error, stackTrace);
    }
  }
}

base class _SealedColdswapLazyCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _SealedColdswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _SealedColdswapLazyCascadingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _SealedColdswapEagerCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with _SealedColdswapCorallineMixin<Coral<T>>, _EagerCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _SealedColdswapEagerCascadingCoral(
    super.source, {
    required super.cascade,
  });

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

base class _SealedHotswapLazyCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _JointMooringMixin,
        _SealedHotswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _SealedHotswapLazyCascadingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _SealedHotswapEagerCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with _JointMooringMixin, _SealedHotswapCorallineMixin<Coral<T>>, _EagerCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _SealedHotswapEagerCascadingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

base class _DetachableColdswapLazyCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _DetachableColdswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _DetachableColdswapLazyCascadingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _DetachableColdswapEagerCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with _DetachableColdswapCorallineMixin<Coral<T>>, _EagerCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _DetachableColdswapEagerCascadingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

base class _DetachableHotswapLazyCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _JointMooringMixin,
        _DetachableHotswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _DetachableHotswapLazyCascadingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _DetachableHotswapEagerCascadingCoral<S, T> extends _CascadingCoral<S, T>
    with
        _JointMooringMixin,
        _DetachableHotswapCorallineMixin<Coral<T>>,
        _EagerCascadingCorallineMixin<Coral<S>, Coral<T>> {
  _DetachableHotswapEagerCascadingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

abstract base class _ConvergingCoral<S, T> extends _CascadingCoralline<Trunk<S>, Coral<T>>
    with CoralSnapshotDelegator<T>
    implements Coral<T> {
  _ConvergingCoral(Trunk<S> source, {required Coral<T> Function(Iterable<Coral<S>> lines) cascade})
      : _cascade = cascade {
    _sourceTerminal = TrunkTerminal<S>(source, onDirty: _onSourceDirty);
  }

  @override
  late final TrunkTerminal<S> _sourceTerminal;

  @override
  Coral<T> _catchEmpty() => Coral.empty();

  @override
  Coral<T> _catchDamaged(Object error, StackTrace? stackTrace) => Coral.damaged(error, stackTrace);

  final Coral<T> Function(Iterable<Coral<S>> lines) _cascade;

  @mustCallSuper
  @override
  void _performCascadeGuarded() {
    try {
      final newSource = _sourceTerminal._inbound.snapshot;
      if (newSource.isEmpty) {
        _performRelease();
      } else if (newSource.isDamaged) {
        _setError(newSource.error, newSource.stackTrace);
      } else {
        _performSwap(_cascade.call(newSource.lines));
      }
    } catch (error, stackTrace) {
      _setError(error, stackTrace);
    }
  }
}

base class _SealedColdswapLazyConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _SealedColdswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _SealedColdswapLazyConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _SealedColdswapEagerConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with _SealedColdswapCorallineMixin<Coral<T>>, _EagerCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _SealedColdswapEagerConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

base class _SealedHotswapLazyConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _JointMooringMixin,
        _SealedHotswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _SealedHotswapLazyConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _SealedHotswapEagerConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with _JointMooringMixin, _SealedHotswapCorallineMixin<Coral<T>>, _EagerCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _SealedHotswapEagerConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

base class _DetachableColdswapLazyConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _DetachableColdswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _DetachableColdswapLazyConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _DetachableColdswapEagerConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with _DetachableColdswapCorallineMixin<Coral<T>>, _EagerCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _DetachableColdswapEagerConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

base class _DetachableHotswapLazyConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with
        _SuppressibleDirtyPoint,
        _JointMooringMixin,
        _DetachableHotswapCorallineMixin<Coral<T>>,
        _LazyCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _DetachableHotswapLazyConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _pull().snapshot;
}

base class _DetachableHotswapEagerConvergingCoral<S, T> extends _ConvergingCoral<S, T>
    with
        _JointMooringMixin,
        _DetachableHotswapCorallineMixin<Coral<T>>,
        _EagerCascadingCorallineMixin<Trunk<S>, Coral<T>> {
  _DetachableHotswapEagerConvergingCoral(super.source, {required super.cascade});

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

abstract base class _CascadingTrunk<S, T> extends _UpdatableTrunk<T> {
  _CascadingTrunk({required Coral<S> source}) : super.late() {
    _sourceTerminal = CoralTerminal<S>(
      source,
      onDirty: _onSourceDirty,
    );
  }

  late final CoralTerminal<S> _sourceTerminal;

  void _onSourceDirty();

  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    _sourceTerminal.activate();
  }

  @mustCallSuper
  @override
  void _deactivate() {
    _sourceTerminal.deactivate();
    super._deactivate();
  }

  @mustCallSuper
  void _performCascadeGuarded();
}

/// See [_LazyCascadingCorallineMixin] for the explanation of why [_SuppressibleDirtyPoint] is required.
base mixin _LazyCascadingTrunkMixin<S, T> on _CascadingTrunk<S, T>, _SuppressibleDirtyPoint {
  @override
  void _onSourceDirty() {
    _performRelease();
  }

  @override
  void _performCascadeGuarded() {
    try {
      _suppressedDirtyPushCount++;
      super._performCascadeGuarded();
    } finally {
      _suppressedDirtyPushCount--;
    }
  }

  TrunkSnapshot<T> _performCascadeIfNeeded() {
    if (_snapshot.isEmpty) _performCascadeGuarded();
    return _snapshot;
  }

  @override
  TrunkSnapshot<T> get snapshot => _performCascadeIfNeeded();
}

base mixin _EagerCascadingTrunkMixin<S, T> on _CascadingTrunk<S, T> {
  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    _performCascadeGuarded();
  }

  @override
  void _onSourceDirty() {
    _performCascadeGuarded();
  }

  @override
  TrunkSnapshot<T> get snapshot => _snapshot;
}

abstract base class _DivergingTrunk<S, T> extends _CascadingTrunk<S, T> {
  _DivergingTrunk(Coral<S> source, {required Iterable<Coral<T>> Function(S data) cascade})
      : _cascade = cascade,
        super(source: source);

  final Iterable<Coral<T>> Function(S data) _cascade;

  @mustCallSuper
  @override
  void _performCascadeGuarded() {
    try {
      final newSource = _sourceTerminal._inbound.snapshot;
      if (newSource.isEmpty) {
        _performRelease();
      } else if (newSource.isDamaged) {
        _setError(newSource.error, newSource.stackTrace);
      } else {
        _performUpdate(_cascade.call(newSource.data));
      }
    } catch (error, stackTrace) {
      _setError(error, stackTrace);
    }
  }
}

base class _SealedColdswapLazyDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _SuppressibleDirtyPoint, _SealedColdswapTrunkMixin<T>, _LazyCascadingTrunkMixin<S, T> {
  _SealedColdswapLazyDivergingTrunk(super.source, {required super.cascade});
}

base class _SealedColdswapEagerDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _SealedColdswapTrunkMixin<T>, _EagerCascadingTrunkMixin<S, T> {
  _SealedColdswapEagerDivergingTrunk(super.source, {required super.cascade});
}

base class _SealedHotswapLazyDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _SuppressibleDirtyPoint, _JointMooringMixin, _SealedHotswapTrunkMixin<T>, _LazyCascadingTrunkMixin<S, T> {
  _SealedHotswapLazyDivergingTrunk(super.source, {required super.cascade});
}

base class _SealedHotswapEagerDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _JointMooringMixin, _SealedHotswapTrunkMixin<T>, _EagerCascadingTrunkMixin<S, T> {
  _SealedHotswapEagerDivergingTrunk(super.source, {required super.cascade});
}

base class _DetachableColdswapLazyDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _SuppressibleDirtyPoint, _DetachableColdswapTrunkMixin<T>, _LazyCascadingTrunkMixin<S, T> {
  _DetachableColdswapLazyDivergingTrunk(super.source, {required super.cascade});
}

base class _DetachableColdswapEagerDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _DetachableColdswapTrunkMixin<T>, _EagerCascadingTrunkMixin<S, T> {
  _DetachableColdswapEagerDivergingTrunk(super.source, {required super.cascade});
}

base class _DetachableHotswapLazyDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _SuppressibleDirtyPoint, _JointMooringMixin, _DetachableHotswapTrunkMixin<T>, _LazyCascadingTrunkMixin<S, T> {
  _DetachableHotswapLazyDivergingTrunk(super.source, {required super.cascade});
}

base class _DetachableHotswapEagerDivergingTrunk<S, T> extends _DivergingTrunk<S, T>
    with _JointMooringMixin, _DetachableHotswapTrunkMixin<T>, _EagerCascadingTrunkMixin<S, T> {
  _DetachableHotswapEagerDivergingTrunk(super.source, {required super.cascade});
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base class _TrunkSnapshot<T> implements TrunkSnapshot<T> {
  _TrunkSnapshot(Iterable<Coral<T>> lines) : lines = List.unmodifiable(lines);
  @override
  @pragma('vm:prefer-inline')
  final bool isEmpty = false;

  @override
  @pragma('vm:prefer-inline')
  final bool isDamaged = false;

  @override
  @pragma('vm:prefer-inline')
  final bool isValid = true;

  @override
  @pragma('vm:prefer-inline')
  final List<Coral<T>> lines;

  @override
  @pragma('vm:prefer-inline')
  List<Coral<T>>? get linesOrNull => lines;

  @override
  @pragma('vm:prefer-inline')
  List<Coral<T>> get linesOrEmpty => lines;

  @override
  @pragma('vm:prefer-inline')
  Object get error => throw CoralSnapshotStateException('Valid', 'TrunkSnapshot<Coral<$T>> has no error.');

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace =>
      throw CoralSnapshotStateException('Valid', 'TrunkSnapshot<Coral<$T>> has no stackTrace.');
}

base class _DamagedTrunkSnapshot<T> implements TrunkSnapshot<T> {
  const _DamagedTrunkSnapshot(this.error, [StackTrace? stackTrace]) : stackTrace = stackTrace ?? StackTrace.empty;

  @override
  @pragma('vm:prefer-inline')
  final bool isEmpty = false;

  @override
  @pragma('vm:prefer-inline')
  final bool isDamaged = true;

  @override
  @pragma('vm:prefer-inline')
  final bool isValid = false;

  @override
  @pragma('vm:prefer-inline')
  List<Coral<T>> get lines => throw CoralSnapshotExtractionException(
        'Damaged',
        'There is no lines<Coral<$T>>.',
        error: error,
        stackTrace: stackTrace,
      );

  @override
  @pragma('vm:prefer-inline')
  List<Coral<T>>? get linesOrNull => null;

  @override
  @pragma('vm:prefer-inline')
  List<Coral<T>> get linesOrEmpty => const [];

  @override
  @pragma('vm:prefer-inline')
  final Object error;

  @override
  @pragma('vm:prefer-inline')
  final StackTrace stackTrace;
}

base class _EmptyTrunkSnapshot<T> implements TrunkSnapshot<T> {
  const _EmptyTrunkSnapshot();

  @override
  @pragma('vm:prefer-inline')
  final bool isEmpty = true;

  @override
  @pragma('vm:prefer-inline')
  final bool isDamaged = false;

  @override
  @pragma('vm:prefer-inline')
  final bool isValid = false;

  @override
  @pragma('vm:prefer-inline')
  List<Coral<T>> get lines => throw CoralSnapshotExtractionException('Empty', 'There is no lines<Coral<$T>>.');

  @override
  @pragma('vm:prefer-inline')
  final List<Coral<T>>? linesOrNull = null;

  @override
  @pragma('vm:prefer-inline')
  List<Coral<T>> get linesOrEmpty => const [];

  @override
  @pragma('vm:prefer-inline')
  Object get error => throw CoralSnapshotStateException('Empty', 'TrunkSnapshot<Coral<$T>> has no error.');

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace =>
      throw CoralSnapshotStateException('Empty', 'TrunkSnapshot<Coral<$T>> has no stackTrace.');
}

base class _InstantTrunk<T> extends CoralNode with TrunkSnapshotDelegator<T> implements Trunk<T> {
  _InstantTrunk.damaged(Object error, [StackTrace? stackTrace]) : snapshot = TrunkSnapshot.damaged(error, stackTrace);

  _InstantTrunk.empty() : snapshot = TrunkSnapshot(const []);

  @override
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {}

  @override
  final TrunkSnapshot<T> snapshot;
}

base class _SealedTrunk<T> extends _TrunklineNode<Coral<T>> with TrunkSnapshotDelegator<T> implements Trunk<T> {
  _SealedTrunk(Iterable<Coral<T>> lines) {
    late final List<Coral<T>> frozenLines;
    try {
      frozenLines = List.unmodifiable(lines);
    } catch (error, stackTrace) {
      snapshot = TrunkSnapshot.damaged(error, stackTrace);
      return;
    }

    try {
      final Iterable<Coral<T>> attachingLines = frozenLines.map((e) {
        if (identical(this, e._joint)) return e;
        try {
          return e.._attach(this);
        } catch (error, stackTrace) {
          return Coral.damaged(error, stackTrace).._attach(this);
        }
      });

      snapshot = TrunkSnapshot(attachingLines);
    } catch (error, stackTrace) {
      frozenLines.where((e) => identical(e._joint, this)).forEach((e) => e
        .._deactivateOptimistically()
        .._detachOptimistically(this));

      snapshot = TrunkSnapshot.damaged(error, stackTrace);
    }

    final resolvedLines = snapshot.linesOrEmpty;

    for (int i = 0; i < resolvedLines.length; i++) {
      resolvedLines[i]._syncLifecycleBasedOnCorallineOptimistically();
    }
  }

  @override
  late final List<Coral<T>> _inbound = snapshot.linesOrEmpty;

  @override
  late final TrunkSnapshot<T> snapshot;
}

abstract base class _DynamicTrunk<T> extends _TrunklineNode<Coral<T>>
    with _DirtyPoint, TrunkSnapshotDelegator<T>
    implements Trunk<T> {
  _DynamicTrunk(Iterable<Coral<T>> lines) {
    late final List<Coral<T>> newLines;
    try {
      newLines = List.unmodifiable(lines);
    } catch (error, stackTrace) {
      _snapshot = TrunkSnapshot.damaged(error, stackTrace);
      return;
    }

    _attachAndSnapshotOptimistically(newLines);
  }

  _DynamicTrunk.late();

  @override
  List<Coral<T>> get _inbound => _snapshot.linesOrEmpty;

  @override
  TrunkSnapshot<T> get snapshot => _snapshot;

  TrunkSnapshot<T> _snapshot = TrunkSnapshot.empty();

  // ignore: unused_element
  Coral<T> _discardOptimistically(Coral<T> inbound);

  /// Attaches the given [frozenLines] to this joint and creates a new [TrunkSnapshot].
  ///
  /// **WARNING**:
  /// The [frozenLines] MUST be an unmodifiable list (e.g., `List.unmodifiable(...)`).
  /// This method does not internally check for modifiability to avoid performance overhead,
  /// but mutating the list during iteration can lead to severe [ConcurrentModificationError]
  /// and unpredictable side effects.
  void _attachAndSnapshotOptimistically(List<Coral<T>> frozenLines) {
    try {
      final Iterable<Coral<T>> attachingLines = frozenLines.map((e) {
        if (identical(this, e._joint)) return e;
        try {
          return e.._attach(this);
        } catch (error, stackTrace) {
          return Coral.damaged(error, stackTrace).._attach(this);
        }
      });

      _snapshot = TrunkSnapshot(attachingLines);
    } catch (error, stackTrace) {
      frozenLines.where((e) => identical(e._joint, this)).forEach((e) => e
        .._deactivateOptimistically()
        .._detachOptimistically(this));

      _snapshot = TrunkSnapshot.damaged(error, stackTrace);
    }

    // / 🚨 Architecture Note: Separation of Concerns 🚨
    // /
    // / DO NOT move this loop inside the `try-catch` block above.
    // /
    // / 1. **Final State Execution**: The `try-catch` strictly handles Topology Mutation.
    // /    This loop must execute based on the finalized `_snapshot` state,
    // /    whether the attachment succeeded or was rolled back to `damaged`.
    // / 2. **Guaranteed Safety**: `_switchLifecycle...Optimistically()` is inherently
    // /    safe and guaranteed not to throw an unhandled exception.
    // / 3. **Preventing False Rollbacks**: If this was inside the `try` block,
    // /    a theoretical failure in lifecycle synchronization would incorrectly
    // /    trigger a full topology rollback, breaking the framework's intent.
    final resolvedLines = snapshot.linesOrEmpty;

    for (int i = 0; i < resolvedLines.length; i++) {
      resolvedLines[i]._syncLifecycleBasedOnCorallineOptimistically();
    }
  }
}

abstract base class _UpdatableTrunk<T> extends _DynamicTrunk<T> {
  _UpdatableTrunk(super.lines);

  _UpdatableTrunk.late() : super.late();

  @mustCallSuper
  void _performUpdate(Iterable<Coral<T>> newLines) {
    final oldLines = _snapshot.linesOrNull;

    late final List<Coral<T>> frozenLines;
    try {
      frozenLines = List.unmodifiable(newLines);
    } catch (error, stackTrace) {
      _setError(error, stackTrace);
      return;
    }

    if (oldLines?._isSequentiallyIdentical(frozenLines) ?? false) return;

    if (frozenLines.isEmpty) {
      if (oldLines?.isNotEmpty ?? false) {
        oldLines?.forEach((e) {
          if (identical(e._joint, this)) {
            _discardOptimistically(e);
          }
        });
      }

      /// DO NOT replace this block with [_performRelease].
      /// 1. [_performRelease] assigns [TrunkSnapshot.empty],
      ///    which throws an [Exception] when [TrunkSnapshot.lines] is accessed.
      ///    Here, we assign [TrunkSnapshot] with `const []` to legitimately
      ///    represent a valid state with 0 elements.
      /// 2. The manual iteration above safely verifies
      ///    `identical(e._joint, this)` before detaching.
      /// 3. We use `const []` instead of `[]` for memory optimization.
      ///    It reuses a single immutable empty lines instance across the app,
      ///    avoiding unnecessary memory allocation.
      _snapshot = TrunkSnapshot(const []);
    } else {
      if (oldLines?.isNotEmpty ?? false) {
        oldLines?.where((e) => !frozenLines._containsIdentical(e)).forEach((e) {
          if (identical(e._joint, this)) {
            _discardOptimistically(e);
          }
        });
      }

      _attachAndSnapshotOptimistically(frozenLines);
    }

    _pushDirty();
  }

  @mustCallSuper
  // ignore: unused_element
  void _performUpdateGuarded(Iterable<Coral<T>> Function() callback) {
    try {
      _performUpdate(callback());
    } catch (error, stackTrace) {
      _setError(error, stackTrace);
    }
  }

  @mustCallSuper
  void _performRelease() {
    if (_snapshot.isEmpty) return;
    _snapshot.linesOrNull?.forEach((e) {
      if (identical(e._joint, this)) _discardOptimistically(e);
    });
    _snapshot = TrunkSnapshot.empty();
    _pushDirty();
  }

  @mustCallSuper
  void _setError(Object error, [StackTrace? stackTrace]) {
    _snapshot.linesOrNull?.forEach((e) {
      if (identical(e._joint, this)) _discardOptimistically(e);
    });
    _snapshot = TrunkSnapshot.damaged(error, stackTrace);
    _pushDirty();
  }
}

base mixin _SealedColdswapTrunkMixin<T> on _DynamicTrunk<T> {
  @mustCallSuper
  @override
  Coral<T> _discardOptimistically(Coral<T> inbound) {
    return inbound
      .._deactivateOptimistically()
      .._detachOptimistically(this);
  }
}

base mixin _SealedHotswapTrunkMixin<T> on _DynamicTrunk<T>, _JointMooringMixin {
  @override
  late final _mooringPoint = _MooringPoint().._attach(this);

  Coral<T>? _discardingInbound;

  @mustCallSuper
  @override
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (identical(_discardingInbound, coralNode)) return;
    super._releaseCoralNodeOrThrow(coralNode);
  }

  @mustCallSuper
  @override
  Coral<T> _discardOptimistically(Coral<T> inbound) {
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

base mixin _DetachableColdswapTrunkMixin<T> on _DynamicTrunk<T> {
  @mustCallSuper
  @override
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (!_inbound._containsIdentical(coralNode)) {
      throw CoralNodeReleaseViolationException(this, coralNode);
    }

    final newLines = List.of(_inbound)..removeWhere((e) => identical(e, coralNode));
    _snapshot = TrunkSnapshot(newLines);
    _pushDirty();
  }

  @mustCallSuper
  @override
  Coral<T> _discardOptimistically(Coral<T> inbound) {
    return inbound
      .._deactivateOptimistically()
      .._detachOptimistically(this);
  }
}

base mixin _DetachableHotswapTrunkMixin<T> on _DynamicTrunk<T>, _JointMooringMixin {
  @override
  late final _mooringPoint = _MooringPoint().._attach(this);

  Coral<T>? _discardingInbound;

  @mustCallSuper
  @override
  void _releaseCoralNodeOrThrow(CoralNode coralNode) {
    if (identical(_discardingInbound, coralNode)) return;

    if (!_inbound._containsIdentical(coralNode)) {
      throw CoralNodeReleaseViolationException(this, coralNode);
    }

    final newLines = List.of(_inbound)..removeWhere((e) => identical(e, coralNode));
    _snapshot = TrunkSnapshot(newLines);
    _pushDirty();
  }

  @mustCallSuper
  @override
  Coral<T> _discardOptimistically(Coral<T> inbound) {
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

base class _DetachableColdswapTrunk<T> extends _DynamicTrunk<T> with _DetachableColdswapTrunkMixin<T> {
  _DetachableColdswapTrunk(super.lines);
}

base class _DetachableHotswapTrunk<T> extends _DynamicTrunk<T>
    with _JointMooringMixin, _DetachableHotswapTrunkMixin<T> {
  _DetachableHotswapTrunk(super.lines);
}

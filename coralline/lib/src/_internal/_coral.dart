// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base class _CoralSnapshot<T> implements CoralSnapshot<T> {
  const _CoralSnapshot(this.data);

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
  final T data;

  @override
  @pragma('vm:prefer-inline')
  T? get dataOrNull => data;

  @override
  @pragma('vm:prefer-inline')
  T dataOrElse(T Function() fallback) => data;

  @override
  @pragma('vm:prefer-inline')
  Object get error => throw CoralSnapshotStateException('Valid', 'No error was found in this valid CoralSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace =>
      throw CoralSnapshotStateException('Valid', 'No stackTrace was found in this valid CoralSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  bool isEquivalent(CoralSnapshot other, [bool Function(T previous, T next)? equals]) {
    if (identical(this, other)) return true;

    return other is _CoralSnapshot<T> && (null != equals ? equals(data, other.data) : other.data == data);
  }
}

base class _DamagedCoralSnapshot<T> implements CoralSnapshot<T> {
  const _DamagedCoralSnapshot(this.error, [StackTrace? stackTrace]) : stackTrace = stackTrace ?? StackTrace.empty;

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
  T get data => throw CoralSnapshotExtractionException(
        'Damaged',
        'This CoralSnapshot<$T> contains an error instead of data.',
        error: error,
        stackTrace: stackTrace,
      );

  @override
  @pragma('vm:prefer-inline')
  T? get dataOrNull => null;

  @override
  @pragma('vm:prefer-inline')
  T dataOrElse(T Function() fallback) => fallback.call();

  @override
  @pragma('vm:prefer-inline')
  final Object error;

  @override
  @pragma('vm:prefer-inline')
  final StackTrace stackTrace;

  @override
  @pragma('vm:prefer-inline')
  bool isEquivalent(CoralSnapshot other, [bool Function(T previous, T next)? equals]) {
    if (identical(this, other)) return true;

    return other is _DamagedCoralSnapshot<T> && other.error == error && other.stackTrace == stackTrace;
  }
}

base class _EmptyCoralSnapshot<T> implements CoralSnapshot<T> {
  const _EmptyCoralSnapshot();

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
  T get data => throw CoralSnapshotExtractionException('Empty', 'No data available in this empty CoralSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  final T? dataOrNull = null;

  @override
  @pragma('vm:prefer-inline')
  T dataOrElse(T Function() fallback) => fallback.call();

  @override
  @pragma('vm:prefer-inline')
  Object get error => throw CoralSnapshotStateException('Empty', 'No error was found in this empty CoralSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  StackTrace get stackTrace =>
      throw CoralSnapshotStateException('Empty', 'No stackTrace was found in this empty CoralSnapshot<$T>.');

  @override
  @pragma('vm:prefer-inline')
  bool isEquivalent(CoralSnapshot other, [bool Function(T previous, T next)? equals]) {
    if (identical(this, other)) return true;

    return other is _EmptyCoralSnapshot<T>;
  }
}

base class _InstantCoralProvider<T> implements CoralProvider<T> {
  _InstantCoralProvider.data(T data) : coral = Coral.data(data);

  _InstantCoralProvider.coral(this.coral);

  @override
  bool get isActivated => coral.isActivated;

  @override
  bool get isRunning => coral.isRunning;

  @override
  bool get isPaused => coral.isPaused;

  @override
  bool get isDeactivated => coral.isDeactivated;

  @override
  final Coral<T> coral;
}

base class _InstantCoral<T> extends CoralNode with CoralSnapshotDelegator<T> implements Coral<T> {
  _InstantCoral(T data) : snapshot = CoralSnapshot<T>(data);

  _InstantCoral.damaged(Object error, [StackTrace? stackTrace]) : snapshot = CoralSnapshot.damaged(error, stackTrace);

  _InstantCoral.empty() : snapshot = CoralSnapshot.empty();

  @override
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {}

  @override
  final CoralSnapshot<T> snapshot;
}

base class _ResourceCoral<T> extends CoralNode with CoralSnapshotDelegator<T> implements Coral<T> {
  _ResourceCoral({required T Function() create, required void Function(T resource) dispose})
      : _createResource = create,
        _disposeResource = dispose;

  final T Function() _createResource;

  final void Function(T resource) _disposeResource;

  @override
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {}

  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    final oldSnapshot = _snapshot;
    _snapshot = null;
    if (oldSnapshot != null && oldSnapshot.isValid) {
      try {
        _disposeResource.call(oldSnapshot.data);
      } catch (error, stackTrace) {
        _handleUncaughtError(error, stackTrace);
      }
    }
    try {
      _snapshot = CoralSnapshot(_createResource.call());
    } catch (error, stackTrace) {
      _snapshot = CoralSnapshot.damaged(error, stackTrace);
    }
  }

  @mustCallSuper
  @override
  void _deactivate() {
    super._deactivate();
    final oldSnapshot = _snapshot;
    _snapshot = null;
    if (oldSnapshot != null && oldSnapshot.isValid) {
      try {
        _disposeResource.call(oldSnapshot.data);
      } catch (error, stackTrace) {
        _handleUncaughtError(error, stackTrace);
      }
    }
  }

  @override
  CoralSnapshot<T> get snapshot => _snapshot ??= CoralSnapshot.empty();
  CoralSnapshot<T>? _snapshot;
}

final class _LifecycleObservableCoral<T> extends _SealedCoralProxy<T>
    with CoralSnapshotDelegator<T>
    implements Coral<T> {
  _LifecycleObservableCoral(
    super.inbound, {
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  })  : _onActivated = onActivated,
        _onPaused = onPaused,
        _onResumed = onResumed,
        _onDeactivated = onDeactivated;

  final void Function()? _onActivated;

  final void Function()? _onPaused;

  final void Function()? _onResumed;

  final void Function()? _onDeactivated;

  @mustCallSuper
  @override
  void _activate() {
    super._activate();
    _onActivated?.call();
  }

  @mustCallSuper
  @override
  void _pause() {
    super._pause();
    _onPaused?.call();
  }

  @mustCallSuper
  @override
  void _resume() {
    super._resume();
    _onResumed?.call();
  }

  @mustCallSuper
  @override
  void _deactivate() {
    super._deactivate();
    _onDeactivated?.call();
  }

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;
}

final class _DistinctCoral<T> extends _SealedCoralProxy<T>
    with _ClearancePoint, _DirtyPoint, CoralSnapshotDelegator<T>
    implements Coral<T> {
  _DistinctCoral(
    super.inbound, {
    bool Function(T previous, T next)? equals,
  }) : _equals = equals;

  final bool Function(T previous, T next)? _equals;

  @override
  @pragma('vm:prefer-inline')
  void _performClearance() {
    try {
      final CoralSnapshot<T> newSnapshot = _inbound.snapshot;
      // If _snapshot is null, this is the first computation, so proceed unconditionally (?? false)
      if (_snapshot?.isEquivalent(newSnapshot, _equals) ?? false) return;
      _snapshot = newSnapshot;
      _pushDirty();
    } catch (error, stackTrace) {
      _snapshot = CoralSnapshot.damaged(error, stackTrace);
      _pushDirty();
    }
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> get snapshot => _snapshot ??= _inbound.snapshot;
  CoralSnapshot<T>? _snapshot;
}

abstract base class _ReadlessRelayComputeCoralProxy<S, T> extends _SealedCoralProxy<S>
    with _ClearancePoint, _DirtyPoint, CoralSnapshotDelegator<T>
    implements Coral<T> {
  _ReadlessRelayComputeCoralProxy(super.inbound);

  /// Computes and returns the new snapshot.
  CoralSnapshot<T> _compute();

  CoralSnapshot<T>? _snapshot;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> get snapshot => _snapshot ??= _compute();

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _performClearance() {
    _snapshot = null;
    _pushDirty();
  }
}

base class _FallbackCoral<T> extends _ReadlessRelayComputeCoralProxy<T, T> {
  _FallbackCoral(
    super.inbound, {
    T Function()? onEmpty,
    T Function(Object error, [StackTrace? stackTrace])? onDamage,
  })  : _onEmpty = onEmpty,
        _onDamage = onDamage,
        assert(null != onEmpty || null != onDamage, 'Provide at least onEmpty or onDamage');

  final T Function()? _onEmpty;
  final T Function(Object error, [StackTrace? stackTrace])? _onDamage;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _compute() {
    try {
      final source = _inbound.snapshot;
      final onEmpty = _onEmpty;
      final onDamage = _onDamage;
      if (source.isEmpty && onEmpty != null) {
        return CoralSnapshot(onEmpty());
      } else if (source.isDamaged && onDamage != null) {
        return CoralSnapshot(onDamage(source.error, source.stackTrace));
      } else {
        return source;
      }
    } catch (error, stackTrace) {
      return CoralSnapshot.damaged(error, stackTrace);
    }
  }
}

base class _FallbackEmptyToNullCoral<T> extends _ReadlessRelayComputeCoralProxy<T?, T> {
  _FallbackEmptyToNullCoral(super.inbound);

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _compute() {
    try {
      final source = _inbound.snapshot;
      return source.isEmpty ? CoralSnapshot(null as T) : source as CoralSnapshot<T>;
    } catch (error, stackTrace) {
      return CoralSnapshot.damaged(error, stackTrace);
    }
  }
}

base class _GuardedCoral<T> extends _SealedCoralProxy<T>
    with _ClearancePoint, _DirtyPoint, CoralSnapshotDelegator<T>
    implements Coral<T> {
  _GuardedCoral(
    super.inbound, {
    required bool Function() canProceed,
    Object? Function()? getReason,
  })  : _canProceed = canProceed,
        _getReason = getReason;

  final bool Function() _canProceed;

  final Object? Function()? _getReason;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _performClearance() {
    _snapshot = null;
    _pushDirty();
  }

  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _compute() {
    try {
      if (_canProceed.call()) return _inbound.snapshot;

      final reason = _getReason?.call();
      return null != reason ? CoralSnapshot.damaged(reason) : CoralSnapshot.empty();
    } catch (error, stackTrace) {
      return CoralSnapshot<T>.damaged(error, stackTrace);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> get snapshot => _snapshot ??= _compute();
  CoralSnapshot<T>? _snapshot;
}

final class _MapCoral<S, T> extends _ReadlessRelayComputeCoralProxy<S, T> {
  _MapCoral(
    super.inbound, {
    required T Function(S source) convert,
  }) : _convert = convert;

  final T Function(S source) _convert;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _compute() {
    try {
      final source = _inbound.snapshot;
      if (source.isEmpty) {
        return CoralSnapshot.empty();
      } else if (source.isDamaged) {
        return CoralSnapshot.damaged(source.error, source.stackTrace);
      } else {
        return CoralSnapshot(_convert.call(source.data));
      }
    } catch (error, stackTrace) {
      return CoralSnapshot.damaged(error, stackTrace);
    }
  }
}

base class _TrunkAggregator<S, T> extends _SealedTrunkProxy<S>
    with _ClearancePoint, _DirtyPoint, CoralSnapshotDelegator<T>
    implements Coral<T> {
  _TrunkAggregator(super.inbound, {required T Function(Iterable<Coral<S>> lines) aggregator})
      : _aggregator = aggregator;

  final T Function(Iterable<Coral<S>> data) _aggregator;

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _performClearance() {
    _snapshot = null;
    _pushDirty();
  }

  @mustCallSuper
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _compute() {
    try {
      final newSource = _inbound.snapshot;
      if (newSource.isEmpty) {
        return CoralSnapshot.empty();
      } else if (newSource.isDamaged) {
        return CoralSnapshot.damaged(newSource.error, newSource.stackTrace);
      } else {
        return CoralSnapshot(_aggregator.call(newSource.lines));
      }
    } catch (error, stackTrace) {
      return CoralSnapshot.damaged(error, stackTrace);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> get snapshot => _snapshot ??= _compute();
  CoralSnapshot<T>? _snapshot;
}

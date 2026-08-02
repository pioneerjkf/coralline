// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base class _EntryCoral<T> extends CoralNode with _DirtyPoint, CoralSnapshotDelegator<T> implements Coral<T> {
  _EntryCoral(T data) : _snapshot = CoralSnapshot<T>(data);

  _EntryCoral.late();

  @override
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {}

  CoralSnapshot<T> _snapshot = CoralSnapshot.empty();

  bool _isPullPending = false;

  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _performForwarding(final CoralSnapshot<T> snapshot) {
    _snapshot = snapshot;
    if (_isPullPending) return;
    _isPullPending = true;
    _pushDirty();
  }

  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> get snapshot {
    _isPullPending = false;
    return _snapshot;
  }
}

base class _DistinctEntryCoral<T> extends _EntryCoral<T> {
  _DistinctEntryCoral(super.data, {bool Function(T previous, T next)? equals}) : _equals = equals;

  _DistinctEntryCoral.late({bool Function(T previous, T next)? equals})
      : _equals = equals,
        super.late();

  final bool Function(T previous, T next)? _equals;

  @mustCallSuper
  @override
  void _performForwarding(final CoralSnapshot<T> snapshot) {
    if (_snapshot.isEquivalent(snapshot, _equals)) return;
    super._performForwarding(snapshot);
  }
}

base class _LifecycleObservableEntryCoral<T> extends _EntryCoral<T> {
  _LifecycleObservableEntryCoral(
    super.data, {
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  })  : _onActivated = onActivated,
        _onPaused = onPaused,
        _onResumed = onResumed,
        _onDeactivated = onDeactivated;

  _LifecycleObservableEntryCoral.late({
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  })  : _onActivated = onActivated,
        _onPaused = onPaused,
        _onResumed = onResumed,
        _onDeactivated = onDeactivated,
        super.late();

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
}

base class _LifecycleObservableDistinctEntryCoral<T> extends _DistinctEntryCoral<T> {
  _LifecycleObservableDistinctEntryCoral(
    super.data, {
    super.equals,
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  })  : _onActivated = onActivated,
        _onPaused = onPaused,
        _onResumed = onResumed,
        _onDeactivated = onDeactivated;

  _LifecycleObservableDistinctEntryCoral.late({
    super.equals,
    void Function()? onActivated,
    void Function()? onPaused,
    void Function()? onResumed,
    void Function()? onDeactivated,
  })  : _onActivated = onActivated,
        _onPaused = onPaused,
        _onResumed = onResumed,
        _onDeactivated = onDeactivated,
        super.late();

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
}

base class _SealedColdswapControlledTrunk<T> extends _UpdatableTrunk<T> with _SealedColdswapTrunkMixin<T> {
  _SealedColdswapControlledTrunk(super.lines);

  _SealedColdswapControlledTrunk.late() : super.late();
}

base class _SealedHotswapControlledTrunk<T> extends _UpdatableTrunk<T>
    with _JointMooringMixin, _SealedHotswapTrunkMixin<T> {
  _SealedHotswapControlledTrunk(super.lines);

  _SealedHotswapControlledTrunk.late() : super.late();
}

base class _DetachableColdswapControlledTrunk<T> extends _UpdatableTrunk<T> with _DetachableColdswapTrunkMixin<T> {
  _DetachableColdswapControlledTrunk(super.lines);

  _DetachableColdswapControlledTrunk.late() : super.late();
}

base class _DetachableHotswapControlledTrunk<T> extends _UpdatableTrunk<T>
    with _JointMooringMixin, _DetachableHotswapTrunkMixin<T> {
  _DetachableHotswapControlledTrunk(super.lines);

  _DetachableHotswapControlledTrunk.late() : super.late();
}

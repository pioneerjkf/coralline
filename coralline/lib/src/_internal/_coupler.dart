// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base class _SealedCoralProxy<T> extends _SealedCoralline<Coral<T>> {
  _SealedCoralProxy(super.inbound);

  @override
  Coral<T> _catchDamaged(Object error, StackTrace? stackTrace) => Coral.damaged(error, stackTrace);
}

base class _CoralCouplerBase<T> with CoralSnapshotDelegator<T> implements CoralCoupler<T> {
  _CoralCouplerBase(Coral<T> inbound, {bool seal = true, bool hotswap = false})
      : _proxy = switch ((seal, hotswap)) {
          (true, true) => _SealedHotswapCoralProxy(inbound),
          (true, false) => _SealedColdswapCoralProxy(inbound),
          (false, true) => _DetachableHotswapCoralProxy(inbound),
          (false, false) => _DetachableColdswapCoralProxy(inbound),
        };

  _CoralCouplerBase.late({bool seal = true, bool hotswap = false})
      : _proxy = switch ((seal, hotswap)) {
          (true, true) => _SealedHotswapCoralProxy.late(),
          (true, false) => _SealedColdswapCoralProxy.late(),
          (false, true) => _DetachableHotswapCoralProxy.late(),
          (false, false) => _DetachableColdswapCoralProxy.late(),
        };

  final _CoralProxy<T> _proxy;

  @override
  bool get isActivated => _proxy._state.isActivated;

  @override
  bool get isRunning => _proxy._state.isRunning;

  @override
  bool get isPaused => _proxy._state.isPaused;

  @override
  bool get isDeactivated => _proxy._state.isDeactivated;

  @override
  CoralSnapshot<T> get snapshot => _proxy.snapshot;

  @override
  Coral<T> get coral => _proxy;

  @mustCallSuper
  @override
  Coral<T>? couple(Coral<T> newInbound) => _proxy._performSwap(newInbound);

  @mustCallSuper
  @override
  Coral<T>? coupleGuarded(Coral<T> Function() callback) => _proxy._performSwapGuarded(callback);

  @mustCallSuper
  @override
  void decouple() => _proxy._performRelease();

  @mustCallSuper
  @override
  bool tryDecoupling(CoralNode coralNode) => _proxy._tryPerformRelease(coralNode);

  @mustCallSuper
  @override
  Coral<T> setError(Object error, [StackTrace? stackTrace]) => _proxy._setError(error, stackTrace);
}

abstract base class _CoralProxy<T> extends _SwappableCoralline<Coral<T>>
    with CoralSnapshotDelegator<T>
    implements Coral<T> {
  _CoralProxy(super.inbound);

  _CoralProxy.late() : super.late();

  @override
  CoralSnapshot<T> get snapshot => _inbound.snapshot;

  @override
  Coral<T> _catchEmpty() => Coral.empty();

  @override
  Coral<T> _catchDamaged(Object error, StackTrace? stackTrace) => Coral.damaged(error, stackTrace);
}

base class _SealedColdswapCoralProxy<T> extends _CoralProxy<T> with _SealedColdswapCorallineMixin<Coral<T>> {
  _SealedColdswapCoralProxy(super.inbound);

  _SealedColdswapCoralProxy.late() : super.late();
}

base class _SealedHotswapCoralProxy<T> extends _CoralProxy<T>
    with _JointMooringMixin, _SealedHotswapCorallineMixin<Coral<T>> {
  _SealedHotswapCoralProxy(super.inbound);

  _SealedHotswapCoralProxy.late() : super.late();
}

base class _DetachableColdswapCoralProxy<T> extends _CoralProxy<T>
    with _DetachableColdswapCorallineMixin<Coral<T>>
    implements Coral<T> {
  _DetachableColdswapCoralProxy(super.inbound);

  _DetachableColdswapCoralProxy.late() : super.late();
}

base class _DetachableHotswapCoralProxy<T> extends _CoralProxy<T>
    with _JointMooringMixin, _DetachableHotswapCorallineMixin<Coral<T>>
    implements Coral<T> {
  _DetachableHotswapCoralProxy(super.inbound);

  _DetachableHotswapCoralProxy.late() : super.late();
}

base class _SealedTrunkProxy<T> extends _SealedCoralline<Trunk<T>> {
  _SealedTrunkProxy(super.inbound);

  @override
  Trunk<T> _catchDamaged(Object error, StackTrace? stackTrace) => Trunk.damaged(error, stackTrace);
}

base class _TrunkCouplerBase<T> with TrunkSnapshotDelegator<T> implements TrunkCoupler<T> {
  _TrunkCouplerBase(Trunk<T> inbound, {bool seal = true, bool hotswap = false})
      : _proxy = switch ((seal, hotswap)) {
          (true, true) => _SealedHotswapTrunkProxy(inbound),
          (true, false) => _SealedColdswapTrunkProxy(inbound),
          (false, true) => _DetachableHotswapTrunkProxy(inbound),
          (false, false) => _DetachableColdswapTrunkProxy(inbound),
        };

  _TrunkCouplerBase.late({bool seal = true, bool hotswap = false})
      : _proxy = switch ((seal, hotswap)) {
          (true, true) => _SealedHotswapTrunkProxy.late(),
          (true, false) => _SealedColdswapTrunkProxy.late(),
          (false, true) => _DetachableHotswapTrunkProxy.late(),
          (false, false) => _DetachableColdswapTrunkProxy.late(),
        };

  final _TrunkProxy<T> _proxy;

  @override
  bool get isActivated => _proxy._state.isActivated;

  @override
  bool get isRunning => _proxy._state.isRunning;

  @override
  bool get isPaused => _proxy._state.isPaused;

  @override
  bool get isDeactivated => _proxy._state.isDeactivated;

  @override
  TrunkSnapshot<T> get snapshot => _proxy.snapshot;

  @override
  Trunk<T> get trunk => _proxy;

  @mustCallSuper
  @override
  Trunk<T>? couple(Trunk<T> newInbound) => _proxy._performSwap(newInbound);

  @mustCallSuper
  @override
  Trunk<T>? coupleGuarded(Trunk<T> Function() callback) => _proxy._performSwapGuarded(callback);

  @mustCallSuper
  @override
  void decouple() => _proxy._performRelease();

  @mustCallSuper
  @override
  bool tryDecoupling(CoralNode coralNode) => _proxy._tryPerformRelease(coralNode);

  @mustCallSuper
  @override
  Trunk<T> setError(Object error, [StackTrace? stackTrace]) => _proxy._setError(error, stackTrace);
}

abstract base class _TrunkProxy<T> extends _SwappableCoralline<Trunk<T>>
    with TrunkSnapshotDelegator<T>
    implements Trunk<T> {
  _TrunkProxy(super.inbound);

  _TrunkProxy.late() : super.late();

  @override
  TrunkSnapshot<T> get snapshot => _inbound.snapshot;

  @override
  Trunk<T> _catchEmpty() => Trunk.empty();

  @override
  Trunk<T> _catchDamaged(Object error, StackTrace? stackTrace) => Trunk.damaged(error, stackTrace);
}

base class _SealedColdswapTrunkProxy<T> extends _TrunkProxy<T> with _SealedColdswapCorallineMixin<Trunk<T>> {
  _SealedColdswapTrunkProxy(super.inbound);

  _SealedColdswapTrunkProxy.late() : super.late();
}

base class _SealedHotswapTrunkProxy<T> extends _TrunkProxy<T>
    with _JointMooringMixin, _SealedHotswapCorallineMixin<Trunk<T>> {
  _SealedHotswapTrunkProxy(super.inbound);

  _SealedHotswapTrunkProxy.late() : super.late();
}

base class _DetachableColdswapTrunkProxy<T> extends _TrunkProxy<T>
    with _DetachableColdswapCorallineMixin<Trunk<T>>
    implements Trunk<T> {
  _DetachableColdswapTrunkProxy(super.inbound);

  _DetachableColdswapTrunkProxy.late() : super.late();
}

base class _DetachableHotswapTrunkProxy<T> extends _TrunkProxy<T>
    with _JointMooringMixin, _DetachableHotswapCorallineMixin<Trunk<T>>
    implements Trunk<T> {
  _DetachableHotswapTrunkProxy(super.inbound);

  _DetachableHotswapTrunkProxy.late() : super.late();
}

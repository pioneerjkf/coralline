// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../animation.dart';

/// An internal state delegate interface for [ResilientAnimationController].
///
/// Abstracting controller operations into a state delegate pattern allows
/// [ResilientAnimationController] to seamlessly swap between a dormant staging
/// delegate ([_DormantAnimationControlDelegate]) and an active engine delegate
/// ([_ActiveAnimationControlDelegate]) depending on the [Coral] resource lifecycle.
abstract interface class _AnimationControlDelegate {
  Animation<double>? get view;

  Duration? get duration;

  set duration(Duration? newValue);

  Duration? get reverseDuration;

  set reverseDuration(Duration? newValue);

  void resync(TickerProvider vsync);

  double get value;

  set value(double newValue);

  void reset();

  double get velocity;

  Duration? get lastElapsedDuration;

  bool get isAnimating;

  AnimationStatus get status;

  TickerFuture forward({double? from});

  TickerFuture reverse({double? from});

  TickerFuture toggle({double? from});

  TickerFuture animateTo(double target, {Duration? duration, Curve curve = Curves.linear});

  TickerFuture animateBack(double target, {Duration? duration, Curve curve = Curves.linear});

  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  });

  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  });

  TickerFuture animateWith(Simulation simulation);

  TickerFuture animateBackWith(Simulation simulation);

  void stop({bool canceled = true});

  void dispose();

  String toStringDetails();
}

/// A dormant state delegate for [ResilientAnimationController].
///
/// Staged parameters (value, duration, reverseDuration) are preserved locally
/// without instantiating an active [AnimationController] ticker engine. Read/write
/// operations notify parent listeners while driving methods throw a descriptive [StateError].
class _DormantAnimationControlDelegate implements _AnimationControlDelegate {
  double _value;
  Duration? _duration;
  Duration? _reverseDuration;
  final double lowerBound;
  final double upperBound;
  final VoidCallback onValueOrDurationChanged;

  _DormantAnimationControlDelegate({
    required double value,
    required Duration? duration,
    required Duration? reverseDuration,
    required this.lowerBound,
    required this.upperBound,
    required this.onValueOrDurationChanged,
  })  : _value = value,
        _duration = duration,
        _reverseDuration = reverseDuration;

  TickerFuture _throwDormantError(String methodName) {
    throw StateError(
      'ResilientAnimationController.$methodName() called while dormant.\n'
      'AnimationController is only available when activated by a topology (e.g., CoralWidget or CoralTerminal).',
    );
  }

  @override
  Animation<double>? get view => null;

  @override
  Duration? get duration => _duration;
  @override
  set duration(Duration? newValue) {
    _duration = newValue;
    onValueOrDurationChanged();
  }

  @override
  Duration? get reverseDuration => _reverseDuration;
  @override
  set reverseDuration(Duration? newValue) {
    _reverseDuration = newValue;
    onValueOrDurationChanged();
  }

  @override
  void resync(TickerProvider vsync) {}

  @override
  double get value => _value;
  @override
  set value(double newValue) {
    _value = newValue;
    onValueOrDurationChanged();
  }

  @override
  void reset() {
    _value = lowerBound;
    onValueOrDurationChanged();
  }

  @override
  double get velocity => 0.0;

  @override
  Duration? get lastElapsedDuration => null;

  @override
  bool get isAnimating => false;

  @override
  AnimationStatus get status {
    if (_value == lowerBound) return AnimationStatus.dismissed;
    if (_value == upperBound) return AnimationStatus.completed;
    return AnimationStatus
        .dismissed; // Intermediate values remain dismissed since the controller is dormant.
  }

  @override
  TickerFuture forward({double? from}) => _throwDormantError('forward');

  @override
  TickerFuture reverse({double? from}) => _throwDormantError('reverse');

  @override
  TickerFuture toggle({double? from}) => _throwDormantError('toggle');

  @override
  TickerFuture animateTo(double target, {Duration? duration, Curve curve = Curves.linear}) =>
      _throwDormantError('animateTo');

  @override
  TickerFuture animateBack(double target, {Duration? duration, Curve curve = Curves.linear}) =>
      _throwDormantError('animateBack');

  @override
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) =>
      _throwDormantError('repeat');

  @override
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) =>
      _throwDormantError('fling');

  @override
  TickerFuture animateWith(Simulation simulation) => _throwDormantError('animateWith');

  @override
  TickerFuture animateBackWith(Simulation simulation) => _throwDormantError('animateBackWith');

  @override
  void stop({bool canceled = true}) {}

  @override
  void dispose() {}

  @override
  String toStringDetails() {
    final String statusName = status.name;
    final String valueString = _value.toStringAsFixed(3);
    return '$statusName $valueString; dormant';
  }
}

/// An active state delegate wrapping a live Flutter [AnimationController].
///
/// Delegates all getter, setter, and ticker driving operations directly to the
/// underlying active [AnimationController] engine.
class _ActiveAnimationControlDelegate implements _AnimationControlDelegate {
  final AnimationController _engine;

  _ActiveAnimationControlDelegate(this._engine);

  @override
  Animation<double>? get view => _engine.view;

  @override
  Duration? get duration => _engine.duration;
  @override
  set duration(Duration? newValue) => _engine.duration = newValue;

  @override
  Duration? get reverseDuration => _engine.reverseDuration;
  @override
  set reverseDuration(Duration? newValue) => _engine.reverseDuration = newValue;

  @override
  void resync(TickerProvider vsync) => _engine.resync(vsync);

  @override
  double get value => _engine.value;
  @override
  set value(double newValue) => _engine.value = newValue;

  @override
  void reset() => _engine.reset();

  @override
  double get velocity => _engine.velocity;

  @override
  Duration? get lastElapsedDuration => _engine.lastElapsedDuration;

  @override
  bool get isAnimating => _engine.isAnimating;

  @override
  AnimationStatus get status => _engine.status;

  @override
  TickerFuture forward({double? from}) => _engine.forward(from: from);

  @override
  TickerFuture reverse({double? from}) => _engine.reverse(from: from);

  @override
  TickerFuture toggle({double? from}) => _engine.toggle(from: from);

  @override
  TickerFuture animateTo(double target, {Duration? duration, Curve curve = Curves.linear}) =>
      _engine.animateTo(target, duration: duration, curve: curve);

  @override
  TickerFuture animateBack(double target, {Duration? duration, Curve curve = Curves.linear}) =>
      _engine.animateBack(target, duration: duration, curve: curve);

  @override
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
    int? count,
  }) =>
      _engine.repeat(min: min, max: max, reverse: reverse, period: period, count: count);

  @override
  TickerFuture fling({
    double velocity = 1.0,
    SpringDescription? springDescription,
    AnimationBehavior? animationBehavior,
  }) =>
      _engine.fling(
          velocity: velocity,
          springDescription: springDescription,
          animationBehavior: animationBehavior);

  @override
  TickerFuture animateWith(Simulation simulation) => _engine.animateWith(simulation);

  @override
  TickerFuture animateBackWith(Simulation simulation) => _engine.animateBackWith(simulation);

  @override
  void stop({bool canceled = true}) => _engine.stop(canceled: canceled);

  @override
  void dispose() {}

  @override
  String toStringDetails() => _engine.toStringDetails();
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

enum _CoralNodeLifecycleState {
  // Active state: The object is able to perform its function.
  // Note: In this example, anything not inactive is considered active.
  // 'running' and 'paused' represent more specific active states.

  // Inactive state: The object cannot perform its function
  inactive,

  // Paused state: Active but temporarily stopped
  paused,

  // Running state: Active and currently performing its function
  running;

  @pragma('vm:prefer-inline')
  bool get isActivated => this != inactive;

  @pragma('vm:prefer-inline')
  bool get isDeactivated => this == inactive;

  @pragma('vm:prefer-inline')
  bool get isPaused => this == paused;

  @pragma('vm:prefer-inline')
  bool get isRunning => this == running;
}

abstract base class _CorallineLifecycle implements _CorallineErrorSink {
  _CoralNodeLifecycleState _state = _CoralNodeLifecycleState.inactive;

  @mustCallSuper
  void _activate() {
    assert(_state.isDeactivated, 'Cannot activate from $_state');
    _state = _CoralNodeLifecycleState.running;
  }

  @mustCallSuper
  void _pause() {
    assert(_state.isRunning, 'Cannot pause from $_state');
    _state = _CoralNodeLifecycleState.paused;
  }

  @mustCallSuper
  void _resume() {
    assert(_state.isPaused, 'Cannot resume from $_state');
    _state = _CoralNodeLifecycleState.running;
  }

  @mustCallSuper
  void _deactivate() {
    assert(_state.isActivated, 'Cannot deactivate from $_state');
    _state = _CoralNodeLifecycleState.inactive;
  }

  @mustCallSuper
  void _activateOptimistically() {
    if (_state.isActivated) return;
    try {
      _activate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  void _pauseOptimistically() {
    if (!_state.isRunning) return;
    try {
      _pause();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  void _resumeOptimistically() {
    if (!_state.isPaused) return;
    try {
      _resume();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }

  @mustCallSuper
  void _deactivateOptimistically() {
    if (_state.isDeactivated) return;
    try {
      _deactivate();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}

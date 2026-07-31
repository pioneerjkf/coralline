// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base class _DeLorean<T> {
  _DeLorean(Future<T> future) : _future = future {
    _controller = CoralController.lateLifecycle(onActivated: _backToTheFuture);
  }

  final Future<T> _future;

  late final CoralController<T> _controller;

  bool _isStarted = false;

  void _backToTheFuture() {
    if (_isStarted) return;
    _isStarted = true;

    try {
      _future.then(
        _controller.set,
        onError: (Object error, StackTrace stackTrace) {
          _controller.setError(error, stackTrace);
        },
      );
    } catch (error, stackTrace) {
      _controller.setError(error, stackTrace);
    }
  }

  Coral<T> get coral => _controller.coral;
}

base class _StreamCoralPipe<T> {
  _StreamCoralPipe(
    Stream<T> stream, {
    this.cancelOnError,
    required bool distinct,
    required bool Function(T previous, T next)? equals,
  }) : _stream = stream {
    _controller = CoralController.lateLifecycle(
      distinct: distinct,
      equals: equals,
      onActivated: _performSubscribe,
      onPaused: _performPause,
      onResumed: _performResume,
      onDeactivated: _performUnsubscribe,
    );
  }

  final Stream<T> _stream;

  final bool? cancelOnError;

  late final CoralController<T> _controller;

  StreamSubscription<T>? _subscription;

  bool _isDone = false;

  void _performSubscribe() {
    if (_isDone) return;

    if (_subscription != null) {
      throw StateError('Already subscribed to Stream(-> $_stream).');
    }

    try {
      _subscription = _stream.listen(
        _controller.set,
        onError: (Object error, StackTrace stackTrace) {
          _controller.setError(error, stackTrace);
          if (cancelOnError == true) _performUnsubscribe();
        },
        onDone: () {
          _isDone = true;
          _performUnsubscribe();
        },
        cancelOnError: cancelOnError,
      );
    } catch (error, stackTrace) {
      _controller.setError(error, stackTrace);
    }
  }

  void _performPause() {
    _subscription?.pause();
  }

  void _performResume() {
    _subscription?.resume();
  }

  void _performUnsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  Coral<T> get coral => _controller.coral;
}

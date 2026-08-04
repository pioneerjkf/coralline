// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

abstract base class _TerminalPoint<C extends CoralNode> extends _CorallineLifecycle
    with _Joint, _Coralline<C>, _ClearancePoint
    implements _CorallineTopology {
  _TerminalPoint(
    C inbound, {
    required void Function() onDirty,
  }) : _onDirty = onDirty {
    C? resolved;
    try {
      resolved = inbound;
      resolved
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
    } catch (error, stackTrace) {
      if (resolved != null && identical(resolved._joint, this)) {
        resolved
          .._deactivateOptimistically()
          .._detachOptimistically(this);
      }

      final damaged = _catchDamaged(error, stackTrace);
      damaged
        .._attach(this)
        .._syncLifecycleBasedOnCorallineOptimistically();
      resolved = damaged;
    }

    _inbound = resolved;
  }

  @override
  late final C _inbound;

  final void Function() _onDirty;

  C _catchDamaged(Object error, StackTrace? stackTrace);

  CorallineTerminalIntent? get intent;

  @override
  CorallineTerminalIntent? _resolveTerminalIntent() => intent;

  @override
  Iterable<_CorallineTopology> _debugIterateDownstream() => const [];

  @override
  void _handleUncaughtError(Object error, StackTrace stackTrace) {
    try {
      final terminalIntent = intent;
      if (terminalIntent != null) {
        try {
          terminalIntent.handleUncaughtError(error, stackTrace);
          return;
        } catch (handlerError, handlerStack) {
          // If the handler fails, log in debug mode without re-throwing assertion cascade.
          assert(() {
            print(
              '\n🚨 [Coralline] terminalIntent.handleUncaughtError failed!\n'
              'Handler Error: $handlerError\n'
              'Handler StackTrace:\n$handlerStack\n',
            );
            return true;
          }());
          // BUG FIX: Report the original pipeline error, not the handler's error.
          Zone.current.handleUncaughtError(error, stackTrace);
          return;
        }
      }

      Zone.current.handleUncaughtError(error, stackTrace);
    } catch (fatalError, fatalStack) {
      // The absolute worst-case scenario: Zone's error handler itself threw an exception.
      // We log it in debug mode without cascading assertions.
      assert(() {
        print(
          '\n🚨 [Coralline] Fatal error inside _handleUncaughtError!\n'
          'Zone Error: $fatalError\n'
          'Zone StackTrace:\n$fatalStack\n',
        );
        return true;
      }());
    }
  }

  @override
  void _performClearance() {
    try {
      _onDirty.call();
    } catch (error, stackTrace) {
      _handleUncaughtError(error, stackTrace);
    }
  }
}

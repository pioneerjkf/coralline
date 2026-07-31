// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

/// An internal marker interface used to identify nodes that block intent propagation
/// (e.g., [CoralBroadcaster]). This is used to enforce topological safety checks.
abstract interface class _IntentFirewall {}

/// An internal terminal node bound to a broadcaster that acts as an intent firewall.
///
/// **Design Philosophy:**
/// Encapsulates the inbound stream for a broadcaster while implementing [_IntentFirewall]
/// to prevent topological intents from propagating across the multiplexing boundary.
///
/// **AI & Developer Note:**
/// Intentionally blocks intent propagation so individual outbound subscriber lines
/// manage their own topological intent boundaries.
final class _BroadcasterTerminal<T> extends CoralTerminal<T> implements _IntentFirewall {
  _BroadcasterTerminal(super.inbound, {required super.onDirty});
}

/// Base implementation for a 1:N fan-out reactive broadcaster node.
///
/// [_CoralBroadcasterBase] multiplexes a single inbound [Coral] stream out to multiple
/// independent [_BroadcasterLine] subscribers.
///
/// **Design Philosophy:**
/// Decouples a single reactive stream into dynamic line sub-nodes while memoizing snapshots
/// (`_lastSnapshot`) to avoid redundant pull computations across multiple subscribers.
///
/// **AI & Developer Note:**
/// - Outbound lines must be created via [coral].
/// - Accessing unattached or dormant line nodes will throw [CoralBroadcasterLineDormantAccessError].
/// - `_rotate` handles Copy-on-Write (`_intoRotate`) mutations to ensure safe iteration during dirty propagation.
base class _CoralBroadcasterBase<T> implements CoralBroadcaster<T> {
  _CoralBroadcasterBase(Coral<T> inbound) {
    _terminal = _BroadcasterTerminal<T>(inbound, onDirty: _rotate);
  }

  late final _BroadcasterTerminal<T> _terminal;

  Set<_BroadcasterLine<T>> _outbounds = <_BroadcasterLine<T>>{};

  bool _intoRotate = false;

  /// Propagates dirty notifications to all active outbound subscriber lines.
  ///
  /// **Ensures:**
  /// * Invalidates [_lastSnapshot].
  /// * Notifies every registered [_BroadcasterLine] in [_outbounds].
  @pragma('vm:prefer-inline')
  void _rotate() {
    try {
      _intoRotate = true;
      _lastSnapshot = null;
      final outbounds = _outbounds;
      for (final e in outbounds) {
        try {
          e._pushDirty();
        } catch (error, stackTrace) {
          e._handleUncaughtError(error, stackTrace);
        }
      }
    } catch (error, stackTrace) {
      Zone.current.handleUncaughtError(error, stackTrace);
    } finally {
      _intoRotate = false;
    }
  }

  CoralSnapshot<T>? _lastSnapshot;

  /// Pulls the latest snapshot from the inbound terminal, caching it for subsequent subscribers.
  ///
  /// **Ensures:**
  /// * Returns the memoized [CoralSnapshot] from the inbound stream.
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _pull() => _lastSnapshot ??= _terminal._inbound.snapshot;

  /// Attaches an outbound subscriber line to this broadcaster.
  ///
  /// * [outbound]: The line node to attach.
  ///
  /// **Requires:**
  /// * [outbound] must belong to this broadcaster instance.
  /// * [outbound] must not already be attached.
  ///
  /// **Ensures:**
  /// * Performs Copy-on-Write on [_outbounds] if mutating during an active `_rotate` pass.
  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _attach(_BroadcasterLine<T> outbound) {
    assert(identical(this, outbound._broadcaster), 'Line must belong to this broadcaster');
    assert(!_outbounds._containsIdentical(outbound), 'Line is already attached');

    if (_intoRotate) {
      _outbounds = <_BroadcasterLine<T>>{..._outbounds};
    }
  }

  /// Detaches an outbound subscriber line from this broadcaster.
  ///
  /// * [outbound]: The line node to detach.
  ///
  /// **Requires:**
  /// * [outbound] must be currently attached.
  ///
  /// **Ensures:**
  /// * Performs Copy-on-Write on [_outbounds] if mutating during an active `_rotate` pass.
  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _detach(_BroadcasterLine<T> outbound) {
    assert(_outbounds._containsIdentical(outbound), 'Line is not attached');

    if (_intoRotate) {
      _outbounds = <_BroadcasterLine<T>>{..._outbounds};
    }
  }

  @override
  bool get isActivated => _terminal.isActivated;

  @override
  bool get isRunning => _terminal.isRunning;

  @override
  bool get isPaused => _terminal.isPaused;

  @override
  bool get isDeactivated => _terminal.isDeactivated;

  @override
  Coral<T> get coral => _BroadcasterLine(this);
}

/// A broadcaster that deactivates its inbound terminal immediately when all subscriber lines detach.
///
/// **Design Philosophy:**
/// Minimizes resource retention by deactivating the upstream terminal stream as soon as
/// the subscriber count drops to zero (`_outbounds.isEmpty`).
///
/// **AI & Developer Note:**
/// Useful when upstream computations or subscriptions should not linger once UI subscribers unmount.
final class _ImmediateDeactivationCoralBroadcaster<T> extends _CoralBroadcasterBase<T> {
  _ImmediateDeactivationCoralBroadcaster(super.inbound);

  @override
  @pragma('vm:prefer-inline')
  void _attach(_BroadcasterLine<T> outbound) {
    super._attach(outbound);
    if (_outbounds.add(outbound)) {
      if (_terminal.isDeactivated) {
        _terminal.activate();
      }
    }
  }

  @override
  @pragma('vm:prefer-inline')
  void _detach(_BroadcasterLine<T> outbound) {
    super._detach(outbound);
    if (_outbounds.remove(outbound)) {
      if (_outbounds.isEmpty && _terminal.isActivated) {
        _terminal.deactivate();
      }
    }
  }
}

/// A broadcaster that defers terminal deactivation using [_CorallineScheduler].
///
/// **Design Philosophy:**
/// Avoids churn and thrashing when subscriber lines rapidly detach and re-attach (such as during
/// widget subtree updates or list recycling) by scheduling lazy deactivation via the global scheduler.
///
/// **AI & Developer Note:**
/// If a new subscriber attaches before the scheduled deactivation task runs, the deactivation is canceled,
/// maintaining an active upstream connection.
final class _LazyDeactivationCoralBroadcaster<T> extends _CoralBroadcasterBase<T> {
  _LazyDeactivationCoralBroadcaster(super.inbound);

  @override
  @pragma('vm:prefer-inline')
  void _attach(_BroadcasterLine<T> outbound) {
    super._attach(outbound);
    if (_outbounds.add(outbound)) {
      if (_terminal.isDeactivated) {
        _terminal.activate();
      }
    }
  }

  @override
  @pragma('vm:prefer-inline')
  void _detach(_BroadcasterLine<T> outbound) {
    super._detach(outbound);
    if (_outbounds.remove(outbound)) {
      if (_outbounds.isEmpty && _terminal.isActivated) {
        _CorallineScheduler.instance._scheduleBroadcasterDeactivate(this);
      }
    }
  }
}

/// Represents a single outbound branch subscriber attached to a 1:N [_CoralBroadcasterBase].
///
/// [_BroadcasterLine] acts as a lightweight proxy node that hooks into its parent broadcaster
/// during activation and detaches upon deactivation.
///
/// **Design Philosophy:**
/// Provides dynamic 1:N fan-out capability without requiring dedicated full terminal nodes for
/// every subscriber branch, optimizing memory allocation and topological node count.
///
/// **AI & Developer Note:**
/// - **Dormant Access Error:** Invoking `snapshot` or `_pull()` on an unattached or dormant line
///   (when `isRunning == false`) will throw [CoralBroadcasterLineDormantAccessError].
/// - Always store or cache the line node returned by `broadcaster.coral` before calling `manifest()`.
///
/// **Example:**
/// ```dart
/// final broadcaster = CoralController<int>(0, broadcast: true);
/// final line = broadcaster.provider.coral; // Returns a _BroadcasterLine instance
/// ```
final class _BroadcasterLine<T> extends CoralNode with _DirtyPoint, CoralSnapshotDelegator<T> implements Coral<T> {
  _BroadcasterLine(_CoralBroadcasterBase<T> broadcaster) : _broadcaster = broadcaster;

  final _CoralBroadcasterBase<T> _broadcaster;

  @override
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance}) {}

  /// Lifecycle Guard & Performance Optimization:
  ///
  /// `super._activate()` MUST be called at the very end of this method.
  ///
  /// 1. Synchronous Flood Prevention: When `_broadcaster._attach(this)` is called,
  ///    the broadcaster might wake up from a dormant state and synchronously emit
  ///    a flood of [_pushDirty] calls back to this node.
  /// 2. Coalescing Buffer: Because `super._activate()` has NOT been called yet,
  ///    this node is not yet running (`isRunning == false`). Consequently,
  ///    [_DirtyPoint._pushDirty] swallows all incoming notifications by simply
  ///    setting `_isDirtyPending = true`. This acts as a perfect debouncing buffer,
  ///    preventing an O(N^2) synchronous cascade down the entire subgraph.
  /// 3. Single Flush: Finally, calling `super._activate()` at the end transitions
  ///    the node to the running state, checks `_isDirtyPending`, and elegantly fires
  ///    a single [_pushDirty] down the graph exactly ONCE.
  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _activate() {
    _broadcaster._attach(this);
    if (!identical(_broadcaster._lastSnapshot, _lastSnapshot)) {
      _pushDirty();
    }
    super._activate();
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _deactivate() {
    super._deactivate();
    _broadcaster._detach(this);
  }

  @mustCallSuper
  @override
  @pragma('vm:prefer-inline')
  void _pushDirty() {
    _lastSnapshot = null;
    super._pushDirty();
  }

  CoralSnapshot<T>? _lastSnapshot;

  /// Pulls the latest snapshot from the parent broadcaster.
  ///
  /// **Throws:**
  /// * Throws [CoralBroadcasterLineDormantAccessError] if `isRunning` is `false`.
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> _pull() {
    if (!isRunning) throw CoralBroadcasterLineDormantAccessError(this);
    return _broadcaster._pull();
  }

  @override
  @pragma('vm:prefer-inline')
  CoralSnapshot<T> get snapshot => _lastSnapshot ??= _pull();
}

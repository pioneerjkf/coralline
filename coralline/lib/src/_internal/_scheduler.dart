// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

/// The abstract base engine for microtask-level batching and debouncing in Coralline.
///
/// Coralline relies on microtask batching to coalesce multiple synchronous state
/// mutations or graph structure updates into a single execution pass.
/// [_CorallineSchedulerBase] ensures that regardless of how many items are
/// registered across various mixins within a single event-loop turn,
/// [scheduleMicrotask] is invoked at most once.
///
/// **Design Philosophy:**
/// Guarantees O(1) scheduling overhead per synchronous frame by debouncing
/// scheduling calls and executing all pending mixin tasks sequentially when
/// the scheduled microtask fires.
///
/// **AI & Developer Note:**
/// Subclasses or mixins overriding [_onTask] MUST invoke `super._onTask()` at
/// the very beginning of their implementation to maintain the proper mixin
/// linearization execution chain and reset [_isScheduled].
abstract base class _CorallineSchedulerBase {
  /// Indicates whether a microtask has already been scheduled for the current
  /// synchronous execution turn.
  bool _isScheduled = false;

  /// Cached tear-off of [_onTask] to eliminate repeated function object
  /// allocations during scheduling.
  late final void Function() _taskHandler = _onTask;

  /// Enqueues the microtask task handler if one is not currently pending.
  ///
  /// **Ensures:**
  /// * [_isScheduled] is set to `true`.
  /// * [scheduleMicrotask] is called exactly once per batch.
  void _ensureScheduled() {
    if (_isScheduled) return;
    _isScheduled = true;
    scheduleMicrotask(_taskHandler);
  }

  /// Resets the scheduling flag to allow subsequent microtask scheduling.
  ///
  /// Must be overridden with `@mustCallSuper` by mixins to attach batch work.
  @mustCallSuper
  void _onTask() {
    _isScheduled = false;
  }
}

/// Handles the batch deactivation and detachment of moored nodes during dynamic
/// graph mutation (Hotswap).
///
/// When nodes are unmoored during graph re-configuration, immediate detachment
/// can lead to inconsistent intermediate states. [_MooringSchedulerMixin] queues
/// unmooring requests and processes them in a single batch snapshot.
///
/// **Design Philosophy:**
/// Batching unmooring operations isolates dynamic graph re-wiring from current
/// computation passes, preventing re-entrancy bugs and race conditions during
/// dynamic node detachment.
///
/// **AI & Developer Note:**
/// Do not clear or mutate [_mooringSet] directly outside [_onTask]. The internal
/// set-swapping mechanism creates an O(1) snapshot to safely allow new items
/// to be registered while processing the current batch.
base mixin _MooringSchedulerMixin on _CorallineSchedulerBase {
  /// Set of [CoralNode] instances awaiting unmooring.
  Set<CoralNode> _mooringSet = <CoralNode>{};

  /// Secondary set used for double-buffering swaps to preserve capacity.
  Set<CoralNode> _mooringSwapSet = <CoralNode>{};

  /// Schedules a [coralNode] for batch unmooring.
  ///
  /// * [coralNode]: The node to be deactivated and detached.
  ///
  /// **Returns:**
  /// `true` if the node was newly added to the unmooring queue; `false` if it
  /// was already present.
  bool _scheduleMooring(CoralNode coralNode) {
    if (!_mooringSet.add(coralNode)) return false;
    _ensureScheduled();
    return true;
  }

  /// Removes a [coralNode] from the unmooring queue if present.
  ///
  /// * [coralNode]: The node to remove from the pending unmooring set.
  ///
  /// **Returns:**
  /// `true` if the node was successfully removed; `false` otherwise.
  bool _removeMooring(CoralNode? coralNode) => _mooringSet.remove(coralNode);

  /// Executes unmooring for all nodes in the current batch snapshot.
  ///
  /// **Requires:**
  /// Each node in the batch must have a valid `_joint` of type `_MooringPoint`.
  ///
  /// **Ensures:**
  /// Nodes in the batch are optimistically deactivated and detached from their
  /// mooring points. Any uncaught errors are forwarded to the current [Zone].
  @mustCallSuper
  @override
  void _onTask() {
    super._onTask();
    if (_mooringSet.isEmpty) return;

    final currentBatch = _mooringSet;
    _mooringSet = _mooringSwapSet;
    _mooringSwapSet = currentBatch;

    for (var e in currentBatch) {
      try {
        final joint = e._joint;
        assert(joint is _MooringPoint, 'CoralNode $e has no mooring point.');
        if (joint is! _MooringPoint) continue;

        e
          .._deactivateOptimistically()
          .._detachOptimistically(joint);
      } catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
    currentBatch.clear();
  }
}

/// Handles coalesced/lazy push of dirty notifications to prevent synchronous
/// update floods.
///
/// When multiple dependencies of a reactive node change in the same turn,
/// pushing dirty notifications immediately can cause exponential notification
/// fan-outs. [_LazyDirtyPushSchedulerMixin] debounces notifications until the
/// microtask flush.
///
/// **Design Philosophy:**
/// Adheres to lazy computation principles. By coalescing dirty state pushes,
/// downstream reactive points are notified exactly once per microtask frame
/// regardless of the number of upstream signal changes.
///
/// **AI & Developer Note:**
/// Always verify `point._isDirtyPending` inside execution loops. If a point is
/// marked non-dirty before the flush occurs, notification is skipped.
base mixin _LazyDirtyPushSchedulerMixin on _CorallineSchedulerBase {
  /// Set of [_DirtyPoint] targets queued for dirty notification push.
  Set<_DirtyPoint> _dirtySet = <_DirtyPoint>{};

  /// Secondary set used for double-buffering swaps to preserve capacity.
  Set<_DirtyPoint> _dirtySwapSet = <_DirtyPoint>{};

  /// Schedules a dirty notification push for the given [point].
  ///
  /// * [point]: The dirty reactive target to register.
  ///
  /// **Returns:**
  /// `true` if the point was newly registered for dirty push; `false` if it
  /// was already pending.
  bool _scheduleDirtyPush(_DirtyPoint point) {
    if (_dirtySet.add(point)) {
      point._isDirtyPending = true;
    } else {
      return false;
    }
    _ensureScheduled();
    return true;
  }

  /// Flushes all queued dirty notifications in the current snapshot batch.
  ///
  /// **Ensures:**
  /// Pushes dirty notifications to all registered points where `_isDirtyPending`
  /// remains `true`. Errors during push are handled via `_handleUncaughtError`.
  @mustCallSuper
  @override
  void _onTask() {
    super._onTask();
    if (_dirtySet.isEmpty) return;

    final currentBatch = _dirtySet;
    _dirtySet = _dirtySwapSet;
    _dirtySwapSet = currentBatch;

    for (var e in currentBatch) {
      try {
        if (!e._isDirtyPending) continue;

        e._pushDirty();
      } catch (error, stackTrace) {
        e._handleUncaughtError(error, stackTrace);
      }
    }
    currentBatch.clear();
  }
}

/// Handles lazy deactivation of 1:N Broadcasters when all downstream subscribers
/// disconnect.
///
/// When downstream reactive nodes disconnect from a 1:N broadcaster, immediate
/// deactivation can be wasteful if a new subscriber attaches shortly after.
/// [_BroadcasterDeactivateSchedulerMixin] defers deactivation checks to the
/// end of the current microtask.
///
/// **Design Philosophy:**
/// Prevents premature stream/resource tear-down during rapid subscriber churn,
/// ensuring broadcasters remain active if re-subscribed within the same turn.
///
/// **AI & Developer Note:**
/// Broadcasters are only deactivated if `isActivated` is `true` AND `_outbounds`
/// is empty at the time of microtask execution.
base mixin _BroadcasterDeactivateSchedulerMixin on _CorallineSchedulerBase {
  /// Set of candidate [_CoralBroadcasterBase] instances pending deactivation check.
  Set<_CoralBroadcasterBase> _broadcasterSet = <_CoralBroadcasterBase>{};

  /// Secondary set used for double-buffering swaps to preserve capacity.
  Set<_CoralBroadcasterBase> _broadcasterSwapSet = <_CoralBroadcasterBase>{};

  /// Enqueues a [broadcaster] for deferred deactivation inspection.
  ///
  /// * [broadcaster]: The broadcaster candidate to check.
  ///
  /// **Returns:**
  /// `true` if the broadcaster was newly scheduled; `false` if already queued.
  bool _scheduleBroadcasterDeactivate(_CoralBroadcasterBase broadcaster) {
    if (!_broadcasterSet.add(broadcaster)) return false;
    _ensureScheduled();
    return true;
  }

  /// Computes pending broadcasters and deactivates those with zero subscribers.
  ///
  /// **Ensures:**
  /// Calls `deactivate()` on broadcasters that are active and have no remaining
  /// outbound connections. Uncaught errors are passed to [Zone.current].
  @mustCallSuper
  @override
  void _onTask() {
    super._onTask();
    if (_broadcasterSet.isEmpty) return;

    final currentBatch = _broadcasterSet;
    _broadcasterSet = _broadcasterSwapSet;
    _broadcasterSwapSet = currentBatch;

    for (var e in currentBatch) {
      try {
        // CRITICAL PERFORMANCE OPTIMIZATION & LAZY CANCELLATION:
        // 1. Behavior: If a new subscriber branch attached (_attach) after deactivation was
        //    scheduled but before this microtask executed, cancel deactivation and keep active.
        // 2. Performance: Performing this check lazily during flush completely eliminates the
        //    massive hot-path overhead of calling `scheduler.remove(this)` on EVERY single
        //    `_attach()` invocation across the entire framework.
        if (e._outbounds.isNotEmpty) continue;

        if (e.isActivated) e._terminal.deactivate();
      } catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }
    }
    currentBatch.clear();
  }
}

/// The global unified scheduler for Coralline.
///
/// Combines Mooring cleanup, Lazy Dirty push, and Broadcaster lazy deactivation
/// into a single microtask execution chain.
///
/// **Design Philosophy:**
/// Uses Dart mixin linearization to guarantee a deterministic three-phase
/// microtask execution order:
/// 1. Mooring cleanup ([_MooringSchedulerMixin])
/// 2. Lazy dirty notification push ([_LazyDirtyPushSchedulerMixin])
/// 3. Broadcaster lazy deactivation ([_BroadcasterDeactivateSchedulerMixin])
///
/// **AI & Developer Note:**
/// Do not instantiate directly. Use the global singleton [instance] to schedule
/// microtask operations across the framework.
///
/// **Example:**
/// ```dart
/// // Internal framework scheduling usage:
/// _CorallineScheduler.instance.scheduleDirtyPush(dirtyPoint);
/// ```
base class _CorallineScheduler extends _CorallineSchedulerBase
    with _MooringSchedulerMixin, _LazyDirtyPushSchedulerMixin, _BroadcasterDeactivateSchedulerMixin {
  /// Private constructor to enforce singleton usage pattern.
  _CorallineScheduler._();

  /// The global shared instance of [_CorallineScheduler].
  static final _CorallineScheduler instance = _CorallineScheduler._();
}

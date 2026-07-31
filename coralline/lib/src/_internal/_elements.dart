// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

final class _KeyedMapCoral<E, K, T> extends _ReadlessRelayComputeCoralProxy<Iterable<E>, List<T>> {
  _KeyedMapCoral(
    super.inbound, {
    required K Function(E data) key,
    required T Function(E data) convert,
  })  : _keySelector = key,
        _convert = convert;

  final K Function(E data) _keySelector;

  final T Function(E data) _convert;

  /// Internal map caching converted values [T] indexed by key [K].
  ///
  /// ### Cache Retention & Lifecycle:
  /// - **Do NOT clear on `_performClearance()` or `isDamaged`**:
  ///   `_performClearance()` invalidates `_snapshot` when [inbound] emits dirty.
  ///   Clearing `_internalCache` on clearance would defeat the caching purpose of
  ///   `keyed.map`, causing re-evaluation of `_convert` for existing keys.
  /// - **Explicit Reset**: Cleared when [source] is empty (`source.isEmpty`) or when
  ///   an unhandled computation exception occurs inside [_compute].
  /// - **Garbage Sweeping**: Inactive keys are removed via [Map.removeWhere] when cache
  ///   length exceeds active keys (Pigeonhole Principle).
  final Map<K, T> _internalCache = {};

  @mustCallSuper
  @override
  CoralSnapshot<List<T>> _compute() {
    try {
      final source = _inbound.snapshot;
      if (source.isEmpty) {
        _internalCache.clear();
        return CoralSnapshot.empty();
      } else if (source.isDamaged) {
        return CoralSnapshot.damaged(source.error, source.stackTrace);
      } else {
        final newResult = <T>[];
        final activeKeys = <K>{};

        try {
          for (final data in source.data) {
            final key = _keySelector(data);
            activeKeys.add(key);
            var cached = _internalCache[key];
            if (cached != null) {
              newResult.add(cached);
            } else {
              final converted = _convert(data);
              _internalCache[key] = converted;
              newResult.add(converted);
            }
          }
        } catch (error, stackTrace) {
          _internalCache.clear();
          return CoralSnapshot.damaged(error, stackTrace);
        }

        // Optimization: Sweeping the internal cache via removeWhere is an O(N) operation.
        // By checking if the cache size exceeds activeKeys.length (Pigeonhole Principle),
        // we skip the full map traversal in O(1) when no keys have been removed.
        if (_internalCache.length > activeKeys.length) {
          _internalCache.removeWhere((key, _) => !activeKeys.contains(key));
        }

        return CoralSnapshot(UnmodifiableListView(newResult));
      }
    } catch (error, stackTrace) {
      return CoralSnapshot.damaged(error, stackTrace);
    }
  }
}

abstract base class _KeyedDivergingTrunk<E, K, T> extends _CascadingTrunk<Iterable<E>, T> {
  _KeyedDivergingTrunk(
    Coral<Iterable<E>> source, {
    required K Function(E data) key,
    required Coral<T> Function(E data) builder,
  })  : _keySelector = key,
        _nodeBuilder = builder,
        super(source: source);

  final K Function(E data) _keySelector;

  final Coral<T> Function(E data) _nodeBuilder;

  /// Internal map caching built [Coral] nodes by their key [K].
  ///
  /// ### Cache Retention & Lifecycle:
  /// - **Do NOT clear on `_performRelease()` or `_setError()`**:
  ///   In lazy cascading, `_performRelease()` is called whenever the source emits dirty.
  ///   Clearing `_internalCache` on release/error would wipe node identity and inner state,
  ///   causing unnecessary node re-creation on subsequent pulls. Node lifecycles
  ///   (attachment/detachment) are synchronized separately while maintaining cache entries.
  /// - **Explicit Reset**: Cleared only when [source] is empty (`source.isEmpty`).
  /// - **Garbage Sweeping**: Inactive keys are removed via [Map.removeWhere] during evaluation.
  final Map<K, Coral<T>> _internalCache = {};

  @mustCallSuper
  @override
  void _performCascadeGuarded() {
    try {
      final source = _sourceTerminal._inbound.snapshot;
      if (source.isEmpty) {
        _internalCache.clear();
        _performRelease();
      } else if (source.isDamaged) {
        _setError(source.error, source.stackTrace);
      } else {
        final newResult = <Coral<T>>[];
        final activeKeys = <K>{};

        for (final data in source.data) {
          K key;
          try {
            key = _keySelector(data);
          } catch (error, stackTrace) {
            newResult.add(Coral.damaged(error, stackTrace));
            continue;
          }
          try {
            activeKeys.add(key);
            var cached = _internalCache[key];
            if (cached != null) {
              newResult.add(cached);
            } else {
              final built = _nodeBuilder(data);
              _internalCache[key] = built;
              newResult.add(built);
            }
          } catch (error, stackTrace) {
            newResult.add(Coral.damaged(error, stackTrace));
            continue;
          }
        }

        _internalCache.removeWhere((k, _) => !activeKeys.contains(k));

        _performUpdate(newResult);
      }
    } catch (error, stackTrace) {
      _setError(error, stackTrace);
    }
  }
}

base class _SealedColdswapLazyKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with _SuppressibleDirtyPoint, _SealedColdswapTrunkMixin<T>, _LazyCascadingTrunkMixin<Iterable<E>, T> {
  _SealedColdswapLazyKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

base class _SealedColdswapEagerKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with _SealedColdswapTrunkMixin<T>, _EagerCascadingTrunkMixin<Iterable<E>, T> {
  _SealedColdswapEagerKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

base class _SealedHotswapLazyKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with
        _SuppressibleDirtyPoint,
        _JointMooringMixin,
        _SealedHotswapTrunkMixin<T>,
        _LazyCascadingTrunkMixin<Iterable<E>, T> {
  _SealedHotswapLazyKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

base class _SealedHotswapEagerKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with _JointMooringMixin, _SealedHotswapTrunkMixin<T>, _EagerCascadingTrunkMixin<Iterable<E>, T> {
  _SealedHotswapEagerKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

base class _DetachableColdswapLazyKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with _SuppressibleDirtyPoint, _DetachableColdswapTrunkMixin<T>, _LazyCascadingTrunkMixin<Iterable<E>, T> {
  _DetachableColdswapLazyKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

base class _DetachableColdswapEagerKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with _DetachableColdswapTrunkMixin<T>, _EagerCascadingTrunkMixin<Iterable<E>, T> {
  _DetachableColdswapEagerKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

base class _DetachableHotswapLazyKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with
        _SuppressibleDirtyPoint,
        _JointMooringMixin,
        _DetachableHotswapTrunkMixin<T>,
        _LazyCascadingTrunkMixin<Iterable<E>, T> {
  _DetachableHotswapLazyKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

base class _DetachableHotswapEagerKeyedDivergingTrunk<E, K, T> extends _KeyedDivergingTrunk<E, K, T>
    with _JointMooringMixin, _DetachableHotswapTrunkMixin<T>, _EagerCascadingTrunkMixin<Iterable<E>, T> {
  _DetachableHotswapEagerKeyedDivergingTrunk(super.source, {required super.key, required super.builder});
}

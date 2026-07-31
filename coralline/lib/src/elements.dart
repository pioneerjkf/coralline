// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

extension IterableCoralElementsExtension<E> on Coral<Iterable<E>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [Iterable] reactively.
  CoralIterableElements<E> get elements => CoralIterableElements<E>._(this);
}

extension KeyedIterableCoralElementsExtension<E> on Coral<Iterable<E>> {
  /// Opens a dedicated namespace for operating on keyed elements of this [Iterable] reactively.
  CoralKeyedIterableElements<E> get keyed => CoralKeyedIterableElements<E>._(this);
}

extension ListCoralElementsExtension<E> on Coral<List<E>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [List] reactively.
  CoralListElements<E> get elements => CoralListElements<E>._(this);
}

extension SetCoralElementsExtension<E> on Coral<Set<E>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [Set] reactively.
  CoralSetElements<E> get elements => CoralSetElements<E>._(this);
}

extension MapCoralElementsExtension<K, V> on Coral<Map<K, V>> {
  /// Opens a dedicated namespace for operating on the individual elements of this [Map] reactively.
  CoralMapElements<K, V> get elements => CoralMapElements<K, V>._(this);
}

/// **Core Concept (Collection Element Proxy):**
/// A dedicated proxy wrapper for [Coral<Iterable<E>>] to perform element-wise
/// transformations and computations safely and defensively.
///
/// Under the hood, all collection-returning operations immediately compute and package
/// results into an immutable list ([List.unmodifiable]) to prevent lazy computation exceptions
/// outside the reactive boundary and to enforce state immutability.
extension type CoralIterableElements<E>._(Coral<Iterable<E>> _coral) {
  /// Exposes the underlying [Coral] node of this elements proxy.
  Coral<Iterable<E>> get coral => _coral;

  /// Maps each element of this collection to another object [T].
  Coral<List<T>> map<T>(T Function(E element) convert) =>
      _coral.map((source) => List.unmodifiable(source.map(convert)));

  /// Filters elements of this collection based on [test].
  Coral<List<E>> where(bool Function(E element) test) => _coral.map((source) => List.unmodifiable(source.where(test)));

  /// Returns a list of elements that have type [T] reactively.
  Coral<List<T>> whereType<T>() => _coral.map((source) => List.unmodifiable(source.whereType<T>()));

  /// Returns a list of (index, element) pairs reactively.
  Coral<List<(int, E)>> get indexed => _coral.map((source) => List.unmodifiable(source.indexed));

  /// Flattens this collection by mapping each element to an [Iterable] and concatenating.
  Coral<List<T>> expand<T>(Iterable<T> Function(E element) toElements) =>
      _coral.map((source) => List.unmodifiable(source.expand(toElements)));

  /// Checks whether the collection contains an element equal to [element] reactively.
  Coral<bool> contains(Object? element) => _coral.map((source) => source.contains(element));

  /// Reduces a collection to a single value by iteratively combining elements reactively.
  Coral<E> reduce(E Function(E value, E element) combine) => _coral.map((source) => source.reduce(combine));

  /// Reduces a collection to a single value by iteratively combining elements with an initial value reactively.
  Coral<T> fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      _coral.map((source) => source.fold(initialValue, combine));

  /// Checks if all elements satisfy [test].
  Coral<bool> every(bool Function(E element) test) => _coral.map((source) => source.every(test));

  /// Converts each element to a [String] and concatenates the results reactively.
  Coral<String> join([String separator = '']) => _coral.map((source) => source.join(separator));

  /// Checks if any element satisfies [test].
  Coral<bool> any(bool Function(E element) test) => _coral.map((source) => source.any(test));

  /// Returns a list containing the elements of this iterable reactively.
  Coral<List<E>> toList() => _coral.map((source) => List.unmodifiable(source));

  /// Returns a set containing the elements of this iterable reactively.
  Coral<Set<E>> toSet() => _coral.map((source) => Set.unmodifiable(source.toSet()));

  /// Returns the number of elements reactively.
  Coral<int> get length => _coral.map((source) => source.length);

  /// Checks if this collection is empty.
  Coral<bool> get isEmpty => _coral.map((source) => source.isEmpty);

  /// Checks if this collection is not empty.
  Coral<bool> get isNotEmpty => _coral.map((source) => source.isNotEmpty);

  /// Takes the first [count] elements of this collection.
  Coral<List<E>> take(int count) => _coral.map((source) => List.unmodifiable(source.take(count)));

  /// Skips the first [count] elements of this collection.
  Coral<List<E>> skip(int count) => _coral.map((source) => List.unmodifiable(source.skip(count)));

  /// Returns the first element of this collection reactively.
  Coral<E> get first => _coral.map((source) => source.first);

  /// Returns the first element of this collection reactively, or null if empty.
  Coral<E?> get firstOrNull => _coral.map((source) => source.firstOrNull);

  /// Returns the last element of this collection reactively.
  Coral<E> get last => _coral.map((source) => source.last);

  /// Returns the last element of this collection reactively, or null if empty.
  Coral<E?> get lastOrNull => _coral.map((source) => source.lastOrNull);

  /// Checks that this collection has only one element, and returns that element reactively.
  Coral<E> get single => _coral.map((source) => source.single);

  /// Checks that this collection has only one element, and returns that element reactively, or null if empty/multiple.
  Coral<E?> get singleOrNull => _coral.map((source) => source.singleOrNull);

  /// Returns the first element that satisfies the given predicate [test] reactively.
  Coral<E> firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _coral.map((source) => source.firstWhere(test, orElse: orElse));

  /// Returns the last element that satisfies the given predicate [test] reactively.
  Coral<E> lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _coral.map((source) => source.lastWhere(test, orElse: orElse));

  /// Returns the single element that satisfies [test] reactively.
  Coral<E> singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      _coral.map((source) => source.singleWhere(test, orElse: orElse));

  /// Returns the [index]th element reactively.
  Coral<E> elementAt(int index) => _coral.map((source) => source.elementAt(index));
}

/// **Core Concept (Keyed Collection Element Proxy):**
/// A dedicated proxy wrapper for [Coral<Iterable<E>>] to perform keyed element-wise
/// transformations and divergence operations safely and lazily.
extension type CoralKeyedIterableElements<E>._(Coral<Iterable<E>> _coral) {
  /// Exposes the underlying [Coral] node.
  Coral<Iterable<E>> get coral => _coral;

  /// Maps an `Iterable` to a `List` of objects while safely caching the mapped
  /// objects by unique keys.
  ///
  /// This operator is highly optimized for maintaining expensive custom Dart objects
  /// (such as widgets, controllers, or ViewModels) across iterable state changes.
  ///
  /// **Design Philosophy:**
  /// By reusing instances whose keys haven't changed, this method minimizes object
  /// instantiation overhead and preserves local state within the mapped objects
  /// across frequent updates of the source iterable.
  ///
  /// * [key]: A function that extracts a unique identifier from a source element.
  /// * [convert]: A function that constructs a new mapped object `T` from a source element.
  ///
  /// **Requires:**
  /// * The [key] function must return a stable, unique identifier for each logically
  ///   distinct element.
  ///
  /// **Ensures:**
  /// * Returns a `Coral<List<T>>` containing the newly mapped or cached objects.
  /// * If a source element's key matches a cached object, the cached object is reused
  ///   instead of calling [convert] again.
  Coral<List<T>> map<K, T>({
    required K Function(E data) key,
    required T Function(E data) convert,
  }) =>
      _KeyedMapCoral<E, K, T>(_coral, key: key, convert: convert);

  /// Transforms an `Iterable` into a `Trunk` while safely managing node lifecycle and caching by unique keys.
  ///
  /// Unlike standard [diverge], this extension prevents memory leaks and state loss
  /// by internally tracking and garbage collecting [Coral] nodes based on the `key` extractor.
  ///
  /// **Design Philosophy:**
  /// When diverging an iterable into dynamic coral nodes, recreating nodes on every update
  /// causes state loss and severe performance issues. This method ensures that dynamically
  /// created nodes are cached and preserved across updates, only rebuilding when their
  /// associated key fundamentally changes.
  ///
  /// * [key]: A function that extracts a unique, stable identifier from each element in the source iterable.
  /// * [builder]: A function that constructs a new [Coral] node from a source element.
  /// * [seal]: If `true`, the resulting `Trunk` is sealed and cannot be externally modified. Defaults to `true`.
  /// * [hotswap]: If `true`, the trunk allows hotswapping components. Defaults to `false`.
  /// * [eager]: If `true`, nodes are computed eagerly upon creation. Defaults to `false`.
  ///
  /// **Requires:**
  /// * The [key] function must return a stable, unique identifier for each logically distinct element.
  ///
  /// **Ensures:**
  /// * Returns a `Trunk<T>` containing the diverged `Coral` nodes.
  /// * Child nodes mapped to an existing key are preserved and reused across updates.
  /// * When a key is no longer present in the updated iterable, the framework automatically
  ///   releases its associated [Coral] node.
  ///
  /// **Example:**
  /// ```dart
  /// final usersCoral = Coral.data([User(id: '1', name: 'Alice')]);
  ///
  /// final userTrunk = usersCoral.keyed.diverge(
  ///   key: (user) => user.id, // Stable unique identifier
  ///   builder: (user) => UserProfileCoral(user.id), // Dynamically maps to a child Coral
  /// );
  /// ```
  Trunk<T> diverge<K, T>({
    required K Function(E data) key,
    required Coral<T> Function(E data) builder,
    bool seal = true,
    bool hotswap = false,
    bool eager = false,
  }) =>
      switch ((seal, hotswap, eager)) {
        (true, true, true) => _SealedHotswapEagerKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
        (true, true, false) => _SealedHotswapLazyKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
        (true, false, true) => _SealedColdswapEagerKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
        (true, false, false) => _SealedColdswapLazyKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
        (false, true, true) => _DetachableHotswapEagerKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
        (false, true, false) => _DetachableHotswapLazyKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
        (false, false, true) => _DetachableColdswapEagerKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
        (false, false, false) => _DetachableColdswapLazyKeyedDivergingTrunk<E, K, T>(
            _coral,
            key: key,
            builder: builder,
          ),
      };
}

/// **Core Concept (List Element Proxy):**
/// A dedicated proxy wrapper for [Coral<List<E>>] to perform list-specific
/// transformations and lookup computations.
extension type CoralListElements<E>._(Coral<List<E>> _coral) implements CoralIterableElements<E> {
  /// Look up the element at [index] reactively.
  Coral<E> operator [](int index) => _coral.map((list) => list[index]);

  /// Returns a reversed view of this list reactively.
  Coral<List<E>> get reversed => _coral.map((list) => List.unmodifiable(list.reversed));

  /// Returns the first index of [element] reactively.
  Coral<int> indexOf(E element, [int start = 0]) => _coral.map((list) => list.indexOf(element, start));

  /// Returns the first index in the list that satisfies [test] reactively.
  Coral<int> indexWhere(bool Function(E element) test, [int start = 0]) =>
      _coral.map((list) => list.indexWhere(test, start));

  /// Returns the last index in the list that satisfies [test] reactively.
  Coral<int> lastIndexWhere(bool Function(E element) test, [int? start]) =>
      _coral.map((list) => list.lastIndexWhere(test, start));

  /// Returns the last index of [element] reactively.
  Coral<int> lastIndexOf(E element, [int? start]) => _coral.map((list) => list.lastIndexOf(element, start));

  /// Returns a sublist of this list reactively.
  Coral<List<E>> sublist(int start, [int? end]) => _coral.map((list) => List.unmodifiable(list.sublist(start, end)));

  /// Returns an unmodifiable [Map] view of this list reactively.
  Coral<Map<int, E>> asMap() => _coral.map((list) => Map.unmodifiable(list.asMap()));
}

/// **Core Concept (Set Element Proxy):**
/// A dedicated proxy wrapper for [Coral<Set<E>>] to perform set-specific
/// transformations and operations while preserving set types.
extension type CoralSetElements<E>._(Coral<Set<E>> _coral) implements CoralIterableElements<E> {
  /// Looks up [object] in the set reactively.
  Coral<E?> lookup(Object? object) => _coral.map((set) => set.lookup(object));

  /// Computes the intersection of this set and [other] reactively.
  Coral<Set<E>> intersection(Set<E> other) => _coral.map((set) => Set.unmodifiable(set.intersection(other)));

  /// Computes the union of this set and [other] reactively.
  Coral<Set<E>> union(Set<E> other) => _coral.map((set) => Set.unmodifiable(set.union(other)));

  /// Computes the difference between this set and [other] reactively.
  Coral<Set<E>> difference(Set<E> other) => _coral.map((set) => Set.unmodifiable(set.difference(other)));
}

/// **Core Concept (Map Element Proxy):**
/// A dedicated proxy wrapper for [Coral<Map<K, V>>] to perform map-specific
/// lookup, mapping, and filtering operations.
extension type CoralMapElements<K, V>._(Coral<Map<K, V>> _coral) {
  /// Exposes the underlying [Coral] node of this elements proxy.
  Coral<Map<K, V>> get coral => _coral;

  /// Look up the value associated with [key] reactively.
  Coral<V?> operator [](K key) => _coral.map((map) => map[key]);

  /// Checks whether this map contains the given [key] reactively.
  Coral<bool> containsKey(Object? key) => _coral.map((map) => map.containsKey(key));

  /// Checks whether this map contains the given [value] reactively.
  Coral<bool> containsValue(Object? value) => _coral.map((map) => map.containsValue(value));

  /// Maps the entries of this map reactively to a new map.
  Coral<Map<K2, V2>> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) =>
      _coral.map((source) => Map.unmodifiable(source.map(convert)));

  /// Filters the entries of this map based on [test] reactively.
  Coral<Map<K, V>> where(bool Function(K key, V value) test) {
    return _coral.map((source) {
      final filtered = Map<K, V>.from(source)..removeWhere((k, v) => !test(k, v));
      return Map.unmodifiable(filtered);
    });
  }

  /// Returns the keys of this map reactively.
  Coral<List<K>> get keys => _coral.map((map) => List.unmodifiable(map.keys));

  /// Returns the values of this map reactively.
  Coral<List<V>> get values => _coral.map((map) => List.unmodifiable(map.values));

  /// Returns the number of key-value pairs reactively.
  Coral<int> get length => _coral.map((map) => map.length);

  /// Checks if this map is empty.
  Coral<bool> get isEmpty => _coral.map((source) => source.isEmpty);

  /// Checks if this map is not empty.
  Coral<bool> get isNotEmpty => _coral.map((source) => source.isNotEmpty);
}

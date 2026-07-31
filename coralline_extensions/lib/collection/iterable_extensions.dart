// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use

import 'dart:math' show Random;
import 'package:collection/collection.dart';
import 'package:collection/collection.dart' as col;
import 'package:coralline/coralline.dart';

extension GeneralCoralElementsExtension<E> on CoralIterableElements<E> {
  /// Selects [count] elements at random from this collection reactively.
  Coral<List<E>> sample(int count, [Random? random]) =>
      coral.map((source) => List.unmodifiable(source.sample(count, random)));

  /// Returns a list of elements that do not satisfy [test] reactively.
  Coral<List<E>> whereNot(bool Function(E element) test) =>
      coral.map((source) => List.unmodifiable(source.whereNot(test)));

  /// Returns a list containing the elements of this collection sorted by [compare] reactively.
  Coral<List<E>> sorted(int Function(E a, E b) compare) =>
      coral.map((source) => List.unmodifiable(source.sorted(compare)));

  /// Returns a list containing the elements of this collection shuffled reactively.
  Coral<List<E>> shuffled([Random? random]) =>
      coral.map((source) => List.unmodifiable(source.shuffled(random)));

  /// Returns a list containing the elements of this collection sorted by [keyOf] reactively.
  Coral<List<E>> sortedBy<K extends Comparable<dynamic>>(
          K Function(E element) keyOf) =>
      coral.map((source) => List.unmodifiable(
          source.sortedByCompare<K>(keyOf, (a, b) => a.compareTo(b))));

  /// Returns a list containing the elements of this collection sorted by [compare] of [keyOf] reactively.
  Coral<List<E>> sortedByCompare<K>(
          K Function(E element) keyOf, int Function(K a, K b) compare) =>
      coral.map((source) =>
          List.unmodifiable(source.sortedByCompare<K>(keyOf, compare)));

  /// Returns true if this collection is sorted by [compare] reactively.
  Coral<bool> isSorted(int Function(E a, E b) compare) =>
      coral.map((source) => source.isSorted(compare));

  /// Returns true if this collection is sorted by the natural order of [keyOf] reactively.
  Coral<bool> isSortedBy<K extends Comparable<dynamic>>(
          K Function(E element) keyOf) =>
      coral.map((source) =>
          source.isSortedByCompare<K>(keyOf, (a, b) => a.compareTo(b)));

  /// Returns true if this collection is sorted by [compare] of [keyOf] reactively.
  Coral<bool> isSortedByCompare<K>(
          K Function(E element) keyOf, int Function(K a, K b) compare) =>
      coral.map((source) => source.isSortedByCompare<K>(keyOf, compare));

  /// Maps each element of this collection along with its index reactively.
  Coral<List<T>> mapIndexed<T>(T Function(int index, E element) convert) =>
      coral.map((source) => List.unmodifiable(source.mapIndexed(convert)));

  /// Filters elements of this collection based on an indexed predicate [test] reactively.
  Coral<List<E>> whereIndexed(bool Function(int index, E element) test) =>
      coral.map((source) => List.unmodifiable(source.whereIndexed(test)));

  /// Filters elements of this collection based on an indexed predicate [test] reactively, returning those that do not satisfy it.
  Coral<List<E>> whereNotIndexed(bool Function(int index, E element) test) =>
      coral.map((source) => List.unmodifiable(source.whereNotIndexed(test)));

  /// Flattens this collection along with element indices reactively.
  Coral<List<T>> expandIndexed<T>(
          Iterable<T> Function(int index, E element) toElements) =>
      coral
          .map((source) => List.unmodifiable(source.expandIndexed(toElements)));

  /// Reduces this collection to a single value by iteratively combining elements along with their index reactively.
  Coral<E> reduceIndexed(
          E Function(int index, E previous, E element) combine) =>
      coral.map((source) => source.reduceIndexed(combine));

  /// Reduces this collection to a single value by iteratively combining elements along with their index and an initial value reactively.
  Coral<T> foldIndexed<T>(T initialValue,
          T Function(int index, T previous, E element) combine) =>
      coral.map((source) => source.foldIndexed<T>(initialValue, combine));

  /// Returns the first element that satisfies [test] reactively, or null if none.
  Coral<E?> firstWhereOrNull(bool Function(E element) test) =>
      coral.map((source) => source.firstWhereOrNull(test));

  /// Returns the first element that satisfies an indexed predicate [test] reactively, or null if none.
  Coral<E?> firstWhereIndexedOrNull(bool Function(int index, E element) test) =>
      coral.map((source) => source.firstWhereIndexedOrNull(test));

  /// Returns the last element that satisfies [test] reactively, or null if none.
  Coral<E?> lastWhereOrNull(bool Function(E element) test) =>
      coral.map((source) => source.lastWhereOrNull(test));

  /// Returns the last element that satisfies an indexed predicate [test] reactively, or null if none.
  Coral<E?> lastWhereIndexedOrNull(bool Function(int index, E element) test) =>
      coral.map((source) => source.lastWhereIndexedOrNull(test));

  /// Returns the single element that satisfies [test] reactively, or null if none.
  Coral<E?> singleWhereOrNull(bool Function(E element) test) =>
      coral.map((source) => source.singleWhereOrNull(test));

  /// Returns the single element that satisfies an indexed predicate [test] reactively, or null if none.
  Coral<E?> singleWhereIndexedOrNull(
          bool Function(int index, E element) test) =>
      coral.map((source) => source.singleWhereIndexedOrNull(test));

  /// Returns the [index]th element reactively, or null if out of range.
  Coral<E?> elementAtOrNull(int index) =>
      coral.map((source) => source.elementAtOrNull(index));

  /// Groups elements by [key] reactively, keeping only the last element for each key.
  Coral<Map<K, E>> lastBy<K>(K Function(E element) key) =>
      coral.map((source) => Map<K, E>.unmodifiable(source.lastBy<K>(key)));

  /// Groups and folds elements by a key computed from each element reactively.
  Coral<Map<K, G>> groupFoldBy<K, G>({
    required K Function(E element) key,
    required G Function(G? previous, E element) fold,
  }) =>
      coral.map((source) =>
          Map<K, G>.unmodifiable(source.groupFoldBy<K, G>(key, fold)));

  /// Groups elements into sets by [keyOf] reactively.
  Coral<Map<K, Set<E>>> groupSetsBy<K>(K Function(E element) keyOf) =>
      coral.map((source) => Map<K, Set<E>>.unmodifiable(
            source
                .groupSetsBy<K>(keyOf)
                .map((k, v) => MapEntry<K, Set<E>>(k, Set<E>.unmodifiable(v))),
          ));

  /// Groups elements into lists by [keyOf] reactively.
  Coral<Map<K, List<E>>> groupListsBy<K>(K Function(E element) keyOf) =>
      coral.map((source) => Map<K, List<E>>.unmodifiable(
            source.groupListsBy<K>(keyOf).map(
                (k, v) => MapEntry<K, List<E>>(k, List<E>.unmodifiable(v))),
          ));

  /// Legacy alias of [groupListsBy].
  Coral<Map<K, List<E>>> groupBy<K>(K Function(E element) key) =>
      coral.map((source) => Map<K, List<E>>.unmodifiable(
            col.groupBy<E, K>(source, key).map(
                (k, v) => MapEntry<K, List<E>>(k, List<E>.unmodifiable(v))),
          ));

  /// Splits this collection into chunks before elements satisfying [test] reactively.
  Coral<List<List<E>>> splitBefore(bool Function(E element) test) =>
      coral.map((source) => List<List<E>>.unmodifiable(
            source.splitBefore(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks after elements satisfying [test] reactively.
  Coral<List<List<E>>> splitAfter(bool Function(E element) test) =>
      coral.map((source) => List<List<E>>.unmodifiable(
            source.splitAfter(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks between elements satisfying [test] reactively.
  Coral<List<List<E>>> splitBetween(bool Function(E first, E second) test) =>
      coral.map((source) => List<List<E>>.unmodifiable(
            source.splitBetween(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks before elements satisfying an indexed predicate [test] reactively.
  Coral<List<List<E>>> splitBeforeIndexed(
          bool Function(int index, E element) test) =>
      coral.map((source) => List<List<E>>.unmodifiable(
            source.splitBeforeIndexed(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks after elements satisfying an indexed predicate [test] reactively.
  Coral<List<List<E>>> splitAfterIndexed(
          bool Function(int index, E element) test) =>
      coral.map((source) => List<List<E>>.unmodifiable(
            source.splitAfterIndexed(test).map((s) => List<E>.unmodifiable(s)),
          ));

  /// Splits this collection into chunks between elements satisfying an indexed predicate [test] reactively.
  Coral<List<List<E>>> splitBetweenIndexed(
          bool Function(int index, E first, E second) test) =>
      coral.map((source) => List<List<E>>.unmodifiable(
            source
                .splitBetweenIndexed(test)
                .map((s) => List<E>.unmodifiable(s)),
          ));

  /// Returns true if no elements satisfy [test] reactively.
  Coral<bool> none(bool Function(E element) test) =>
      coral.map((source) => source.none(test));

  /// Returns true if no elements satisfy an indexed predicate [test] reactively.
  Coral<bool> noneIndexed(bool Function(int index, E element) test) => coral
      .map((source) => !source.indexed.any((pair) => test(pair.$1, pair.$2)));

  /// Returns true if any element satisfies an indexed predicate [test] reactively.
  Coral<bool> anyIndexed(bool Function(int index, E element) test) => coral
      .map((source) => source.indexed.any((pair) => test(pair.$1, pair.$2)));

  /// Returns true if all elements satisfy an indexed predicate [test] reactively.
  Coral<bool> everyIndexed(bool Function(int index, E element) test) => coral
      .map((source) => source.indexed.every((pair) => test(pair.$1, pair.$2)));

  /// Splits this collection into chunks of [size] elements reactively.
  Coral<List<List<E>>> slices(int size) =>
      coral.map((source) => List<List<E>>.unmodifiable(
            source.slices(size).map((s) => List<E>.unmodifiable(s)),
          ));
}

extension NullableCoralElementsExtension<E extends Object>
    on CoralIterableElements<E?> {
  /// Returns a list of all non-null elements of this collection reactively.
  Coral<List<E>> get whereNotNull =>
      coral.map((source) => List.unmodifiable(source.whereNotNull()));
}

extension IterableIterableCoralElementsExtension<T>
    on CoralIterableElements<Iterable<T>> {
  /// Flattens this collection of iterables into a single iterable reactively.
  Coral<List<T>> get flattenedToList =>
      coral.map((source) => List.unmodifiable(source.flattened));

  /// Flattens this collection of iterables into a single set reactively.
  Coral<Set<T>> get flattenedToSet =>
      coral.map((source) => Set.unmodifiable(source.flattened.toSet()));
}

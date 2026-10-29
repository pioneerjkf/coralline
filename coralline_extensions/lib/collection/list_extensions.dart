// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:math' show Random;
import 'package:collection/collection.dart';
import 'package:collection/collection.dart' as col;
import 'package:coralline/coralline.dart';

/// Reactive binary search, range sorting, slicing, and equality extensions for [CoralListElements].
extension ListCoralElementsExtension<E> on CoralListElements<E> {
  Coral<List<E>> get _listCoral => coral as Coral<List<E>>;

  /// Returns the index of [element] in this sorted list using [compare], or `-1` if not found.
  ///
  /// * [element]: Element to search for.
  /// * [compare]: Comparator function defining the list's sort order.
  Coral<int> binarySearch(E element, int Function(E a, E b) compare) =>
      _listCoral.map(
          (list) => col.ListExtensions(list).binarySearch(element, compare));

  /// Returns the index of [element] in this sorted list between [start] and [end] using [keyOf] and [compare], or `-1` if not found.
  ///
  /// * [element]: Element to search for.
  /// * [keyOf]: Function extracting a sort key from each element.
  /// * [compare]: Comparator function for the extracted keys.
  /// * [start]: Inclusive start index (defaults to `0`).
  /// * [end]: Optional exclusive end index.
  Coral<int> binarySearchByCompare<K>(E element, K Function(E element) keyOf,
          int Function(K a, K b) compare, [int start = 0, int? end]) =>
      _listCoral.map((list) => col.ListExtensions(list)
          .binarySearchByCompare<K>(element, keyOf, compare, start, end));

  /// Returns the index of [element] in this sorted list between [start] and [end] using the natural order of [keyOf], or `-1` if not found.
  ///
  /// * [element]: Element to search for.
  /// * [keyOf]: Function extracting a comparable sort key from each element.
  /// * [start]: Inclusive start index (defaults to `0`).
  /// * [end]: Optional exclusive end index.
  Coral<int> binarySearchBy<K extends Comparable<dynamic>>(
          E element, K Function(E element) keyOf, [int start = 0, int? end]) =>
      _listCoral.map((list) => col.ListExtensions(list)
          .binarySearchByCompare<K>(
              element, keyOf, (a, b) => a.compareTo(b), start, end));

  /// Returns the first index where [element] can be inserted in this sorted list using [compare] while preserving sort order.
  ///
  /// * [element]: Element to locate the insertion bound for.
  /// * [compare]: Comparator function defining the list's sort order.
  Coral<int> lowerBound(E element, int Function(E a, E b) compare) => _listCoral
      .map((list) => col.ListExtensions(list).lowerBound(element, compare));

  /// Returns the first index between [start] and [end] where [element] can be inserted in this sorted list using [keyOf] and [compare].
  ///
  /// * [element]: Element to locate the insertion bound for.
  /// * [keyOf]: Function extracting a sort key from each element.
  /// * [compare]: Comparator function for the extracted keys.
  /// * [start]: Inclusive start index (defaults to `0`).
  /// * [end]: Optional exclusive end index.
  Coral<int> lowerBoundByCompare<K>(E element, K Function(E element) keyOf,
          int Function(K a, K b) compare, [int start = 0, int? end]) =>
      _listCoral.map((list) => col.ListExtensions(list)
          .lowerBoundByCompare<K>(element, keyOf, compare, start, end));

  /// Returns the first index between [start] and [end] where [element] can be inserted in this sorted list using the natural order of [keyOf].
  ///
  /// * [element]: Element to locate the insertion bound for.
  /// * [keyOf]: Function extracting a comparable sort key from each element.
  /// * [start]: Inclusive start index (defaults to `0`).
  /// * [end]: Optional exclusive end index.
  Coral<int> lowerBoundBy<K extends Comparable<dynamic>>(
          E element, K Function(E element) keyOf, [int start = 0, int? end]) =>
      _listCoral.map((list) => col.ListExtensions(list).lowerBoundByCompare<K>(
          element, keyOf, (a, b) => a.compareTo(b), start, end));

  /// Returns a new unmodifiable list with the elements in range [start] to [end] sorted by [compare].
  ///
  /// * [start]: Inclusive start index of the range to sort.
  /// * [end]: Exclusive end index of the range to sort.
  /// * [compare]: Comparator function defining the sort order.
  Coral<List<E>> sortedRange(
          int start, int end, int Function(E a, E b) compare) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).sortRange(start, end, compare);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with the elements in range [start] to [end] sorted by [compare] of [keyOf].
  ///
  /// * [keyOf]: Function extracting a sort key from each element.
  /// * [compare]: Comparator function for the extracted keys.
  /// * [start]: Inclusive start index (defaults to `0`).
  /// * [end]: Optional exclusive end index.
  Coral<List<E>> sortedByCompare<K>(
          K Function(E element) keyOf, int Function(K a, K b) compare,
          [int start = 0, int? end]) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).sortByCompare<K>(keyOf, compare, start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with the elements in range [start] to [end] sorted by the natural order of [keyOf].
  ///
  /// * [keyOf]: Function extracting a comparable sort key from each element.
  /// * [start]: Inclusive start index (defaults to `0`).
  /// * [end]: Optional exclusive end index.
  Coral<List<E>> sortedBy<K extends Comparable<dynamic>>(
          K Function(E element) keyOf,
          [int start = 0,
          int? end]) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy)
            .sortByCompare<K>(keyOf, (a, b) => a.compareTo(b), start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with the elements in range [start] to [end] shuffled using optional [random].
  ///
  /// * [start]: Inclusive start index.
  /// * [end]: Exclusive end index.
  /// * [random]: Optional random number generator.
  Coral<List<E>> shuffledRange(int start, int end, [Random? random]) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).shuffleRange(start, end, random);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with the elements in range [start] to [end] reversed.
  ///
  /// * [start]: Inclusive start index.
  /// * [end]: Exclusive end index.
  Coral<List<E>> reversedRange(int start, int end) => _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).reverseRange(start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new unmodifiable list with the elements at [index1] and [index2] swapped.
  ///
  /// * [index1]: Index of the first element.
  /// * [index2]: Index of the second element.
  Coral<List<E>> swapped(int index1, int index2) => _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).swap(index1, index2);
        return List<E>.unmodifiable(copy);
      });

  /// Returns an unmodifiable sublist of this list from [start] to [end] reactively.
  ///
  /// * [start]: Inclusive start index.
  /// * [end]: Optional exclusive end index.
  Coral<List<E>> slice(int start, [int? end]) => sublist(start, end);

  /// Returns `true` if [other] has the same elements as this list according to [equality].
  ///
  /// * [other]: List to compare against this list.
  /// * [equality]: Element equality strategy (defaults to [DefaultEquality]).
  Coral<bool> equals(List<E> other,
          [Equality<E> equality = const DefaultEquality()]) =>
      _listCoral
          .map((list) => col.ListExtensions(list).equals(other, equality));

  /// Returns the [index]th element reactively, or `null` if out of range.
  ///
  /// * [index]: Zero-based list index.
  Coral<E?> elementAtOrNull(int index) =>
      _listCoral.map((list) => col.ListExtensions(list).elementAtOrNull(index));

  /// Splits this list into contiguous unmodifiable slices of the given [length].
  ///
  /// * [length]: Maximum number of elements per slice.
  Coral<List<List<E>>> slices(int length) =>
      _listCoral.map((list) => List<List<E>>.unmodifiable(
            col.ListExtensions(list)
                .slices(length)
                .map((s) => List<E>.unmodifiable(s)),
          ));
}

/// Reactive binary search and range sorting extensions for [CoralListElements] of [Comparable] elements.
extension ListComparableCoralElementsExtension<E extends Comparable<dynamic>>
    on CoralListElements<E> {
  Coral<List<E>> get _listCoral => coral as Coral<List<E>>;

  /// Returns the index of [element] in this sorted list using [compare] (or natural order), or `-1` if not found.
  ///
  /// * [element]: Element to search for.
  /// * [compare]: Optional comparator function; defaults to `a.compareTo(b)`.
  Coral<int> binarySearch(E element, [int Function(E a, E b)? compare]) =>
      _listCoral.map((list) => col.ListExtensions(list)
           .binarySearch(element, compare ?? (a, b) => a.compareTo(b)));

  /// Returns the first index where [element] can be inserted in this sorted list using [compare] (or natural order).
  ///
  /// * [element]: Element to locate the insertion bound for.
  /// * [compare]: Optional comparator function; defaults to `a.compareTo(b)`.
  Coral<int> lowerBound(E element, [int Function(E a, E b)? compare]) =>
      _listCoral.map((list) => col.ListExtensions(list)
          .lowerBound(element, compare ?? (a, b) => a.compareTo(b)));

  /// Returns a new unmodifiable list with the elements in range [start] to [end] sorted by [compare] (or natural order).
  ///
  /// * [start]: Inclusive start index.
  /// * [end]: Exclusive end index.
  /// * [compare]: Optional comparator function; defaults to `a.compareTo(b)`.
  Coral<List<E>> sortedRange(int start, int end,
          [int Function(E a, E b)? compare]) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy)
            .sortRange(start, end, compare ?? (a, b) => a.compareTo(b));
        return List<E>.unmodifiable(copy);
      });
}

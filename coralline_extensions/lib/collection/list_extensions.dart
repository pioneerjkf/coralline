// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'dart:math' show Random;
import 'package:collection/collection.dart';
import 'package:collection/collection.dart' as col;
import 'package:coralline/coralline.dart';

extension ListCoralElementsExtension<E> on CoralListElements<E> {
  Coral<List<E>> get _listCoral => coral as Coral<List<E>>;

  /// Returns the index of [element] in this sorted list.
  Coral<int> binarySearch(E element, int Function(E a, E b) compare) =>
      _listCoral.map((list) => col.ListExtensions(list).binarySearch(element, compare));

  /// Returns the index of [element] in this sorted list.
  Coral<int> binarySearchByCompare<K>(
          E element, K Function(E element) keyOf, int Function(K a, K b) compare,
          [int start = 0, int? end]) =>
      _listCoral.map((list) =>
          col.ListExtensions(list).binarySearchByCompare<K>(element, keyOf, compare, start, end));

  /// Returns the index of [element] in this sorted list.
  Coral<int> binarySearchBy<K extends Comparable<dynamic>>(E element, K Function(E element) keyOf,
          [int start = 0, int? end]) =>
      _listCoral.map((list) => col.ListExtensions(list)
          .binarySearchByCompare<K>(element, keyOf, (a, b) => a.compareTo(b), start, end));

  /// Returns the index where [element] should be in this sorted list.
  Coral<int> lowerBound(E element, int Function(E a, E b) compare) =>
      _listCoral.map((list) => col.ListExtensions(list).lowerBound(element, compare));

  /// Returns the index where [element] should be in this sorted list.
  Coral<int> lowerBoundByCompare<K>(
          E element, K Function(E element) keyOf, int Function(K a, K b) compare,
          [int start = 0, int? end]) =>
      _listCoral.map((list) =>
          col.ListExtensions(list).lowerBoundByCompare<K>(element, keyOf, compare, start, end));

  /// Returns the index where [element] should be in this sorted list.
  Coral<int> lowerBoundBy<K extends Comparable<dynamic>>(E element, K Function(E element) keyOf,
          [int start = 0, int? end]) =>
      _listCoral.map((list) => col.ListExtensions(list)
          .lowerBoundByCompare<K>(element, keyOf, (a, b) => a.compareTo(b), start, end));

  /// Returns a new list containing a sorted range of elements from this list.
  Coral<List<E>> sortedRange(int start, int end, int Function(E a, E b) compare) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).sortRange(start, end, compare);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new list containing the sorted elements of this list by [compare] of [keyOf].
  Coral<List<E>> sortedByCompare<K>(K Function(E element) keyOf, int Function(K a, K b) compare,
          [int start = 0, int? end]) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).sortByCompare<K>(keyOf, compare, start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new list containing the sorted elements of this list by [keyOf].
  Coral<List<E>> sortedBy<K extends Comparable<dynamic>>(K Function(E element) keyOf,
          [int start = 0, int? end]) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).sortByCompare<K>(keyOf, (a, b) => a.compareTo(b), start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new list with a range of elements shuffled.
  Coral<List<E>> shuffledRange(int start, int end, [Random? random]) => _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).shuffleRange(start, end, random);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new list with a range of elements reversed.
  Coral<List<E>> reversedRange(int start, int end) => _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).reverseRange(start, end);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a new list with two elements swapped.
  Coral<List<E>> swapped(int index1, int index2) => _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).swap(index1, index2);
        return List<E>.unmodifiable(copy);
      });

  /// Returns a sublist of this list reactively.
  Coral<List<E>> slice(int start, [int? end]) => sublist(start, end);

  /// Whether [other] has the same elements as this list.
  Coral<bool> equals(List<E> other, [Equality<E> equality = const DefaultEquality()]) =>
      _listCoral.map((list) => col.ListExtensions(list).equals(other, equality));

  /// Returns the [index]th element reactively, or null if out of range.
  Coral<E?> elementAtOrNull(int index) =>
      _listCoral.map((list) => col.ListExtensions(list).elementAtOrNull(index));

  /// Contiguous slices of this list with the given [length].
  Coral<List<List<E>>> slices(int length) => _listCoral.map((list) => List<List<E>>.unmodifiable(
        col.ListExtensions(list).slices(length).map((s) => List<E>.unmodifiable(s)),
      ));
}

extension ListComparableCoralElementsExtension<E extends Comparable<dynamic>>
    on CoralListElements<E> {
  Coral<List<E>> get _listCoral => coral as Coral<List<E>>;

  /// Returns the index of [element] in this sorted list.
  Coral<int> binarySearch(E element, [int Function(E a, E b)? compare]) => _listCoral.map((list) =>
      col.ListExtensions(list).binarySearch(element, compare ?? (a, b) => a.compareTo(b)));

  /// Returns the index where [element] should be in this sorted list.
  Coral<int> lowerBound(E element, [int Function(E a, E b)? compare]) => _listCoral.map(
      (list) => col.ListExtensions(list).lowerBound(element, compare ?? (a, b) => a.compareTo(b)));

  /// Returns a new list containing a sorted range of elements from this list.
  Coral<List<E>> sortedRange(int start, int end, [int Function(E a, E b)? compare]) =>
      _listCoral.map((list) {
        final copy = list.toList();
        col.ListExtensions(copy).sortRange(start, end, compare ?? (a, b) => a.compareTo(b));
        return List<E>.unmodifiable(copy);
      });
}

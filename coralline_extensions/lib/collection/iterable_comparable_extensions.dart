// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:coralline/coralline.dart';

extension ComparableCoralElementsExtension<E extends Comparable<dynamic>>
    on CoralIterableElements<E> {
  /// Returns the minimum element in this collection, or null if empty.
  Coral<E?> get minOrNull => coral.map((source) {
        if (source.isEmpty) return null;
        return source.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
      });

  /// Returns the minimum element in this collection, or throws [StateError] if empty.
  Coral<E> get min => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
      });

  /// Returns the maximum element in this collection, or null if empty.
  Coral<E?> get maxOrNull => coral.map((source) {
        if (source.isEmpty) return null;
        return source.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      });

  /// Returns the maximum element in this collection, or throws [StateError] if empty.
  Coral<E> get max => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
      });

  /// Returns true if this collection is sorted in ascending order.
  Coral<bool> isSorted([int Function(E a, E b)? compare]) => coral.map((source) {
        if (source.length < 2) return true;
        final comp = compare ?? (a, b) => a.compareTo(b);
        var iterator = source.iterator;
        iterator.moveNext();
        var previous = iterator.current;
        while (iterator.moveNext()) {
          if (comp(previous, iterator.current) > 0) return false;
          previous = iterator.current;
        }
        return true;
      });

  /// Returns a new list containing the elements of this collection sorted in ascending order.
  Coral<List<E>> get sorted => coral.map((source) {
        return List<E>.unmodifiable(source.toList()..sort());
      });

  /// Returns a new list containing the elements of this collection sorted in descending order.
  Coral<List<E>> get sortedDescending => coral.map((source) {
        return List<E>.unmodifiable(source.toList()..sort((a, b) => b.compareTo(a)));
      });
}

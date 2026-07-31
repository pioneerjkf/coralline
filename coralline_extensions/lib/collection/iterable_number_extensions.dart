// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:coralline/coralline.dart';

extension NumericCoralElementsExtension<E extends num> on CoralIterableElements<E> {
  /// Returns the minimum element in this collection, or null if empty.
  Coral<E?> get minOrNull => coral.map((source) => source.minOrNull as E?);

  /// Returns the minimum element in this collection, or throws [StateError] if empty.
  Coral<E> get min => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.min as E;
      });

  /// Returns the maximum element in this collection, or null if empty.
  Coral<E?> get maxOrNull => coral.map((source) => source.maxOrNull as E?);

  /// Returns the maximum element in this collection, or throws [StateError] if empty.
  Coral<E> get max => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.max as E;
      });

  /// Returns the sum of the elements in this collection.
  Coral<E> get sum => coral.map((source) {
        final val = source.sum;
        if (val is E) return val;
        if (E == double) return val.toDouble() as E;
        return val.toInt() as E;
      });

  /// Returns the average of the elements in this collection.
  Coral<double> get average => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.average;
      });
}

extension IntegerCoralElementsExtension on CoralIterableElements<int> {
  /// Returns the minimum element in this collection, or null if empty.
  Coral<int?> get minOrNull => coral.map((source) => source.minOrNull);

  /// Returns the minimum element in this collection, or throws [StateError] if empty.
  Coral<int> get min => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.min;
      });

  /// Returns the maximum element in this collection, or null if empty.
  Coral<int?> get maxOrNull => coral.map((source) => source.maxOrNull);

  /// Returns the maximum element in this collection, or throws [StateError] if empty.
  Coral<int> get max => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.max;
      });

  /// Returns the sum of the elements in this collection.
  Coral<int> get sum => coral.map((source) => source.sum);

  /// Returns the average of the elements in this collection.
  Coral<double> get average => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.average;
      });
}

extension DoubleCoralElementsExtension on CoralIterableElements<double> {
  /// Returns the minimum element in this collection, or null if empty.
  Coral<double?> get minOrNull => coral.map((source) => source.minOrNull);

  /// Returns the minimum element in this collection, or throws [StateError] if empty.
  Coral<double> get min => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.min;
      });

  /// Returns the maximum element in this collection, or null if empty.
  Coral<double?> get maxOrNull => coral.map((source) => source.maxOrNull);

  /// Returns the maximum element in this collection, or throws [StateError] if empty.
  Coral<double> get max => coral.map((source) {
        if (source.isEmpty) throw StateError('No element');
        return source.max;
      });

  /// Returns the sum of the elements in this collection.
  Coral<double> get sum => coral.map((source) => source.sum);
}

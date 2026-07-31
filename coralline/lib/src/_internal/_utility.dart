// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

extension _IterableExtension<E> on Iterable<E> {
  /// **Core Concept (Identity Check):**
  /// Checks whether this iterable contains an element that is strictly identical
  /// to the given [element], comparing by physical memory address (`identical`).
  ///
  /// **Design Philosophy (Reference vs. Equality):**
  /// The standard [contains] method relies on `operator ==`, which can be
  /// overridden by subclasses and may incur heavy computational costs or
  /// trigger unintended logical equality checks. In the context of a state
  /// management engine or node graph traversal, we strictly need to verify the
  /// exact instance reference without computing user-defined equality logic.
  ///
  /// **Performance Characteristics:**
  /// Performance is bounded by O(N) using fast reference comparisons.
  bool _containsIdentical(Object? element) {
    final iterator = this.iterator;
    while (iterator.moveNext()) {
      if (identical(iterator.current, element)) return true;
    }
    return false;
  }

  /// **Core Concept (Sequential Identity Check):**
  /// Determines whether this iterable and [other] contain the exact same
  /// object references in the exact same sequential order.
  ///
  /// **Performance Optimizations:**
  /// 1. **Fast-Path:** Immediately returns `true` if `identical(this, other)`.
  /// 2. **Length Check:** If both iterables are [List]s, it validates their
  ///    `length` property (an O(1) operation) before iterating.
  /// 3. **Lock-step Iteration:** Progresses both iterators simultaneously and
  ///    short-circuits at the first mismatched reference or length discrepancy.
  ///
  /// **Design Philosophy (Zero-Dependency & Fast-Path):**
  /// This extension eliminates the need for heavyweight third-party packages
  /// (e.g., `package:collection`). It provides a zero-dependency, extremely
  /// lightweight fast-path to prevent unnecessary UI rebuilds or downstream
  /// computations when a list is re-instantiated but its constituent references
  /// remain entirely unchanged.
  bool _isSequentiallyIdentical(Iterable<E>? other) {
    if (identical(this, other)) return true;
    if (other == null) return false;
    if (this is List && other is List && length != other.length) return false;

    final iteratorA = iterator;
    final iteratorB = other.iterator;
    while (iteratorA.moveNext()) {
      if (!iteratorB.moveNext()) return false;
      if (!identical(iteratorA.current, iteratorB.current)) return false;
    }
    if (iteratorB.moveNext()) return false;
    return true;
  }
}

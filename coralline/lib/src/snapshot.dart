// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../coralline.dart';

/// **Core Concept (State Container):**
/// The base sealed class for all snapshot types, representing an immutable,
/// atomic state container at a specific point in time.
///
/// **Design Philosophy (Fail-Fast Validation):**
/// Snapshots force developers to safely check [isValid], [isEmpty], or [isDamaged]
/// before attempting to extract data. This completely eliminates NullPointerExceptions
/// and guarantees pipeline-level null safety.
@immutable
sealed class CorallineSnapshot {
  bool get isEmpty;

  bool get isDamaged;

  bool get isValid;

  Object get error;

  StackTrace get stackTrace;
}

abstract interface class CorallineSnapshotDelegator<S extends CorallineSnapshot> {
  S get snapshot;

  bool get isEmpty;

  bool get isDamaged;

  bool get isValid;

  Object get error;

  StackTrace get stackTrace;
}

/// **Core Concept (Snapshot Collection Utility):**
/// Provides convenience methods to inspect and filter an `Iterable` of [CorallineSnapshot]s.
extension CorallineSnapshotCollectionExtension<E extends CorallineSnapshot> on Iterable<E> {
  /// Returns `true` if every snapshot in this collection is in a `valid` state.
  @pragma('vm:prefer-inline')
  bool areAllValid() => every((snapshot) => snapshot.isValid);

  /// Returns `true` if at least one snapshot in this collection is in an `empty` state.
  @pragma('vm:prefer-inline')
  bool hasAnyEmpty() => any((snapshot) => snapshot.isEmpty);

  /// Returns `true` if at least one snapshot in this collection is in a `damaged` state.
  @pragma('vm:prefer-inline')
  bool hasAnyDamaged() => any((snapshot) => snapshot.isDamaged);

  /// Returns `true` if at least one snapshot in this collection is NOT in a `valid` state
  /// (i.e., either `empty` or `damaged`).
  @pragma('vm:prefer-inline')
  bool hasAnyInvalid() => any((snapshot) => !snapshot.isValid);

  /// Filters this collection, returning only the snapshots that are in an `empty` state.
  @pragma('vm:prefer-inline')
  Iterable<E> whereEmpty() => where((snapshot) => snapshot.isEmpty);

  /// Filters this collection, returning only the snapshots that are in a `damaged` state.
  @pragma('vm:prefer-inline')
  Iterable<E> whereDamaged() => where((snapshot) => snapshot.isDamaged);

  /// Filters this collection, returning only the snapshots that are NOT in a `valid` state.
  @pragma('vm:prefer-inline')
  Iterable<E> whereInvalid() => where((snapshot) => !snapshot.isValid);
}

/// **Core Concept (Delegator Collection Utility):**
/// Provides convenience methods to inspect and filter an `Iterable` of objects that
/// implement [CorallineSnapshotDelegator] (such as `Coral` or `Trunk`).
extension CorallineSnapshotDelegatorCollectionExtension<E extends CorallineSnapshotDelegator> on Iterable<E> {
  /// Returns `true` if every delegator in this collection is in a `valid` state.
  @pragma('vm:prefer-inline')
  bool areAllValid() => every((coral) => coral.isValid);

  /// Returns `true` if at least one delegator in this collection is in an `empty` state.
  @pragma('vm:prefer-inline')
  bool hasAnyEmpty() => any((coral) => coral.isEmpty);

  /// Returns `true` if at least one delegator in this collection is in a `damaged` state.
  @pragma('vm:prefer-inline')
  bool hasAnyDamaged() => any((coral) => coral.isDamaged);

  /// Returns `true` if at least one delegator in this collection is NOT in a `valid` state.
  @pragma('vm:prefer-inline')
  bool hasAnyInvalid() => any((coral) => !coral.isValid);

  /// Filters this collection, returning only the delegators that are in an `empty` state.
  @pragma('vm:prefer-inline')
  Iterable<E> whereEmpty() => where((coral) => coral.isEmpty);

  /// Filters this collection, returning only the delegators that are in a `damaged` state.
  @pragma('vm:prefer-inline')
  Iterable<E> whereDamaged() => where((coral) => coral.isDamaged);

  /// Filters this collection, returning only the delegators that are NOT in a `valid` state.
  @pragma('vm:prefer-inline')
  Iterable<E> whereInvalid() => where((coral) => !coral.isValid);
}

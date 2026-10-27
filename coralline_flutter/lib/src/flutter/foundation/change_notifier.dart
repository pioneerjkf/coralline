// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../foundation.dart';

/// A convenience extension that bridges Flutter's [ValueListenable] with the Coralline pipeline.
///
/// This extension enables any [ValueListenable] (such as [ValueNotifier]) to be converted
/// into a reactive [Coral] node, integrating Flutter's change-notification system
/// into the declarative topology of Coralline.
///
/// ## Architecture & Lifecycle Pipe Diagram
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │         ValueListenableCoralExtension (Pipe Flow)      │
/// └────────────────────────────────────────────────────────┘
///       │
///       ▼ .toCoral()
/// [ValueListenable<T>] ──> [_ValueListenableCoralPipe<T>]
///                                   │
///                        [CoralController.lateLifecycle]
///                                   │
///             ┌─────────────────────┴─────────────────────┐
///             ▼ onActivated()                             ▼ onDeactivated()
///      addListener(_listen)                        removeListener(_listen)
///             │
///             ▼ emit value
///         [Coral<T>]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Lazy Subscription Binding**: Registration of the [ValueListenable] listener is deferred
///    until the returned [Coral] node is actually observed by an active subscriber.
/// 2. **Automatic Teardown Cleanliness**: When all downstream consumers deactivate, the listener
///    is detached automatically via [CoralController.lateLifecycle], preventing memory leaks.
/// 3. **Change Deduping**: By default (`distinct: true`), consecutive duplicate values emitted
///    by the notifier are dropped, optimizing downstream computation cycles.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Avoid creating multiple distinct [Coral] nodes for the same [ValueListenable] inside build
///   methods; cache the derived [Coral] node as a field or parameter.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Invoking toCoral() repeatedly in build creates redundant pipe nodes
/// Widget buildCounter(ValueNotifier<int> notifier) {
///   final coral = notifier.toCoral(); // Recreates pipe on every build pass!
///   return Text('Value: ${coral.data}');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Cache the converted Coral node in a long-lived field or component
/// class CounterDisplay {
///   CounterDisplay(ValueNotifier<int> notifier)
///       : counterCoral = notifier.toCoral();
///
///   final Coral<int> counterCoral;
/// }
/// ```
extension ValueListenableCoralExtension<T> on ValueListenable<T> {
  /// Converts this [ValueListenable] into a reactive [Coral] node.
  ///
  /// The listener registration is deferred until the returned [Coral] node is activated,
  /// and is automatically cleaned up when the node is deactivated.
  ///
  /// * [distinct]: If `true`, ignores duplicate consecutive values. Defaults to `true`.
  /// * [equals]: An optional custom equality function to compare the previous and next values
  ///   when [distinct] is enabled.
  ///
  /// **Ensures:**
  /// * Returns a [Coral] node that reflects the values of this [ValueListenable].
  /// * Subscribes to the [ValueListenable] on activation, and unsubscribes on deactivation.
  ///
  /// **Example:**
  /// ```dart
  /// final counterNotifier = ValueNotifier<int>(0);
  /// final counterCoral = counterNotifier.toCoral();
  ///
  /// // The coral now reactively mirrors the notifier's value.
  /// counterNotifier.value = 1;
  /// ```
  Coral<T> toCoral(
          {bool distinct = true, bool Function(T previous, T next)? equals}) =>
      _ValueListenableCoralPipe<T>(this, distinct: distinct, equals: equals)
          .coral;
}

/// An internal bridge adapter binding a [ValueListenable] to a [CoralController.lateLifecycle].
final class _ValueListenableCoralPipe<T> {
  _ValueListenableCoralPipe(
    ValueListenable<T> listenable, {
    bool distinct = true,
    bool Function(T previous, T next)? equals,
  }) : _listenable = listenable {
    _controller = CoralController.lateLifecycle(
      distinct: distinct,
      equals: equals,
      onActivated: _onActivate,
      onDeactivated: _onDeactivate,
    );
  }

  final ValueListenable<T> _listenable;

  late final CoralController<T> _controller;

  void _onActivate() {
    _controller.set(_listenable.value);
    _listenable.addListener(_listen);
  }

  void _onDeactivate() {
    _listenable.removeListener(_listen);
  }

  void _listen() {
    _controller.set(_listenable.value);
  }

  /// The downstream [Coral] node that reflects the value of the upstream listenable.
  Coral<T> get coral => _controller.coral;
}

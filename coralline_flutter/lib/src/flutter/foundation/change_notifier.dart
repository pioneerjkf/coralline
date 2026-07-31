// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../foundation.dart';

/// A convenience extension that bridges Flutter's [ValueListenable] with the Coralline pipeline.
///
/// This extension enables any [ValueListenable] (such as [ValueNotifier]) to be converted
/// into a reactive [Coral] node, integrating Flutter's change-notification system
/// into the declarative topology of Coralline.
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

  Coral<T> get coral => _controller.coral;
}

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../material.dart';

/// **Core Concept (Scaffold Proxy):**
/// A dedicated proxy wrapper for [Coral<BuildContext>] to access [ScaffoldMessengerState]
/// and ancestor [ScaffoldState] reactively.
extension type CoralBuildContextScaffoldProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the nearest [ScaffoldMessengerState].
  ///
  /// **Ensures:**
  /// * Emits active [ScaffoldMessengerState].
  Coral<ScaffoldMessengerState> get messenger =>
      _coral.map((e) => ScaffoldMessenger.of(e)).distinct();

  /// Reactively observes the nearest ancestor [ScaffoldState] if present.
  ///
  /// **Ensures:**
  /// * Emits nearest ancestor [ScaffoldState] or `null`.
  Coral<ScaffoldState?> get state => _coral.map((e) => Scaffold.maybeOf(e)).distinct();
}

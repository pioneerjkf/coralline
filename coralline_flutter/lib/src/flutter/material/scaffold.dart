// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../material.dart';

/// A proxy wrapper for [Coral<BuildContext>] to access [ScaffoldMessengerState] and ancestor [ScaffoldState] reactively.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │             CoralBuildContextScaffoldProxy             │
/// └────────────────────────────────────────────────────────┘
///               │                           │
///               ▼ [.messenger]              ▼ [.state]
///      ScaffoldMessenger.of()          Scaffold.maybeOf()
///               │                           │
///               ▼                           ▼
///     [ScaffoldMessengerState]            [ScaffoldState?]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Nullable Ancestor Safety**: Uses `Scaffold.maybeOf` for [state] to avoid runtime exceptions
///    when rendering outside of an ancestor [Scaffold].
/// 2. **Notification Isolation**: Distinct mappings ensure consumers only update when the resolved
///    scaffold state reference changes.
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
  Coral<ScaffoldState?> get state =>
      _coral.map((e) => Scaffold.maybeOf(e)).distinct();
}

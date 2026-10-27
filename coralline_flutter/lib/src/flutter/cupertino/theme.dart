// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../cupertino.dart';

/// A proxy wrapper for [Coral<BuildContext>] to access Flutter [CupertinoThemeData], [CupertinoTextThemeData], colors, and brightness reactively.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │         CoralBuildContextCupertinoThemeProxy           │
/// └────────────────────────────────────────────────────────┘
///       │                   │                   │
///       ▼ [.data]           ▼ [.primaryColor]   ▼ [.brightness]
/// CupertinoTheme.of() CupertinoTheme.of().primary CupertinoTheme.brightnessOf()
///       │                   │                   │
///       ▼                   ▼                   ▼
/// [CupertinoThemeData]    [Color]              [Brightness]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Atomic Cupertino Token Observers**: Allows selective subscriptions to brightness or
///    individual color tokens without re-evaluating the parent container widget.
/// 2. **Deduplicated Property Stream**: Every property stream is equipped with `.distinct()` to
///    suppress downstream updates when token values are identical.
extension type CoralBuildContextCupertinoThemeProxy._(
    Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the current [CupertinoThemeData].
  ///
  /// **Ensures:**
  /// * Emits updated [CupertinoThemeData] whenever theme configuration changes.
  Coral<CupertinoThemeData> get data =>
      _coral.map((e) => CupertinoTheme.of(e)).distinct();

  /// Reactively observes the current primary color.
  Coral<Color> get primaryColor =>
      _coral.map((e) => CupertinoTheme.of(e).primaryColor).distinct();

  /// Reactively observes the current primary contrasting color.
  Coral<Color> get primaryContrastingColor => _coral
      .map((e) => CupertinoTheme.of(e).primaryContrastingColor)
      .distinct();

  /// Reactively observes the current navigation bar background color.
  Coral<Color> get barBackgroundColor =>
      _coral.map((e) => CupertinoTheme.of(e).barBackgroundColor).distinct();

  /// Reactively observes the current scaffold background color.
  Coral<Color> get scaffoldBackgroundColor => _coral
      .map((e) => CupertinoTheme.of(e).scaffoldBackgroundColor)
      .distinct();

  /// Reactively observes the current [CupertinoTextThemeData].
  Coral<CupertinoTextThemeData> get textTheme =>
      _coral.map((e) => CupertinoTheme.of(e).textTheme).distinct();

  /// Reactively observes the current brightness.
  Coral<Brightness> get brightness =>
      _coral.map((e) => CupertinoTheme.brightnessOf(e)).distinct();
}

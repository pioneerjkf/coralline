// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../material.dart';

/// A proxy wrapper for [Coral<BuildContext>] to access Flutter [ThemeData], [ColorScheme], [TextTheme], and [IconThemeData] reactively.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │              CoralBuildContextThemeProxy               │
/// └────────────────────────────────────────────────────────┘
///       │                  │                  │
///       ▼ [.data]          ▼ [.colorScheme]   ▼ [.textTheme]
///   Theme.of(e)       Theme.of(e).colorScheme Theme.of(e).textTheme
///       │                  │                  │
///       ▼                  ▼                  ▼
///  [ThemeData]        [ColorScheme]       [TextTheme]
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Atomic Token Selection**: Observing [colorScheme] or [textTheme] allows fine-grained
///    subscription without exposing raw widget trees to bulk theme rebuild passes.
/// 2. **Distinct Output Caching**: All mapped outputs are chained with `.distinct()` to prevent
///    redundant dirty notifications if theme values do not change.
extension type CoralBuildContextThemeProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the current [ThemeData].
  ///
  /// **Ensures:**
  /// * Emits updated [ThemeData] whenever theme configuration changes.
  ///
  /// **Implementation note:**
  /// Always cache derived line nodes as `late final` fields to prevent dormant access errors.
  Coral<ThemeData> get data => _coral.map((e) => Theme.of(e)).distinct();

  /// Reactively observes the current [ColorScheme].
  ///
  /// **Ensures:**
  /// * Emits updated [ColorScheme] derived from the active theme.
  ///
  /// **Implementation note:**
  /// Always cache derived line nodes as `late final` fields to prevent dormant access errors.
  Coral<ColorScheme> get colorScheme =>
      _coral.map((e) => Theme.of(e).colorScheme).distinct();

  /// Reactively observes the current [TextTheme].
  ///
  /// **Ensures:**
  /// * Emits updated [TextTheme] derived from the active theme.
  ///
  /// **Implementation note:**
  /// Always cache derived line nodes as `late final` fields to prevent dormant access errors.
  Coral<TextTheme> get textTheme =>
      _coral.map((e) => Theme.of(e).textTheme).distinct();

  /// Reactively observes the current [IconThemeData].
  ///
  /// **Ensures:**
  /// * Emits updated [IconThemeData] derived from the active element context.
  Coral<IconThemeData> get iconTheme =>
      _coral.map((e) => IconTheme.of(e)).distinct();
}

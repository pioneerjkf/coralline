// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../material.dart';

/// **Core Concept (Theme Proxy):**
/// A dedicated proxy wrapper for [Coral<BuildContext>] to access Flutter [ThemeData],
/// [ColorScheme], [TextTheme], and [IconThemeData] reactively.
extension type CoralBuildContextThemeProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Reactively observes the current [ThemeData].
  ///
  /// **Ensures:**
  /// * Emits updated [ThemeData] whenever theme configuration changes.
  ///
  /// **AI & Developer Note:**
  /// Always cache derived line nodes as `late final` fields to prevent dormant access errors.
  Coral<ThemeData> get data => _coral.map((e) => Theme.of(e)).distinct();

  /// Reactively observes the current [ColorScheme].
  ///
  /// **Ensures:**
  /// * Emits updated [ColorScheme] derived from the active theme.
  ///
  /// **AI & Developer Note:**
  /// Always cache derived line nodes as `late final` fields to prevent dormant access errors.
  Coral<ColorScheme> get colorScheme => _coral.map((e) => Theme.of(e).colorScheme).distinct();

  /// Reactively observes the current [TextTheme].
  ///
  /// **Ensures:**
  /// * Emits updated [TextTheme] derived from the active theme.
  ///
  /// **AI & Developer Note:**
  /// Always cache derived line nodes as `late final` fields to prevent dormant access errors.
  Coral<TextTheme> get textTheme => _coral.map((e) => Theme.of(e).textTheme).distinct();

  /// Reactively observes the current [IconThemeData].
  ///
  /// **Ensures:**
  /// * Emits updated [IconThemeData] derived from the active element context.
  Coral<IconThemeData> get iconTheme => _coral.map((e) => IconTheme.of(e)).distinct();
}

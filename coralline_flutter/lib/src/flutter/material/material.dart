// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../material.dart';

/// Opens a dedicated namespace on [Coral<BuildContext>] for Material Design components.
extension CoralBuildContextMaterialExtension on Coral<BuildContext> {
  /// Opens a dedicated namespace for Material design tokens and scope controllers reactively.
  CoralBuildContextMaterialProxy get material => CoralBuildContextMaterialProxy._(this);
}

/// **Core Concept (Material Proxy):**
/// Root proxy wrapper providing access to Material Theme, ColorScheme, TextTheme, and Scaffold scopes.
extension type CoralBuildContextMaterialProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Opens the [CoralBuildContextThemeProxy] namespace for Material theme tokens.
  CoralBuildContextThemeProxy get theme => CoralBuildContextThemeProxy._(_coral);

  /// Opens the [CoralBuildContextScaffoldProxy] namespace for Scaffold scopes.
  CoralBuildContextScaffoldProxy get scaffold => CoralBuildContextScaffoldProxy._(_coral);

  /// Reactively observes the current [ColorScheme] shortcut.
  Coral<ColorScheme> get colorScheme => theme.colorScheme;

  /// Reactively observes the current [TextTheme] shortcut.
  Coral<TextTheme> get textTheme => theme.textTheme;

  /// Reactively observes the nearest [ScaffoldMessengerState] shortcut.
  Coral<ScaffoldMessengerState> get scaffoldMessenger => scaffold.messenger;
}

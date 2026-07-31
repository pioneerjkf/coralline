// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../cupertino.dart';

/// Opens a dedicated namespace on [Coral<BuildContext>] for Cupertino components.
extension CoralBuildContextCupertinoExtension on Coral<BuildContext> {
  /// Opens a dedicated namespace for Cupertino design tokens and controllers reactively.
  CoralBuildContextCupertinoProxy get cupertino =>
      CoralBuildContextCupertinoProxy._(this);
}

/// **Core Concept (Cupertino Proxy):**
/// Root proxy wrapper providing access to Cupertino Theme, TextTheme, colors, and user interface level.
extension type CoralBuildContextCupertinoProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Opens the [CoralBuildContextCupertinoThemeProxy] namespace for Cupertino theme tokens.
  CoralBuildContextCupertinoThemeProxy get theme =>
      CoralBuildContextCupertinoThemeProxy._(_coral);

  /// Reactively observes the current [CupertinoThemeData] shortcut.
  Coral<CupertinoThemeData> get themeData => theme.data;

  /// Reactively observes the current primary color shortcut.
  Coral<Color> get primaryColor => theme.primaryColor;

  /// Reactively observes the current [CupertinoTextThemeData] shortcut.
  Coral<CupertinoTextThemeData> get textTheme => theme.textTheme;

  /// Reactively observes the current navigation bar background color shortcut.
  Coral<Color> get barBackgroundColor => theme.barBackgroundColor;

  /// Reactively observes the current scaffold background color shortcut.
  Coral<Color> get scaffoldBackgroundColor => theme.scaffoldBackgroundColor;

  /// Reactively observes the current ancestor [CupertinoUserInterfaceLevelData] if present.
  Coral<CupertinoUserInterfaceLevelData?> get userInterfaceLevel =>
      _coral.map((e) => CupertinoUserInterfaceLevel.maybeOf(e)).distinct();
}

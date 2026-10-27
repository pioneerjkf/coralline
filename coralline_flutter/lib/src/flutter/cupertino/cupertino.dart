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

/// A proxy wrapper providing access to Cupertino Theme, TextTheme, colors, and user interface level.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │            CoralBuildContextCupertinoProxy             │
/// └────────────────────────────────────────────────────────┘
///       │                                  │
///       ▼ [.theme]                         ▼ [.userInterfaceLevel]
/// [CoralBuildContextCupertinoThemeProxy]  CupertinoUserInterfaceLevel.maybeOf(e)
///       │
///       ├─► .primaryColor
///       ├─► .textTheme
///       ├─► .barBackgroundColor
///       └─► .scaffoldBackgroundColor
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Structured Namespacing**: Isolates Cupertino-specific token streams within a dedicated proxy
///    to avoid polluting the core [Coral<BuildContext>] namespace.
/// 2. **Deduplicated Property Propagation**: Each accessor filters unchanged values via `.distinct()`.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Avoid accessing proxy properties on every rebuild pass without caching;
///   cache derived proxy streams as `late final` fields in components.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Reading Cupertino theme proxy dynamically in build without caching
/// Widget render(Coral<BuildContext> contextCoral) {
///   return Text('Color: ${contextCoral.cupertino.primaryColor.data}');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Cache Cupertino proxy stream as a late final field
/// class CupertinoCardComponent {
///   CupertinoCardComponent(Coral<BuildContext> contextCoral)
///       : primaryColor = contextCoral.cupertino.primaryColor;
///
///   final Coral<Color> primaryColor;
/// }
/// ```
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

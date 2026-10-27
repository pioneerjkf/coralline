// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../../material.dart';

/// Opens a dedicated namespace on [Coral<BuildContext>] for Material Design components.
extension CoralBuildContextMaterialExtension on Coral<BuildContext> {
  /// Opens a dedicated namespace for Material design tokens and scope controllers reactively.
  CoralBuildContextMaterialProxy get material =>
      CoralBuildContextMaterialProxy._(this);
}

/// A proxy wrapper providing access to Material Theme, ColorScheme, TextTheme, and Scaffold scopes.
///
/// ## Sub-Functor & Invocation Pathways
/// ```text
/// ┌────────────────────────────────────────────────────────┐
/// │             CoralBuildContextMaterialProxy             │
/// └────────────────────────────────────────────────────────┘
///       │                           │
///       ▼ [.theme]                  ▼ [.scaffold]
/// [CoralBuildContextThemeProxy]    [CoralBuildContextScaffoldProxy]
///       │                           │
///       ├─► .colorScheme            ├─► .messenger
///       └─► .textTheme              └─► .state
/// ```
///
/// ## Key Invariants & Architectural Benefits
/// 1. **Structured Namespacing**: Prevents polluting Flutter's [Coral<BuildContext>] namespace with
///    hundreds of flat getters while grouping related tokens logically.
/// 2. **Subtree Scoping**: Efficiently extracts Material tokens without requiring manual
///    `Theme.of(context)` calls in component build methods.
///
/// **Warning (Anti-Pattern Prevention):**
/// - Avoid reading Material proxy tokens in loops without caching;
///   cache derived proxy streams as `late final` fields in components.
///
/// **BAD:**
/// ```dart
/// // [Anti-Pattern] Ad-hoc reading of theme tokens on every build pass
/// Widget render(Coral<BuildContext> contextCoral) {
///   return Text('Color: ${contextCoral.material.colorScheme.data.primary}');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // [Recommended] Cache theme proxy stream as a late final field
/// class ThemedCardComponent {
///   ThemedCardComponent(Coral<BuildContext> contextCoral)
///       : colors = contextCoral.material.colorScheme;
///
///   final Coral<ColorScheme> colors;
/// }
/// ```
extension type CoralBuildContextMaterialProxy._(Coral<BuildContext> _coral) {
  /// Exposes the underlying [Coral<BuildContext>] node.
  Coral<BuildContext> get context => _coral;

  /// Opens the [CoralBuildContextThemeProxy] namespace for Material theme tokens.
  CoralBuildContextThemeProxy get theme =>
      CoralBuildContextThemeProxy._(_coral);

  /// Opens the [CoralBuildContextScaffoldProxy] namespace for Scaffold scopes.
  CoralBuildContextScaffoldProxy get scaffold =>
      CoralBuildContextScaffoldProxy._(_coral);

  /// Reactively observes the current [ColorScheme] shortcut.
  Coral<ColorScheme> get colorScheme => theme.colorScheme;

  /// Reactively observes the current [TextTheme] shortcut.
  Coral<TextTheme> get textTheme => theme.textTheme;

  /// Reactively observes the nearest [ScaffoldMessengerState] shortcut.
  Coral<ScaffoldMessengerState> get scaffoldMessenger => scaffold.messenger;
}

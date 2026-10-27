// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'package:coralline_flutter/animation.dart';
/// @docImport 'package:coralline_flutter/foundation.dart';
/// @docImport 'package:coralline_flutter/scheduler.dart';
/// @docImport 'package:coralline_flutter/widgets.dart';
///
/// Flutter integration library for the Coralline reactive state management framework.
///
/// Bridges pure Dart Coralline reactive pipelines with Flutter's element tree
/// using a Push-Dirty, Pull-Data execution model.
///
/// ## System Architectural Flow
/// ```text
/// [Coralline Pipeline] ──> Push Dirty Signal ──> [CoralWidgetElement]
///                                                      │
///                                                      └── Lazy Pull on Next Frame ──> [Widget Tree]
/// ```
///
/// ## Core Subsystems
/// - **UI Components**: [SimplexBuildComponent], [BuildComponent], [CoralWidget] in `widgets.dart`.
/// - **Context Awareness**: [CorallineBuildContextAware], [InheritedCoralProviderWidget] in `widgets.dart`.
/// - **Lifecycle & Animation**: [ResilientAnimationController], [TickerProviderCorallineLifecycleAwareMixin] in `animation.dart` and `scheduler.dart`.
/// - **Foundation Adapters**: [ValueListenableCoralExtension] in `foundation.dart`.
library;

export 'package:coralline/coralline.dart';
export 'package:coralline_flutter/animation.dart';
export 'package:coralline_flutter/foundation.dart';
export 'package:coralline_flutter/scheduler.dart';
export 'package:coralline_flutter/widgets.dart';

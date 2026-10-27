// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
///
/// Declarative Flutter widgets and context-aware reactive computation components.
///
/// Provides [SimplexBuildComponent] (1:1), [BuildComponent] (N:1), [CoralWidget],
/// [CorallineBuildContextAware], and [InheritedCoralProviderWidget].
library;

import 'dart:async';

import 'package:coralline/coralline.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

export 'package:coralline_flutter/foundation.dart';
export 'package:coralline_flutter/scheduler.dart';

part 'src/flutter/widgets/extension.dart';
part 'src/flutter/widgets/framework.dart';

const String _libraryName = 'coralline_flutter';

// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
///
/// Material Design extensions and reactive proxies for Coralline.
///
/// Exposes reactive access to [ThemeData], [ColorScheme], [TextTheme],
/// and [ScaffoldMessengerState] through `context.material`.
library;

import 'package:coralline/coralline.dart';
import 'package:flutter/material.dart';

export 'package:coralline_flutter/widgets.dart';

part 'src/flutter/material/material.dart';
part 'src/flutter/material/scaffold.dart';
part 'src/flutter/material/theme.dart';

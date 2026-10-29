// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

/// Reactive `package:collection`-backed operators for [CoralIterableElements] and [CoralListElements].
///
/// Provides unmodifiable, lazy pull-evaluated collection extensions for comparable,
/// general iterable, numeric, and list elements within a Coralline topology.
library;

import 'package:coralline/coralline.dart';

export 'collection/iterable_comparable_extensions.dart';
export 'collection/iterable_extensions.dart';
export 'collection/iterable_number_extensions.dart';
export 'collection/list_extensions.dart';

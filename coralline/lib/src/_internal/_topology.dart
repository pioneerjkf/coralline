// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

/// An interface for debugging and validating the structural topology of the CORAL reactive graph.
abstract interface class _CorallineTopology {
  Iterable<_CorallineTopology> _debugIterateDownstream();
}

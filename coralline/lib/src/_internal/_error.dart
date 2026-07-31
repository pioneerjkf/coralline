// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

/// An interface for handling exceptions that occur during internal framework operations.
/// This acts as a generic error sink for lifecycle transitions, topology changes,
/// reactivity propagation, and user callbacks to prevent the framework core from crashing.
abstract interface class _CorallineErrorSink {
  void _handleUncaughtError(Object error, StackTrace stackTrace);
}

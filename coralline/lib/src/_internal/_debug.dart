// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

final _debugTags = Expando<String>();
final _debugLocations = Expando<String>();

void _captureDebugTrace(Object target, String? tag, int traceCount) {
  assert(() {
    if (tag != null) _debugTags[target] = tag;
    try {
      final fullTrace = StackTrace.current.toString().split('\n');
      if (fullTrace.length > 2) {
        // skip(2) to bypass `_captureDebugTrace` AND the `debugTrace` caller.
        _debugLocations[target] = fullTrace.skip(2).take(traceCount).join('\n');
      }
    } catch (_) {}
    return true;
  }());
}

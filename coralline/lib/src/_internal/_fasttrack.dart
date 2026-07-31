// Copyright 2023-2026 Youngjune Jeon All rights reserved.
// Use of this source code is governed by an Apache 2.0 license that can be
// found in the LICENSE file.

part of '../../coralline.dart';

base mixin _CorallineFasttrack {
  _Joint? get _joint;

  _ClearancePoint? _clearancePoint;

  @mustCallSuper
  @pragma('vm:prefer-inline')
  bool _rerouteClearancePoint() {
    final oldClearance = _clearancePoint;
    final newClearance = _joint?._resolveClearancePoint();
    if (identical(oldClearance, newClearance)) return false;
    _clearancePoint = newClearance;
    _didRerouteClearancePoint(oldClearance: oldClearance, newClearance: _clearancePoint);
    return true;
  }

  @mustCallSuper
  void _didRerouteClearancePoint({_ClearancePoint? oldClearance, _ClearancePoint? newClearance});

  CorallineTerminalIntent? _terminalIntent;

  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _updateTerminalIntent() {
    final oldIntent = _terminalIntent;
    final newIntent = _joint?._resolveTerminalIntent();
    if (identical(oldIntent, newIntent)) return;
    _propagateTerminalIntent(oldIntent: oldIntent, newIntent: newIntent);
  }

  @mustCallSuper
  @pragma('vm:prefer-inline')
  void _propagateTerminalIntent({CorallineTerminalIntent? oldIntent, CorallineTerminalIntent? newIntent}) {
    _terminalIntent = newIntent;
  }
}

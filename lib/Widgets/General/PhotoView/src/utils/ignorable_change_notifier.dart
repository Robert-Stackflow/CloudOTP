/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that has a second collection of listeners: the ignorable ones
///
/// Those listeners will be fired when [notifyListeners] fires and will be ignored
/// when [notifySomeListeners] fires.
///
/// The common collection of listeners inherited from [ChangeNotifier] will be fired
/// every time.
class IgnorableChangeNotifier extends ChangeNotifier {
  ObserverList<VoidCallback>? _ignorableListeners =
      ObserverList<VoidCallback>();

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_ignorableListeners == null) {
        AssertionError([
          'A $runtimeType was used after being disposed.',
          'Once you have called dispose() on a $runtimeType, it can no longer be used.'
        ]);
      }
      return true;
    }());
    return true;
  }

  @override
  bool get hasListeners {
    return super.hasListeners || (_ignorableListeners?.isNotEmpty ?? false);
  }

  void addIgnorableListener(listener) {
    assert(_debugAssertNotDisposed());
    _ignorableListeners!.add(listener);
  }

  void removeIgnorableListener(listener) {
    assert(_debugAssertNotDisposed());
    _ignorableListeners!.remove(listener);
  }

  @override
  void dispose() {
    _ignorableListeners = null;
    super.dispose();
  }

  @protected
  @override
  @visibleForTesting
  void notifyListeners() {
    super.notifyListeners();
    if (_ignorableListeners != null) {
      final List<VoidCallback> localListeners =
          List<VoidCallback>.from(_ignorableListeners!);
      for (VoidCallback listener in localListeners) {
        try {
          if (_ignorableListeners!.contains(listener)) {
            listener();
          }
        } catch (exception, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: exception,
              stack: stack,
              library: 'Photoview library',
            ),
          );
        }
      }
    }
  }

  /// Ignores the ignoreables
  @protected
  void notifySomeListeners() {
    super.notifyListeners();
  }
}

/// Just like [ValueNotifier] except it extends [IgnorableChangeNotifier] which has
/// listeners that wont fire when [updateIgnoring] is called.
class IgnorableValueNotifier<T> extends IgnorableChangeNotifier
    implements ValueListenable<T> {
  IgnorableValueNotifier(this._value);

  @override
  T get value => _value;
  T _value;

  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  void updateIgnoring(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifySomeListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

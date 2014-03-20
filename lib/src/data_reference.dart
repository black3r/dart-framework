// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Observable object, which represents single primitive in Data.
 *
 */
class DataReference<V> extends Object with ChangeNotificationsMixin, ChangeValueNotificationsMixin{

  /**
   * Encapsulated value
   */
  V _value;

  StreamSubscription _onDataChangeListener, _onDataChangeSyncListener;

  /**
   * Return value of a primitive type.
   */
  V get value => _value;

  /**
   * Change value of primitive type and notify listeners.
   */
  set value(V newValue) {
    changeValue(newValue);
  }

  _silentChangeValue(V newValue){
    assert(newValue is! DataReference);
    _value = newValue;

    if(_onDataChangeListener != null) {
      _onDataChangeListener.cancel();
      _onDataChangeListener = null;
    }
    if(_onDataChangeSyncListener != null) {
      _onDataChangeSyncListener.cancel();
      _onDataChangeSyncListener = null;
    }

    if(newValue is ChangeNotificationsMixin) {
      _onDataChangeSyncListener = newValue.onChangeSync.listen((changeEvent) {
        _onChangeSyncController.add(changeEvent);
      });
      _onDataChangeListener = newValue.onChange.listen((changeEvent) {
        // due to its lazy initialization, _onChangeController does not need to
        // exist; if not ignore the change, no one is listening!
        if (_onChangeController != null) {
          _onChangeController.add(changeEvent);
        }
      });
    }

  }

  changeValue(V newValue, {author: null}) {
    _markChanged(this._value, newValue);
    _silentChangeValue(newValue);
    _notify(author: author);
  }

  /**
   * Creates new DataReference with [value]
   */
  DataReference(V value) {
    _silentChangeValue(value);
    _clearChanges();
    _clearChangesSync();
  }

  void dispose() {
    _dispose();
    if (_onDataChangeListener != null) {
      _onDataChangeListener.cancel();
    }
    if (_onDataChangeSyncListener != null) {
      _onDataChangeSyncListener.cancel();
    }

  }

  String toString() => 'Ref(${_value.toString()})';
}
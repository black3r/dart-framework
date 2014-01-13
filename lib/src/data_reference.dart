// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Observable object, which represents single primitive in Data.
 *
 */
class DataReference extends Object with ChangeNotificationsMixin, ChangeValueNotificationsMixin{

  /**
   * Encapsulated value
   */
  dynamic _value;

  StreamSubscription _onDataChangeListener, _onDataChangeSyncListener;

  /**
   * Return value of a primitive type.
   */
  get value => _value;

  /**
   * Change value of primitive type and notify listeners.
   */
  set value(newValue) {
    changeValue(newValue);
  }

  changeValue(newValue, {author: null}) {
    _markChanged(this, this);
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
        _onChangeController.add(changeEvent);
      });

    }

    _notify(author: author);
  }

  /**
   * Creates new DataReference with [value]
   */
  DataReference(value) {
    changeValue(value);
    _clearChanges();
    _clearChangesSync();
  }

  String toString() => 'Ref(${_value.toString()})';
}
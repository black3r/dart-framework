// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Observable object, which represents single primitive in Data.
 *
 */
class DataReference extends Object with ChangeNotificationsMixin{

  /**
   * Encapsulated value
   */
  dynamic _value;
  StreamSubscription _onDataChangeListener, _onDataChangeSyncListener, _onBeforeAddedListener, _onBeforeRemovedListener;
  
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
    _value = newValue;
    
    Change change = new Change(_value, newValue);
    _onChangeController.add(change);
    _onChangeSyncController.add(change);
   
    _clearChangesSync();
    _clearChanges();
    
    if(_onDataChangeListener != null) {
      _onDataChangeListener.cancel();
      _onDataChangeListener = null;
    }
    if(_onDataChangeSyncListener != null) {
      _onDataChangeSyncListener.cancel();
      _onDataChangeSyncListener = null;
    }
    if(_onBeforeAddedListener != null) {
      _onBeforeAddedListener.cancel();
      _onBeforeAddedListener = null;
    }
    if(_onBeforeRemovedListener != null) {
      _onBeforeRemovedListener.cancel();
      _onBeforeRemovedListener = null;
    }
    
    if(value is ChangeNotificationsMixin) {
      _onDataChangeSyncListener = newValue.onChangeSync.listen((changeEvent) {
        _onChangeSyncController.add(changeEvent);
      });
      _onDataChangeListener = newValue.onChange.listen((changeEvent) {
        _onChangeController.add(changeEvent);
      });
      _onBeforeAddedListener = newValue.onBeforeAdd.listen((changeEvent) {
        _onBeforeAddedController.add(changeEvent);
      });
      _onBeforeRemovedListener = newValue.onBeforeRemove.listen((changeEvent) {
        _onBeforeRemovedController.add(changeEvent);
      });
    }
  }

  /**
   * Creates new DataReference with [value]
   */
  DataReference(value) { 
    changeValue(value);
  }

  String toString() => _value.toString();
}
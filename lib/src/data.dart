// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class DataView {

  /**
   * Returns the value for the given key or null if key is not in the data object.
   * Because null values are supported, one should use containsKey to
   * distinguish between an absent key and a null value.
   */
  dynamic operator[](key);

  /**
   * Stream populated with [ChangeSet] events whenever the data gets changed.
   */
  Stream<ChangeSet> get onChange;

  /**
   * Returns true if there is no {key, value} pair in the data object.
   */
  bool get isEmpty;

  /**
   * Returns true if there is at least one {key, value} pair in the data object.
   */
  bool get isNotEmpty;

  /**
   * The keys of data object.
   */
  Iterable get keys;

  /**
   * The values of [Data].
   */
  Iterable get values;

  /**
   * The number of {key, value} pairs in the [Data].
   */
  int get length;

  /**
   * Returns whether this data object contains the given [key].
   */
  bool containsKey(String key);
  
  Map toMap();
}


abstract class DataViewMixin implements DataView {

  final Map _fields = new Map();

  dynamic operator[](key) => _fields[key];

  ChangeSet _changeSet = new ChangeSet();

  final StreamController<ChangeSet> _onChangeController =
      new StreamController<ChangeSet>.broadcast();

  Stream<ChangeSet> get onChange => _onChangeController.stream;

  bool get isEmpty {
    return _fields.isEmpty;
  }

  bool get isNotEmpty {
    return _fields.isNotEmpty;
  }

  Iterable get keys {
    return _fields.keys;
  }

  Iterable get values {
    return _fields.values;
  }

  int get length {
    return _fields.length;
  }

  bool containsKey(String key) {
    return _fields.containsKey(key);
  }

  /**
   * Streams all new changes marked in [changeSet].
   */
  void _notify() {
    Timer.run(() {
      if(!_changeSet.isEmpty) {
        _onChangeController.add(_changeSet);
        _clearChanges();
      }
    });
  }

  _clearChanges() {
    _changeSet = new ChangeSet();
  }

  Map toMap() => _fields;
}

/**
 * A representation for a single unit of structured data.
 */
class Data extends Object with DataViewMixin implements DataView {

  /**
   * Creates an empty data object.
   */
  Data();

  /**
   * Creates a new data object from key-value pairs [data].
   */
  factory Data.fromMap(Map data) {
    var dataObj = new Data();
    data.forEach((k, v) => dataObj[k] = v);
    dataObj._clearChanges();
    return dataObj;
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void operator[]=(String key, value) {
    if (_fields.containsKey(key)) {
      _changeSet.markChanged(key, new Change(_fields[key], value));
    } else {      
      _changeSet.markAdded(key);      
    }

    _fields[key] = value;
    _notify();
  }

  /**
   * Removes [key] from the data object.
   */
  void remove(String key) {
    _fields.remove(key);
    _changeSet.markRemoved(key);
    _notify();
  }

}

// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class DataView {

  final Map _fields = new Map();
  /**
   * Returns the value for the given key or null if key is not in the data object.
   * Because null values are supported, one should use containsKey to
   * distinguish between an absent key and a null value.
   */
  dynamic operator[](key) => _fields[key];
  
  ChangeSet _changeSet = new ChangeSet();
  ChangeSet _changeSetSync = new ChangeSet();

  final StreamController<ChangeSet> _onChangeController =
      new StreamController.broadcast();

  final StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);
  
  
  /**
   * Stream populated with [ChangeSet] events whenever the data gets changed.
   */
  Stream<ChangeSet> get onChange => _onChangeController.stream;

  /**
   * Stream populated with {'change': [ChangeSet], 'author': [dynamic]} events
   * synchronously at the moment when the data get changed.
   */
  Stream<Map> get onChangeSync => _onChangeSyncController.stream;

  /**
   * Returns true if there is no {key, value} pair in the data object.
   */
  bool get isEmpty {
    return _fields.isEmpty;
  }

  /**
   * Returns true if there is at least one {key, value} pair in the data object.
   */
  bool get isNotEmpty {
    return _fields.isNotEmpty;
  }
  
  /**
   * The keys of data object.
   */
  Iterable get keys {
    return _fields.keys;
  }
  /**
   * The values of [Data].
   */
  Iterable get values {
    return _fields.values;
  }

  /**
   * The number of {key, value} pairs in the [Data].
   */
  int get length {
    return _fields.length;
  }

  /**
   * Returns whether this data object contains the given [key].
   */
  bool containsKey(String key) {
    return _fields.containsKey(key);
  }
  
  bool containsValue(Object value) {
    return _fields.containsValue(value);
  }
  /**
   * Converts to Map.
   */
  Map toJson() => new Map.from(_fields);

  /**
   * Streams all new changes marked in [changeSet].
   */
  void _notify({author: null}) {

    if (!_changeSetSync.isEmpty) {
      _onChangeSyncController.add({'author': author, 'change': _changeSetSync});
      _clearChangesSync();
    }

    Timer.run(() {
      if(!_changeSet.isEmpty) {
        _changeSet.prettify();

        if(!_changeSet.isEmpty) {
          _onChangeController.add(_changeSet);
          _clearChanges();
        }
      }
    });
  }

  _clearChanges() {
    _changeSet = new ChangeSet();
  }

  _clearChangesSync() {
    _changeSetSync = new ChangeSet();
  }

  _markAdded(String key) {
    _changeSetSync.markAdded(key);
    _changeSet.markAdded(key);
  }

  _markRemoved(String key) {
    _changeSet.markRemoved(key);
    _changeSetSync.markRemoved(key);
  }

  _markChanged(String key, Change change) {
    _changeSet.markChanged(key, change);
    _changeSetSync.markChanged(key, change);
  }

}

/**
 * A representation for a single unit of structured data.
 */

class Data extends Object with DataView implements Map {


  /**
   * Creates an empty data object.
   */
  Data();

  /**
   * Creates a new data object from key-value pairs [data].
   */
  factory Data.fromMap(dynamic data) {
    var dataObj = new Data();
    for (var key in data.keys) {
      dataObj[key] = data[key];
    }
    dataObj._clearChanges();
    return dataObj;
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void add(String key, value, {author: null}) {
    addAll({key: value}, author: author);
  }

  /**
   * Adds all key-value pairs of [other] to this data.
   */
  void addAll(Map other, {author: null}) {
    other.forEach((key, value) {
      if (_fields.containsKey(key)) {
        _markChanged(key, new Change(_fields[key], value));
      } else {
        _markChanged(key, new Change(null, value));
        _markAdded(key);
      }
      _fields[key] = value;
    });
    _notify(author: author);
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void operator[]=(String key, value) {
    add(key, value);
    _notify();
  }

  /**
   * Removes [key] from the data object.
   */
  void remove(String key, {author: null}) {
    removeAll([key], author: author);
  }

  /**
   * Remove all [keys] from the data object.
   */
  void removeAll(List<String> keys, {author: null}) {
    for (var key in keys) {
      _markChanged(key, new Change(_fields[key], null));
      _markRemoved(key);
      _fields.remove(key);
    }
    _notify(author: author);
  }


  void clear({author: null}) {
    removeAll(keys.toList(), author: author);
  }



  void forEach(void f(key, value)) {
    _fields.forEach(f);
  }

  putIfAbsent(key, ifAbsent()) {
    if(!containsKey(key)){
      add(key, ifAbsent());
    }
  }
}

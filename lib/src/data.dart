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
   * Stream populated with {'change': [ChangeSet], 'author': [dynamic]} events
   * synchronously at the moment when the data get changed.
   */
  Stream<Map> get onChangeSync;

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
}

abstract class DataViewMixin implements DataView {

  final Map _fields = new Map();

  dynamic operator[](key) => _fields[key];

  ChangeSet _changeSet = new ChangeSet();
  ChangeSet _changeSetSync = new ChangeSet();

  final StreamController<ChangeSet> _onChangeController =
      new StreamController<ChangeSet>.broadcast();

  final StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);

  Stream<ChangeSet> get onChange => _onChangeController.stream;

  Stream<Map> get onChangeSync => _onChangeSyncController.stream;

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
  void _notify({author: null}) {
    _onChangeSyncController.add({'author': author, 'change': _changeSetSync});
    Timer.run(() {
      if(!_changeSet.isEmpty) {
        _changeSet.prettify();
        _onChangeController.add(_changeSet);
        _clearChanges();
      }
    });
  }

  _clearChanges() {
    _changeSetSync = new ChangeSet();
    _changeSet = new ChangeSet();
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

}

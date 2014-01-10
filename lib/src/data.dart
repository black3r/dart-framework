// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

//TODO consider moving mixin to separate file

abstract class DataView extends Object with ChangeNotificationsMixin {

  final Map _fields = new Map();
  /**
   * Returns the value for the given key or null if key is not in the data object.
   * Because null values are supported, one should use containsKey to
   * distinguish between an absent key and a null value.
   */
  dynamic operator[](key) => _fields[key];

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
   * Returns Json representation of the object.
   */
  String toString() => toJson().toString();

  /**
   * Should release all allocated (referenced) resources as subscribtions.
   */
  void dispose();
}

/**
 * A representation for a single unit of structured data.
 */

class Data extends DataView with DataChangeListenersMixin<String> implements Map {
  //Track subscriptions and remove

  /**
   * Creates an empty data object.
   */
  Data();



  /**
   * Creates a new data object from key-value pairs [data].
   */
  factory Data.from(dynamic data) {
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
        if(_fields[key] is DataView){
          _removeOnDataChangeListener(key);
        }
      } else {
        _markChanged(key, new Change(null, value));
        _markAdded(key);
      }

      if(value is DataView){
        _addOnDataChangeListener(key, value);
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

      if(_fields[key] is DataView){
        _removeOnDataChangeListener(key);
      }

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
    if (!containsKey(key)) {
      add(key, ifAbsent());
    }
  }

  void dispose() {

  }
}

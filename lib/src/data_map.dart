// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class DataMapView extends Object with ChangeNotificationsMixin, ChangeChildNotificationsMixin {

  final Map<String, DataReference> _fields = new Map();
  /**
   * Returns the value for the given key or null if key is not in the data object.
   * Because null values are supported, one should use containsKey to
   * distinguish between an absent key and a null value.
   */
  dynamic operator[](key) => _fields.containsKey(key) ? _fields[key].value : null;

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
   * The values of [DataMap].
   */
  Iterable get values {
    return _fields.values.map((DataReference ref) => ref.value);
  }

  /**
   * The number of {key, value} pairs in the [DataMap].
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
    bool contains = false;
    _fields.forEach((K, V) {
      if(V.value == value) contains = true;
    });
    return contains;
  }
  /**
   * Converts to Map.
   */
  Map toJson() => new Map.fromIterables(_fields.keys, _fields.values.map((E) => E.value));

  /**
   * Returns Json representation of the object.
   */
  String toString() => toJson().toString();

  /**
   * Should release all allocated (referenced) resources as subscribtions.
   */
  void dispose() {
    _dispose();
  }

}

/**
 * A representation for a single unit of structured data.
 */

class DataMap extends DataMapView implements Map {
  //Track subscriptions and remove

  /**
   * Creates an empty data object.
   */
  DataMap();

  /**
   * Creates a new data object from key-value pairs [data].
   */
  factory DataMap.from(dynamic data) {
    var dataObj = new DataMap();
    for (var key in data.keys) {
      dataObj[key] = data[key];
    }
    dataObj._clearChanges();
    dataObj._clearChangesSync();
    return dataObj;
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void add(String key, value, {author: null}) {
    _addAll({key: value}, author: author);
  }

  /**
   * Adds all key-value pairs of [other] to this data.
   */
  void addAll(Map other, {author: null}) {
    _addAll(other, author:author);
  }

  void _addAll(Map other, {author: null}) {
    other.forEach((key, value) {
      if (_fields.containsKey(key)) {
        _fields[key].changeValue(value, author: author);
      } else {
        DataReference ref = new DataReference(value);
        _markAdded(key, ref.value);
        _addOnDataChangeListener(key, ref);
        _fields[key] = ref;
      }
    });
    _notify(author: author);
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void operator[]=(String key, value) {
    _addAll({key: value});
  }

  /**
   * Removes [key] from the data object.
   */
  void remove(String key, {author: null}) {
    _removeAll([key], author: author);
  }

  /**
   * Remove all [keys] from the data object.
   */
  void removeAll(List<String> keys, {author: null}) {
    _removeAll(keys, author:author);
  }


  void _removeAll(List<String> keys, {author: null}) {
    for (var key in keys) {
      _markRemoved(key, _fields[key].value);
      _removeOnDataChangeListener(key);
      _fields.remove(key);
    }
    _notify(author: author);
  }

  void clear({author: null}) {
    _removeAll(keys.toList(), author: author);
  }

  void forEach(void f(key, value)) {
    _fields.forEach((K, V) => f(K, V.value));
  }

  DataReference ref(String key) {
    return _fields[key];
  }

  putIfAbsent(key, ifAbsent()) {
    if (!containsKey(key)) {
      _addAll({key: ifAbsent()});
    }
  }

}

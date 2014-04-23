// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class DataMapView<K, V> extends Object with ChangeNotificationsMixin, ChangeChildNotificationsMixin {

  final Map<K, dynamic> _fields = new Map();
  /**
   * Returns the value for the given key or null if key is not in the data object.
   * Because null values are supported, one should use containsKey to
   * distinguish between an absent key and a null value.
   */
  V operator[](key) => _fields[key] is DataReference ? _fields[key].value : _fields[key];

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
  Iterable<K> get keys {
    return _fields.keys;
  }
  /**
   * The values of [DataMap].
   */
  Iterable<V> get values {
    return _fields.values.map((elem) => elem is DataReference ? elem.value : elem);
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
  bool containsKey(K key) {
    return _fields.containsKey(key);
  }

  bool containsValue(Object value) {
    if(_fields.containsValue(value)) return true;
    bool contains = false;
    _fields.forEach((K, elem) { if(elem is DataReference && elem.value == value) contains = true;});
    return contains;
  }
  /**
   * Converts to Map.
   */
  Map toJson() => new Map.fromIterables(this.keys, this.values);

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

class DataMap<K, V> extends DataMapView<K, V> implements Map<K, V> {
  //Track subscriptions and remove

  /**
   * Creates an empty data object.
   */
  DataMap();

  /**
   * Creates a new data object from key-value pairs [data].
   */
  factory DataMap.from(Map<K, V> data) {
    var dataObj = new DataMap<K, V>();
    dataObj._initAddAll(data);
    return dataObj;
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void add(K key, V value, {author: null}) {
    _addAll({key: value}, author: author);
  }

  /**
   * Adds all key-value pairs of [other] to this data.
   */
  void addAll(Map<K, V> other, {author: null}) {
    _addAll(other, author:author);
  }

  void _initAddAll(Map<K, V> other){
    other.forEach((key, value) {
      if (value is List || value is Set || value is Map) {
        value = cleanify(value);
      }
      if(value is ChangeNotificationsMixin) _addOnDataChangeListener(key, value);
      _fields[key] = value;
    });
  }

  void _addAll(Map<K, V> other, {author: null}) {
    other.forEach((key, value) {
      if (value is List || value is Set || value is Map) {
        value = cleanify(value);
      }
      if (_fields.containsKey(key)) {
        if(_fields[key] is DataReference)
          _fields[key].changeValue(value, author: author);
        else {
          _markChanged(key, new Change(_fields[key], value));
          _removeOnDataChangeListener(key);
          if(value is ChangeNotificationsMixin) _addOnDataChangeListener(key, value);
          _fields[key] = value;
        }
      } else {
        _markAdded(key, value);
        if(value is ChangeNotificationsMixin) _addOnDataChangeListener(key, value);
        _fields[key] = value;
      }
    });
    _notify(author: author);
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void operator[]=(K key, V value) {
    _addAll({key: value});
  }

  /**
   * Removes [key] from the data object.
   */
  V remove(K key, {author: null}) {
    return _removeAll([key], author: author).first;
  }

  /**
   * Remove all [keys] from the data object.
   */
  Iterable<V> removeAll(List<K> keys, {author: null}) {
    return _removeAll(keys, author:author);
  }


  Iterable<V> _removeAll(List<K> keys, {author: null}) {
    var removed = [];
    for (var key in keys) {
      if(_fields.containsKey(key)){
        _markRemoved(key, this[key]);
        removed.add(_fields.remove(key));
      }
      _removeOnDataChangeListener(key);
    }
    _notify(author: author);
    return removed;
  }

  void clear({author: null}) {
    _removeAll(keys.toList(), author: author);
  }

  void forEach(void f(K key, V value)) {
    _fields.forEach((K, V) => f(K, V is DataReference ? V.value : V));
  }

  DataReference ref(K key) {
    if(!_fields.containsKey(key)) return null;
    if(_fields[key] is! DataReference) {
      _removeOnDataChangeListener(key);
      _fields[key] = new DataReference(_fields[key]);
      _addOnDataChangeListener(key, _fields[key]);
    }
    return _fields[key];
  }

  putIfAbsent(K key, ifAbsent()) {
    if (!containsKey(key)) {
      _addAll({key: ifAbsent()});
    }
  }

}

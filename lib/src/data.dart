// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class DataView {

  /**
   * Returns the value for the given key or null if key is not in the model.
   * Because null values are supported, one should use containsKey to
   * distinguish between an absent key and a null value.
   */
  dynamic operator[](key);

  /**
   * Stream populated with [ChangeSet] events whenever the model gets changed.
   */
  Stream<ChangeSet> get onChange;

  /**
   * Returns true if there is no {key, value} pair in the model.
   */
  bool get isEmpty;

  /**
   * Returns true if there is at least one {key, value} pair in the model.
   */
  bool get isNotEmpty;

  /**
   * The keys of model.
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
   * Returns whether this model contains the given [key].
   */
  bool containsKey(String key);
}

abstract class DataViewMixin implements DataView {

  final Map _fields = new Map();

  dynamic operator[](key) => this._fields[key];

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
    return this._fields.containsKey(key);
  }

  /**
   * Streams all new changes marked in [changeSet].
   */
  void _notify() {
    Timer.run(() {
      if(!_changeSet.isEmpty) {
        this._onChangeController.add(this._changeSet);
        _clearChanges();
      }
    });
  }

  _clearChanges() {
    this._changeSet = new ChangeSet();
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
    var model = new Data();
    data.forEach((k, v) => model[k] = v);
    model._clearChanges();
    return model;
  }

  /**
   * Assigns the [value] to the [key] field.
   */
  void operator[]=(String key, value) {
    if (this._fields.containsKey(key)) {
      _changeSet.changed(key, new Change(this._fields[key], value));
    } else {
      _changeSet.added(key);
    }

    this._fields[key] = value;
    _notify();
  }

  /**
   * Removes [key] from the data object.
   */
  void remove(String key) {
    this._fields.remove(key);
    this._changeSet.removed(key);
    _notify();
  }

}

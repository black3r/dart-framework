// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class ModelView {

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
   * The values of [Model].
   */
  Iterable get values;

  /**
   * The number of {key, value} pairs in the [Model].
   */
  int get length;

  /**
   * Returns whether this model contains the given [key].
   */
  bool containsKey(String key);
}

abstract class ModelViewMixin implements ModelView {

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
class Model extends Object with ModelViewMixin implements ModelView {

  /**
   * Creates an empty model.
   */
  Model();

  /**
   * Creates a new model from key, value pairs [data].
   */
  factory Model.fromData(Map data) {
    var model = new Model();
    data.forEach((k, v) => model[k] = v);
    model._clearChanges();
    return model;
  }

  /**
   * Assignes the [value] to the [key] field.
   */
  void operator[]=(String key, value) {
    if (this._fields.containsKey(key)) {
      _changeSet.changeChild(key, new Change(this._fields[key], value));
    } else {
      _changeSet.addChild(key);
    }

    this._fields[key] = value;
    _notify();
  }

  /**
   * Removes [key] from model.
   */
  void remove(String key) {
    this._fields.remove(key);
    this._changeSet.removeChild(key);
    _notify();
  }

}

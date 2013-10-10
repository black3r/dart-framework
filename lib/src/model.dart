// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * A representation for a single unit of structured data.
 */
class Model {
  final Map _fields;
  dynamic operator[](key) => this._fields[key];

  ChangeSet _changeSet = new ChangeSet();

  final StreamController<ChangeSet> _onChangeController;
  Stream<ChangeSet> get onChange => _onChangeController.stream;

  /**
   * Creates an empty model.
   */
  Model()
      : _onChangeController = new StreamController<ChangeSet>.broadcast(),
        _fields = new Map() {
  }


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
   * Returns true if there is no {key, value} pair in the [Model].
   */
  bool get isEmpty {
    return _fields.isEmpty;
  }

  /**
   * Returns true if there is at least one {key, value} pair in the [Model].
   */
  bool get isNotEmpty {
    return _fields.isNotEmpty;
  }

  /**
   * The keys of [Model].
   */
  Iterable get keys {
    return _fields.keys;
  }

  /**
   * The values of [Model].
   */
  Iterable get values {
    return _fields.values;
  }

  /**
   * The number of {key, value} pairs in the [Model].
   */
  int get length {
    return _fields.length;
  }

  /**
   * Returns whether this model contains the given [key].
   */
  bool containsKey(String key) {
    return this._fields.containsKey(key);
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
    notify();
  }

  /**
   * Removes [key] from model.
   */
  void remove(String key) {
    this._fields.remove(key);
    this._changeSet.removeChild(key);
    notify();
  }

  /**
   * Streams all new changes marked in [changeSet].
   */
  void notify() {
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

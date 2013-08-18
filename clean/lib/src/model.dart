// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * A representation for a single unit of structured data.
 */
class Model {
  final Map _fields;
  dynamic get id => _fields['id'];
  dynamic operator[](key) => this._fields[key];

  final StreamController<Map> _onChangeController;
  Stream<Map> get onChange => _onChangeController.stream;


  /**
   * Creates a model with the given [id].
   */
  Model(id)
      : _onChangeController = new StreamController<Map>.broadcast(),
        _fields = new Map() {
    this._fields['id'] = id;
  }


  /**
   * Creates a new model from key, value pairs [data].
   */
  factory Model.fromData(id, Map data) {
    var model = new Model(id);
    data.forEach((k, v) => model[k] = v);
    return model;
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
    if (key == 'id') {
      throw new ArgumentError('The field "id" is read only.');
    }

    var old_values = new Map();
    if (this._fields.containsKey(key)) {
      old_values[key] = this._fields[key];
    }

    var new_values = new Map();
    new_values[key] = value;

    this._fields[key] = value;

    this._onChangeController.add({
      'source': this,
      'old_values': old_values,
      'new_values': new_values
    });
  }
}

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

  ChangeSet changeSet = new ChangeSet();
  
  final StreamController<ChangeSet> _onChangeController;
  Stream<ChangeSet> get onChange => _onChangeController.stream;

  /**
   * Creates a model with the given [id].
   */
  Model(id)
      : _onChangeController = new StreamController<ChangeSet>.broadcast(),
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
    
    var old_value = null;
    if (this._fields.containsKey(key)) {
      old_value = this._fields[key];
      changeSet.changeChild(key, new Change(old_value, value));
    } else {
      changeSet.addChild(key);
    }
    
    this._fields[key] = value;
    notify();
  }
  
  /**
   * Removes [key] from model.
   */
  void remove(String key, {silent: false}) {
    this._fields.remove(key);
    
    if(!silent) {
      this.changeSet.removeChild(key);
      notify();
    }
  }
  
  /**
   * Streams all new changes marked in [changeSet].
   */
  void notify() {
    Timer.run(() {
      if(!changeSet.isEmpty) {
        this._onChangeController.add(new ChangeSet.from(this.changeSet)); 
        this.changeSet.clear();
      }
    });
  }
}

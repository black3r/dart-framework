// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Collection of [Model]s.
 */
class Collection {
  final Map<dynamic, Model> _models;
  final Map<dynamic, StreamSubscription> _modelListeners;
  int get length => this._models.length;

  final StreamController _onChangeController;
  Stream<Map> get onChange => _onChangeController.stream;

  /**
   * Creates an empty collection.
   */
  Collection()
      : _models = new Map<dynamic, Model>(),
        _modelListeners = new Map<dynamic, StreamSubscription>(),
        _onChangeController = new StreamController<Map>();


  /**
   * Generates Collection from list of [models].
   */
  factory Collection.fromList(List<Model> models) {
    var collection = new Collection();
    for (var model in models) {
      collection.add(model, silent: true);
    }
    return collection;
  }

  /**
   * Gets model specified by given [id].
   */
  Model operator[](id) => this._models[id];

  /**
   * Returns whether this collection contains the given [id].
   */
  bool containsId(id) => this._models.containsKey(id);

  /**
   * Appends the [model] to the collection.
   *
   * Models should have unique id's.
   */
  void add(Model model, {bool silent: false}) {
    var event = {
      'type': 'add',
      'values': [model],
    };

    this._models[model.id] = model;
    this._modelListeners[model.id] = model.onChange.listen((event) {
      this._onChangeController.add({
        'type': 'change',
        'values': [model],
        'changes': [event],
      });
    });

    if (!silent) {
      this._onChangeController.add(event);
    }
  }

  /**
   * Removes a model from collection
   */
  void remove(id, {bool silent: false}) {
    var model = this._models[id];
    this._models.remove(id);
    this._modelListeners[id].cancel();
    this._modelListeners.remove(id);

    if (!silent) {
      this._onChangeController.add({
        'type': 'remove',
        'values': [model],
      });
    }
  }

}
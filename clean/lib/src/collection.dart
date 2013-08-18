// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Collection of [Model]s.
 */
class Collection extends Object with IterableMixin<Model> {
  final Map<dynamic, Model> _models;
  final List<Model> _modelsList;
  final Map<dynamic, StreamSubscription> _modelListeners;
  int get length => this._models.length;

  final StreamController _onChangeController;
  Stream<Map> get onChange => _onChangeController.stream;

  Iterator<Model> get iterator => _modelsList.iterator;


  /**
   * Creates an empty collection.
   */
  Collection()
      : _models = new Map<dynamic, Model>(),
        _modelsList = new List<Model>(),
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


  void _add(Model model) {
    this._models[model.id] = model;
    this._modelsList.add(model);
    this._modelListeners[model.id] = model.onChange.listen((event) {
      this._onChangeController.add({
        'type': 'change',
        'values': [model],
        'changes': [event],
      });
    });
  }


  /**
   * Appends the [model] to the collection.
   *
   * Models should have unique id's.
   */
  void add(Model model, {bool silent: false}) {
    this._add(model);

    if (!silent) {
      this._onChangeController.add({
        'type': 'add',
        'values': [model],
      });
    }
  }

  void _remove(id) {
    this._models.remove(id);
    this._modelsList.removeWhere((model) => model.id == id);
    this._modelListeners[id].cancel();
    this._modelListeners.remove(id);
  }

  /**
   * Removes a model from the collection.
   */
  void remove(id, {bool silent: false}) {
    var model = this._models[id];
    this._remove(id);

    if (!silent) {
      this._onChangeController.add({
        'type': 'remove',
        'values': [model],
      });
    }
  }

  void _clear() {
    for (var listener in this._modelListeners.values) {
      listener.cancel();
    }
    this._models.clear();
    this._modelListeners.clear();
    this._modelsList.clear();
  }

  /**
   * Removes all models from the collection.
   */
  void clear({bool silent: false}) {
    var models = this._modelsList.toList();
    this._clear();

    if (!silent) {
      this._onChangeController.add({
        'type': 'remove',
        'values': models,
      });
    }
  }

}
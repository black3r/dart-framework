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

  ChangeSet changeSet = new ChangeSet();
  
  final StreamController _onChangeController;
  Stream<ChangeSet> get onChange => _onChangeController.stream;

  Iterator<Model> get iterator => _modelsList.iterator;


  /**
   * Creates an empty collection.
   */
  Collection()
      : _models = new Map<dynamic, Model>(),
        _modelsList = new List<Model>(),
        _modelListeners = new Map<dynamic, StreamSubscription>(),
        _onChangeController = new StreamController<ChangeSet>.broadcast();


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

  void _addOnModelChangeListener(Model model) {
    this._modelListeners[model.id] = model.onChange.listen((event) {
      changeSet.changeChild(model, event);
      notify();
    });
  }

  void _removeOnModelChangeListener(id) {
    this._modelListeners[id].cancel();
    this._modelListeners.remove(id);
  }

  void _add(Model model) {
    this._models[model.id] = model;
    this._modelsList.add(model);
    this._addOnModelChangeListener(model);
  }


  /**
   * Appends the [model] to the collection.
   *
   * Models should have unique id's.
   */
  void add(Model model, {bool silent: false}) {
    this._add(model);

    if (!silent) {
      changeSet.addChild(model);
      notify();
    }
  }

  void _remove(id) {
    this._models.remove(id);
    this._modelsList.removeWhere((model) => model.id == id);
    this._removeOnModelChangeListener(id);
  }

  /**
   * Removes a model from the collection.
   */
  void remove(id, {bool silent: false}) {
    var model = this._models[id];
    this._remove(id);

    if (!silent) {
      changeSet.removeChild(model);
      notify();
    }
  }

  void _clear() {
    for (var id in this._models.keys) {
      this._removeOnModelChangeListener(id);
    }
    this._models.clear();
    this._modelsList.clear();
  }

  /**
   * Removes all models from the collection.
   */
  void clear({bool silent: false}) {
    var models = this._modelsList.toList();
    this._clear();

    if (!silent) {
      for(var model in models) {
        this.changeSet.removeChild(model);
      }
      notify();
    }
  }
  /**
   * Stream all new changes marked in [changeset].
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
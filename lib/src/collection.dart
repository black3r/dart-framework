// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Provides the read operations with collection of models.
 */
abstract class CollectionView implements Iterable {

  /**
   * Stream populated with [ChangeSet] events whenever the collection or any
   * of models contained gets changed.
   */
  Stream<ChangeSet> get onChange;

  /**
   * Returns whether this collection contains the given [model].
   */
  bool contains(ModelView model);
}

abstract class CollectionViewMixin implements CollectionView {
  final Set<ModelView> _models = new Set<ModelView>();

  final Map<dynamic, StreamSubscription> _modelListeners =
      new Map<dynamic, StreamSubscription>();

  int get length => this._models.length;

  ChangeSet _changeSet = new ChangeSet();

  final StreamController _onChangeController =
      new StreamController<ChangeSet>.broadcast();

  Stream<ChangeSet> get onChange => _onChangeController.stream;

  bool contains(ModelView model) => this._models.contains(model);

  void _clearChanges() {
    this._changeSet = new ChangeSet();
  }

  /**
   * Stream all new changes marked in [changeset].
   */
  void _notify() {
    Timer.run(() {
      if(!_changeSet.isEmpty) {
        this._onChangeController.add(this._changeSet);
        this._clearChanges();
      }
    });
  }
}

/**
 * Collection of [ModelView]s.
 */
class Collection extends Object with CollectionViewMixin,
    IterableMixin<ModelView> {

  Iterator<ModelView> get iterator => _models.iterator;

  /**
   * Creates an empty collection.
   */
  Collection();

  /**
   * Generates Collection from [Iterable] of [models].
   */
  factory Collection.from(Iterable<ModelView> models) {
    var collection = new Collection();
    for (var model in models) {
      collection.add(model);
    }
    collection._clearChanges();
    return collection;
  }

  void _addOnModelChangeListener(ModelView model) {
    this._modelListeners[model] = model.onChange.listen((event) {
      _changeSet.changeChild(model, event);
      _notify();
    });
  }

  void _removeOnModelChangeListener(ModelView model) {
    this._modelListeners[model].cancel();
    this._modelListeners.remove(model);
  }

  /**
   * Appends the [model] to the collection.
   *
   * Models should have unique id's.
   */
  void add(ModelView model) {
    this._models.add(model);
    this._addOnModelChangeListener(model);
    _changeSet.addChild(model);
    _notify();
  }

  /**
   * Removes a model from the collection.
   */
  void remove(ModelView model) {
    this._models.remove(model);
    this._removeOnModelChangeListener(model);
    _changeSet.removeChild(model);
    _notify();
  }

  /**
   * Removes all models from the collection.
   */
  void clear() {
    for (var model in this._models) {
      this._removeOnModelChangeListener(model);
      this._changeSet.removeChild(model);
    }
    this._models.clear();
    _notify();
  }

}

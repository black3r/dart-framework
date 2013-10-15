// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Provides the read operations with collection of models.
 */
abstract class DataCollectionView implements Iterable {

  /**
   * Stream populated with [ChangeSet] events whenever the collection or any
   * of models contained gets changed.
   */
  Stream<ChangeSet> get onChange;

  /**
   * Returns whether this collection contains the given [model].
   */
  bool contains(DataView model);
}

abstract class DataCollectionViewMixin implements DataCollectionView {
  final Set<DataView> _models = new Set<DataView>();

  final Map<dynamic, StreamSubscription> _modelListeners =
      new Map<dynamic, StreamSubscription>();

  int get length => this._models.length;

  ChangeSet _changeSet = new ChangeSet();

  final StreamController _onChangeController =
      new StreamController<ChangeSet>.broadcast();

  Stream<ChangeSet> get onChange => _onChangeController.stream;

  bool contains(DataView model) => this._models.contains(model);

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
 * Collection of [DataView]s.
 */
class DataCollection extends Object with DataCollectionViewMixin,
    IterableMixin<DataView> {

  Iterator<DataView> get iterator => _models.iterator;

  /**
   * Creates an empty collection.
   */
  DataCollection();

  /**
   * Generates Collection from [Iterable] of [data].
   */
  factory DataCollection.from(Iterable<DataView> data) {
    var collection = new DataCollection();
    for (var model in data) {
      collection.add(model);
    }
    collection._clearChanges();
    return collection;
  }

  void _addOnModelChangeListener(DataView model) {
    this._modelListeners[model] = model.onChange.listen((event) {
      _changeSet.changed(model, event);
      _notify();
    });
  }

  void _removeOnModelChangeListener(DataView model) {
    this._modelListeners[model].cancel();
    this._modelListeners.remove(model);
  }

  /**
   * Appends the [model] to the collection.
   *
   * Models should have unique id's.
   */
  void add(DataView model) {
    this._models.add(model);
    this._addOnModelChangeListener(model);
    _changeSet.added(model);
    _notify();
  }

  /**
   * Removes a model from the collection.
   */
  void remove(DataView model) {
    this._models.remove(model);
    this._removeOnModelChangeListener(model);
    _changeSet.removed(model);
    _notify();
  }

  /**
   * Removes all models from the collection.
   */
  void clear() {
    for (var model in this._models) {
      this._removeOnModelChangeListener(model);
      this._changeSet.removed(model);
    }
    this._models.clear();
    _notify();
  }

}

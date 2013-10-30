// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Observable collection of data objects that allows for read-only operations.
 *
 * By observable we mean that changes to the contents of the collection (data addition / change / removal)
 * are propagated to registered listeners.
 */
abstract class DataCollectionView implements Iterable {

  /**
   * Stream populated with [ChangeSet] events whenever the collection or any
   * of data object contained gets changed.
   */
  Stream<ChangeSet> get onChange;

  /**
   * Stream populated with {'change': [ChangeSet], 'author': [dynamic]} events
   * synchronously at the moment when the collection or any data object contained
   * gets changed.
   */
  Stream<Map> get onChangeSync;

  /**
   * Returns true iff this collection contains the given [dataObj].
   *
   * @param dataObj Data object to be searched for.
   */
  bool contains(DataView dataObj);

  /**
   * Filters the data collection w.r.t. the given filter function [test].
   *
   * The collection remains up-to-date w.r.t. to the source collection via
   * background synchronization.
   *
   * For the synchronization to work properly, the [test] function must nost:
   *  * change the source collection, or any of its elements
   *  * depend on a non-final outside variable
   */
   DataCollectionView where(bool test(DataView d));

}

/**
 * A minimal implementation of [DataCollectionView].
 */
abstract class DataCollectionViewMixin implements DataCollectionView {

  Iterator<DataView> get iterator => _data.iterator;

  /**
   * Holds data view objects for the collection.
   */
  final Set<DataView> _data = new Set<DataView>();

  /**
   * Internal set of listeners for change events on individual data objects.
   */
  final Map<dynamic, StreamSubscription> _dataListeners =
      new Map<dynamic, StreamSubscription>();

  /**
   * Used to propagate change events to the outside world.
   */
  Stream<ChangeSet> get onChange => _onChangeController.stream;
  Stream<Map> get onChangeSync => _onChangeSyncController.stream;

  final StreamController<ChangeSet> _onChangeController =
      new StreamController.broadcast();
  final StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);

  /**
   * Current state of the collection expressed by a [ChangeSet].
   */
  ChangeSet _changeSet = new ChangeSet();
  ChangeSet _changeSetSync = new ChangeSet();

  int get length => _data.length;
  bool contains(DataView dataObj) => _data.contains(dataObj);

  /**
   * Reset the change log of the collection.
   */
  void _clearChanges() {
    _changeSet = new ChangeSet();
  }

  void _clearChangesSync() {
    _changeSetSync = new ChangeSet();
  }

  /**
   * Stream all new changes marked in [ChangeSet].
   */
  void _notify({author: null}) {
    _onChangeSyncController.add({'author': author, 'change': _changeSetSync});
    _clearChangesSync();
    Timer.run(() {
      if(!_changeSet.isEmpty) {
        _changeSet.prettify();
        _onChangeController.add(_changeSet);
        _clearChanges();
      }
    });
  }

  void _markAdded(DataView dataObj) {
    _changeSet.markAdded(dataObj);
    _changeSetSync.markAdded(dataObj);
  }
  void _markRemoved(DataView dataObj) {
    _changeSet.markRemoved(dataObj);
    _changeSetSync.markRemoved(dataObj);
  }
  void _markChanged(DataView dataObj, ChangeSet changeSet) {
    _changeSet.markChanged(dataObj, changeSet);
    _changeSetSync.markChanged(dataObj, changeSet);
  }

  DataCollectionView where(bool test(DataView d)) {
    return new FilteredDataCollection(this, test);
  }

}

/**
 * Collection of [DataView]s.
 */
class DataCollection extends Object with IterableMixin<DataView>,DataCollectionViewMixin {

  /**
   * Creates an empty collection.
   */
  DataCollection();

  /**
   * Generates Collection from [Iterable] of [data].
   */
  factory DataCollection.from(Iterable<DataView> data) {
    var collection = new DataCollection();
    for (var dataObj in data) {
      collection.add(dataObj);
    }
    collection._clearChanges();
    collection._clearChangesSync();
    return collection;
  }

  /**
   * Appends the [dataObj] to the collection.
   *
   * Data objects should have unique IDs.
   */
  void add(DataView dataObj, {author: null}) {
    _data.add(dataObj);
    _addOnDataChangeListener(dataObj);

    _markAdded(dataObj);
    _notify(author: author);
  }

  /**
   * Removes a data object from the collection.
   */
  void remove(DataView dataObj, {author: null}) {
    _data.remove(dataObj);
    _removeOnDataChangeListener(dataObj);
    _markRemoved(dataObj);
    _notify(author: author);
  }

  /**
   * Removes all data objects from the collection.
   */
  void clear() {
    for (var dataObj in _data) {
      _removeOnDataChangeListener(dataObj);
      _markRemoved(dataObj);
    }
    _data.clear();
    _notify();
  }

  void _addOnDataChangeListener(DataView dataObj) {
    _dataListeners[dataObj] = dataObj.onChangeSync.listen((changeEvent) {
      _markChanged(dataObj, changeEvent['change']);
      _notify(author: changeEvent['author']);
    });
  }

  void _removeOnDataChangeListener(DataView dataObj) {
    _dataListeners[dataObj].cancel();
    _dataListeners.remove(dataObj);
  }
}

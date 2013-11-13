// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

typedef bool DataTestFunction(DataView d);
typedef dynamic DataTransformFunction(DataView d);

/**
 * Observable collection of data objects that allows for read-only operations.
 *
 * By observable we mean that changes to the contents of the collection (data addition / change / removal)
 * are propagated to registered listeners.
 */
abstract class DataCollectionView extends Object with IterableMixin<DataView> implements Iterable {

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


// ============================ index ======================

  /**
   * The index on columns that speeds up retrievals and removals by property value.
   */
  final Map<String, HashIndex> _index = new Map<String, HashIndex>();

  /**
   * Adds indices on chosen properties. Indexed properties can be
   * used to retrieve data by their value with the [findBy] method,
   * or removed by their value with the [removeBy] method.
   */
  void addIndex([Iterable<String> indexedProps]) {

    if (indexedProps != null) {
      // initialize change listener; lazy
      if (_index.keys.length == 0) {
         _initIndexListener();
      }

      for(String prop in indexedProps) {
        if(!_index.containsKey(prop)) {
          // create and initialize the index
          _index[prop] = new HashIndex();
          _rebuildIndex(prop);
        }
      }
    }
  }


  /**
   * (Re)indexes all existing data objects into [prop] index.
   */
  void _rebuildIndex(String prop) {
    for(DataView d in this){
      if (d.containsKey(prop)) {
        _index[prop].add(d[prop], d);
      }
    }
  }

  /**
   * Starts listening synchronously on changes to the collection
   * and rebuilds the indices accordingly.
   */
  void _initIndexListener() {

    this.onChangeSync.listen((Map changes) {
      ChangeSet cs = changes['change'];

      // scan for each indexed property and reindex changed items
      for (String indexProp in _index.keys) {
        cs.addedItems.forEach((DataView d){
          if (d.containsKey(indexProp)) {
            _index[indexProp].add(d[indexProp], d);
          }
        });

        cs.removedItems.forEach((DataView d) {
          if (d.containsKey(indexProp)) {
            _index[indexProp].remove(d[indexProp], d);
          }
        });

        cs.changedItems.forEach((DataView d, ChangeSet cs) {
          if (d.containsKey(indexProp) && cs.changedItems.containsKey(indexProp)) {
            _index[indexProp].remove(cs.changedItems[indexProp].oldValue, d);
            _index[indexProp].add(cs.changedItems[indexProp].newValue,d);
          }
        });
      }
    });
  }

  /**
   * Finds all objects that have [property] equal to [value] in this collection.
   */
  Iterable<DataView> findBy(String property, dynamic value) {
    if (!_index.containsKey(property)) {
      throw new NoIndexException('Property $property is not indexed.');
    }
    return _index[property][value];
  }

  // ============================ /index ======================



  /**
   * Stream populated with [ChangeSet] events whenever the collection or any
   * of data object contained gets changed.
   */
   Stream<ChangeSet> get onChange => _onChangeController.stream;

  /**
   * Stream populated with [DataView] events before any
   * data object is added.
   */
   Stream<DataView> get onBeforeAdded => _onBeforeAddedController.stream;

  /**
   * Stream populated with [DataView] events before any
   * data object is removed.
   */
   Stream<DataView> get onBeforeRemoved => _onBeforeRemovedController.stream;

  /**
   * Stream populated with {'change': [ChangeSet], 'author': [dynamic]} events
   * synchronously at the moment when the collection or any data object contained
   * gets changed.
   */
   Stream<Map> get onChangeSync => _onChangeSyncController.stream;

  /**
   * Returns true iff this collection contains the given [dataObj].
   *
   * @param dataObj Data object to be searched for.
   */
   bool contains(DataView dataObj) => _data.contains(dataObj);

  /**
   * Filters the data collection w.r.t. the given filter function [test].
   *
   * The collection remains up-to-date w.r.t. to the source collection via
   * background synchronization.
   */
   DataCollectionView where(DataTestFunction test) {
    return new FilteredCollectionView(this, test);
   }

   /**
    * Maps the data collection to a new collection w.r.t. the given [mapping].
    *
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    */
   DataCollectionView map(DataTransformFunction mapping) {
     return new MappedCollectionView(this, mapping);
   }

   /**
    * Unions the data collection with another [DataCollectionView] to form a new, [UnionedCollectionView].
    *
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    */
   DataCollectionView union(DataCollectionView other) {
     return other == this
         ? this
             : new UnionedCollectionView(this, other);
   }

   /**
    * Intersects the data collection with another [DataCollectionView] to form a new, [IntersectedCollectionView].
    *
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    */
   DataCollectionView intersection(DataCollectionView other) {
     return other == this
         ? this
             : new IntersectedCollectionView(this, other);
   }
   /**
    * Minuses the data collection with another [DataCollectionView] to form a new, [ExceptedCollectionView].
    *
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    *
    */
   DataCollectionView except(DataCollectionView other) {
     return new ExceptedCollectionView(this, other);
   }

//}

/**
 * A minimal implementation of [DataCollectionView].
 */
//abstract class DataCollectionViewMixin implements DataCollectionView {



  /**
   * Used to propagate change events to the outside world.
   */



  final StreamController<ChangeSet> _onChangeController =
      new StreamController.broadcast();
  final StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);

  final StreamController<DataView> _onBeforeAddedController =
      new StreamController.broadcast(sync: true);
  final StreamController<DataView> _onBeforeRemovedController =
      new StreamController.broadcast(sync: true);

  /**
   * Current state of the collection expressed by a [ChangeSet].
   */
  ChangeSet _changeSet = new ChangeSet();
  ChangeSet _changeSetSync = new ChangeSet();

  Set<DataView>_removedObjects = new Set<DataView>();

  int get length => _data.length;


  void unattachListeners() {
    _onChangeController.close();
  }

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
    _changeSetSync.prettify();
    if(!_changeSet.isEmpty) {
      _onChangeSyncController.add({'author': author, 'change': _changeSetSync});
      _clearChangesSync();
    }

    Timer.run(() {
      if(!_changeSet.isEmpty) {

        for(DataView dataObj in _removedObjects.toList()) {
          _removeOnDataChangeListener(dataObj);
        }
        _removedObjects.clear();

        _changeSet.prettify();

        if(!_changeSet.isEmpty) {
          _onChangeController.add(_changeSet);
          _clearChanges();
        }
      }
    });
  }

  void _addOnDataChangeListener(DataView dataObj) {
    if (_dataListeners.containsKey(dataObj)) return;

    _dataListeners[dataObj] = dataObj.onChangeSync.listen((changeEvent) {
      _markChanged(dataObj, changeEvent['change']);
      _notify(author: changeEvent['author']);
    });
  }

  void _removeOnDataChangeListener(DataView dataObj) {
    if (_dataListeners.containsKey(dataObj)) {
      _dataListeners[dataObj].cancel();
      _dataListeners.remove(dataObj);
    }
  }


  void _markAdded(DataView dataObj) {
    _onBeforeAddedController.add(dataObj);

    // if this object was removed and then re-added in this event loop, don't
    // destroy onChange listener to it.
    _removedObjects.remove(dataObj);

    // mark the addition of [dataObj]
    _changeSet.markAdded(dataObj);
    _changeSetSync.markAdded(dataObj);
  }

  void _markRemoved(DataView dataObj) {
    _onBeforeRemovedController.add(dataObj);

    // collection will stop listening to this object's changes after this
    // event loop.
    _removedObjects.add(dataObj);

    // mark the removal of [dataObj]
    _changeSet.markRemoved(dataObj);
    _changeSetSync.markRemoved(dataObj);
  }

  void _markChanged(DataView dataObj, ChangeSet changeSet) {
    _changeSet.markChanged(dataObj, changeSet);
    _changeSetSync.markChanged(dataObj, changeSet);
  }

}

/**
 * Collection of [DataView]s.
 */
class DataCollection extends DataCollectionView {

  /**
   * Creates an empty collection.
   */
  DataCollection(){
  }

  /**
   * Generates Collection from [Iterable] of [data].
   */
  factory DataCollection.from(Iterable<DataView> data) {
    var collection = new DataCollection();
    for (var dataObj in data) {
      collection.add(dataObj);
    }
    collection._clearChanges();
    return collection;
  }

  /**
   * Appends the [dataObj] to the collection.
   *
   * Data objects should have unique IDs.
   */
  void add(DataView dataObj, {author: null}) {
    _markAdded(dataObj);
    _data.add(dataObj);
    _addOnDataChangeListener(dataObj);

    _notify(author: author);
  }

  /**
   * Removes a data object from the collection.
   */
  void remove(DataView dataObj, {author: null}) {
    _markRemoved(dataObj);
    _data.remove(dataObj);
    _notify(author: author);
    //TODO: Why aren't we removing onChangeListeners?
  }

  /**
   * Removes all objects that have [property] equal to [value] from this collection.
   */
  Iterable<DataView> removeBy(String property, dynamic value) {
    if (!_index.containsKey(property)) {
      throw new NoIndexException('Property $property is not indexed.');
    }

    Iterable<DataView> toBeRemoved = _index[property][value];
    toBeRemoved.forEach((DataView d) => _markRemoved(d));
    _data.removeAll(toBeRemoved);
    _notify();
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

}

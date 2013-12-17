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
abstract class DataCollectionView extends Object
               with IterableMixin<DataView>, ChangeNotificationsMixin
               implements Iterable<DataView> {

  Iterator<DataView> get iterator => _data.iterator;

  /**
   * Holds data view objects for the collection.
   */
  final Set<DataView> _data = new Set<DataView>();

  int get length => _data.length;

// ============================ index ======================

  /**
   * The index on columns that speeds up retrievals and removals by property value.
   */
  final Map<String, HashIndex> _index = new Map<String, HashIndex>();
  StreamSubscription _indexListenerSubscription;

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

      for (String prop in indexedProps) {
        if (!_index.containsKey(prop)) {
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
    for (DataView d in this) {
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

    _indexListenerSubscription = this.onChangeSync.listen((Map changes) {
      ChangeSet cs = changes['change'];

      // scan for each indexed property and reindex changed items
      for (String indexProp in _index.keys) {
        cs.addedItems.forEach((DataView d) {
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
   * Stream populated with [DataView] events before any
   * data object is added.
   */
   Stream<DataView> get onBeforeAdd => _onBeforeAddedController.stream;

  /**
   * Stream populated with [DataView] events before any
   * data object is removed.
   */
   Stream<DataView> get onBeforeRemove => _onBeforeRemovedController.stream;

  /**
   * Used to propagate change events to the outside world.
   */

  final StreamController<DataView> _onBeforeAddedController =
      new StreamController.broadcast(sync: true);
  final StreamController<DataView> _onBeforeRemovedController =
      new StreamController.broadcast(sync: true);

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
  DataCollectionView liveWhere(DataTestFunction test) {
   return new FilteredCollectionView(this, test);
  }

  /**
   * Maps the data collection to a new collection w.r.t. the given [mapping].
   *
   * The collection remains up-to-date w.r.t. to the source collection via
   * background synchronization.
   */
  DataCollectionView liveMap(DataTransformFunction mapping) {
    return new MappedCollectionView(this, mapping);
  }

  /**
   * Unions the data collection with another [DataCollectionView] to form a new, [UnionedCollectionView].
   *
   * The collection remains up-to-date w.r.t. to the source collection via
   * background synchronization.
   */
  DataCollectionView liveUnion(DataCollectionView other) {
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
  DataCollectionView liveIntersection(DataCollectionView other) {
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
  DataCollectionView liveDifference(DataCollectionView other) {
    return new ExceptedCollectionView(this, other);
  }


  void unattachListeners() {
    _onChangeController.close();
  }

  /**
   * Stream all new changes marked in [ChangeSet].
   */

  void dispose() {
    if (_indexListenerSubscription != null) {
      _indexListenerSubscription.cancel();
    }
  }

  String toString() => toList().toString();
}

/**
 * Collection of [DataView]s.
 */
class DataCollection extends DataCollectionView with DataChangeListenersMixin<DataView> implements Set<DataView> {

  /**
   * Creates an empty collection.
   */
  DataCollection() {
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

  void _addAll(Iterable<DataView> elements, {author: null}){
    elements.forEach((DataView d) {
       if(!_data.contains(d)){
         _markAdded(d);
         _removedObjects.remove(d);
         _addOnDataChangeListener(d, d);
       }
    });
    _data.addAll(elements);
    _notify(author: author);
  }

  /**
   * Appends the [dataObj] to the collection. If the element
   * was already in the collection, [false] is returned and
   * nothing happens.
   */

  bool add(DataView dataObj, {author: null}) {
    var res = !_data.contains(dataObj);
    this._addAll([dataObj], author: author);
    return res;
  }


  /**
   * Appends all [elements] to the collection.
   */

  void addAll(Iterable<DataView> elements, {author: null}) {
    this._addAll(elements, author: author);
  }

  void _removeAll(Iterable<DataView> toBeRemoved, {author: null}) {
    //the following causes onChangeListeners removal in the next event loop
    toBeRemoved.forEach((DataView d) {
      if(_data.contains(d)){
        _removedObjects.add(d);
        _markRemoved(d);
      }
    });
    _data.removeAll(toBeRemoved);
    _notify(author: author);
  }

  /**
   * Removes multiple data objects from the collection.
   */
  void removeAll(Iterable<DataView> toBeRemoved, {author: null}) {
    this._removeAll(toBeRemoved, author: author);
  }


  /**
   * Removes a data object from the collection.  If the object was not in
   * the collection, returns [false] and nothing happens.
   */
  bool remove(DataView dataObj, {author: null}) {
    var res = _data.contains(dataObj);
    this._removeAll([dataObj], author: author);
    return res;
  }

  /**
   * Removes all objects that have [property] equal to [value] from this collection.
   */
  Iterable<DataView> removeBy(String property, dynamic value, {author: null}) {
    if (!_index.containsKey(property)) {
      throw new NoIndexException('Property $property is not indexed.');
    }

    Iterable<DataView> toBeRemoved = _index[property][value];
    this._removeAll(toBeRemoved, author: author);
  }

  /**
   * Removes all objects satisfying filter [test]
   */
  void _removeWhere(DataTestFunction test, {author: null}) {
    List toBeRemoved = [];
    for (var dataObj in _data) {
      if(test(dataObj)) {
        toBeRemoved.add(dataObj);
      }
    }
    this._removeAll(toBeRemoved, author: author);
  }

  void removeWhere(DataTestFunction test, {author: null}) {
    _removeWhere(test, author:author);
  }


  DataView lookup(Object object) => _data.lookup(object);

  bool containsAll(Iterable<DataView> other) => _data.containsAll(other);

  void retainWhere(bool test(DataView element), {author: null}) {
    this._removeWhere((data) => !test(data), author: author);
  }

  void retainAll(Iterable<Object> elements, {author: null}) {
    var toKeep = new Set.from(elements);
    this._removeWhere((data) => !toKeep.contains(data), author:author);
  }

  Set<DataView> difference(Set<DataView> other) => _data.difference(other);
  Set<DataView> intersection(Set<DataView> other) => _data.intersection(other);
  Set<DataView> union(Set<DataView> other) => _data.union(other);

  /**
   * Removes all data objects from the collection.
   */
  void clear({author: null}) {
    // we shallow copy _data to avoid concurent modification of
    // the _data field during removal
    this._removeAll(new List.from(this._data), author:author);
  }

  void dispose() {
    super.dispose();
    _dataListeners.forEach((data, subscription) => subscription.cancel());
  }
}

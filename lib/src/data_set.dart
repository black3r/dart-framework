// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

typedef bool DataTestFunction(d);
typedef dynamic DataTransformFunction(d);

/**
 * Observable set of data objects that allows for read-only operations.
 *
 * By observable we mean that changes to the contents of the set (data addition / change / removal)
 * are propagated to registered listeners.
 */
abstract class DataSetView extends Object
               with IterableMixin, ChangeNotificationsMixin, ChangeChildNotificationsMixin
               implements Iterable {

  Iterator get iterator => _data.iterator;

  /**
   * Holds data view objects for the set.
   */
  final Set _data = new Set();

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
    for (dynamic d in this) {
      if (d is DataMapView && d.containsKey(prop)) {
        _index[prop].add(d[prop], d);
      }
    }
  }

  /**
   * Starts listening synchronously on changes to the set
   * and rebuilds the indices accordingly.
   */
  void _initIndexListener() {

    // TODO: think about this.
    _indexListenerSubscription = this.onChangeSync.listen((Map changes) {
      ChangeSet cs = changes['change'];

      // scan for each indexed property and reindex changed items
      for (String indexProp in _index.keys) {
        cs.addedItems.forEach((d) {
          if (d is DataMapView && d.containsKey(indexProp)) {
            _index[indexProp].add(d[indexProp], d);
          }
        });

        cs.removedItems.forEach((d) {
          if (d is DataMapView && d.containsKey(indexProp)) {
            _index[indexProp].remove(d[indexProp], d);
          }
        });

        cs.strictlyChanged.forEach((d, css) {
          if (d is DataMapView && d.containsKey(indexProp) && css.changedItems.containsKey(indexProp)) {
            _index[indexProp].remove(css.changedItems[indexProp].oldValue, d);
            _index[indexProp].add(css.changedItems[indexProp].newValue, d);
          }
        });
      }
    });
  }

  /**
   * Finds all objects that have [property] equal to [value] in this set.
   */
  Iterable<DataMapView> findBy(String property, dynamic value) {
    if (!_index.containsKey(property)) {
      throw new NoIndexException('Property $property is not indexed.');
    }
    return _index[property][value];
  }

  // ============================ /index ======================

  /**
   * Stream populated with obj before any obj is added.
   */
  Stream get onBeforeAdd => _onBeforeAddedController.stream;

  /**
   * Stream populated with obj before any obj is removed.
   */
  Stream get onBeforeRemove => _onBeforeRemovedController.stream;



  final StreamController_onBeforeAddedController =
      new StreamController.broadcast(sync: true);
  final StreamController _onBeforeRemovedController =
      new StreamController.broadcast(sync: true);

  /**
   * Returns true iff this set contains the given [dataObj].
   *
   * @param dataObj Data object to be searched for.
   */
  bool contains(dataObj) => _data.contains(dataObj);

  /**
   * Filters the data set w.r.t. the given filter function [test].
   *
   * The set remains up-to-date w.r.t. to the source set via
   * background synchronization.
   */
  DataSetView liveWhere(DataTestFunction test) {
   return new FilteredDataSetView(this, test);
  }


  /**
   * Unions the data set with another [DataSetView] to form a new, [UnionedSetView].
   *
   * The set remains up-to-date w.r.t. to the source set via
   * background synchronization.
   */
  DataSetView liveUnion(DataSetView other) {
    return other == this
        ? this
            : new UnionedDataSetView(this, other);
  }

  /**
   * Intersects the data set with another [DataSetView] to form a new, [IntersectedSetView].
   *
   * The set remains up-to-date w.r.t. to the source set via
   * background synchronization.
   */
  DataSetView liveIntersection(DataSetView other) {
    return other == this
        ? this
            : new IntersectedDataSetView(this, other);
  }
  /**
   * Minuses the data set with another [DataSetView] to form a new, [ExceptedDataSetView].
   *
   * The set remains up-to-date w.r.t. to the source set via
   * background synchronization.
   *
   */
  DataSetView liveDifference(DataSetView other) {
    return new ExceptedDataSetView(this, other);
  }


  void unattachListeners() {
    _onChangeController.close();
  }

  /**
   * Stream all new changes marked in [ChangeSet].
   */

  void dispose() {
    _dispose();
    if (_indexListenerSubscription != null) {
      _indexListenerSubscription.cancel();
    }
  }

  String toString() => toList().toString();
}

/**
 * Set
 */
class DataSet extends DataSetView
                      implements Set {

  /**
   * Creates an empty set.
   */
  DataSet() {
  }

  /**
   * Generates Set from [Iterable] of [data].
   */
  factory DataSet.from(Iterable data) {
    var set = new DataSet();
    set.addAll(data);
    set._clearChanges();
    set._clearChangesSync();
    return set;
  }

  void _addAll(Iterable elements, {author: null}){
    elements.forEach((data) {
       if(!_data.contains(data)){
         _markAdded(data, data);
         if(data is ChangeNotificationsMixin) {
           _addOnDataChangeListener(data, data);
         }
       }
    });
    _data.addAll(elements);
    _notify(author: author);
  }

  /**
   * Appends the [dataObj] to the set. If the element
   * was already in the set, [false] is returned and
   * nothing happens.
   */

  bool add(dataObj, {author: null}) {
    var res = !_data.contains(dataObj);
    this._addAll([dataObj], author: author);
    return res;
  }


  /**
   * Appends all [elements] to the set.
   */

  void addAll(Iterable elements, {author: null}) {
    this._addAll(elements, author: author);
  }

  void _removeAll(Iterable toBeRemoved, {author: null}) {
    toBeRemoved.forEach((data) {
      if (_data.contains(data)) {
        _markRemoved(data, data);
        if (data is ChangeNotificationsMixin) {
          _removeOnDataChangeListener(data);
        }
      }
    });
    _data.removeAll(toBeRemoved);
    _notify(author: author);
  }

  /**
   * Removes multiple data objects from the set.
   */
  void removeAll(Iterable toBeRemoved, {author: null}) {
    this._removeAll(toBeRemoved, author: author);
  }


  /**
   * Removes a data object from the set.  If the object was not in
   * the set, returns [false] and nothing happens.
   */
  bool remove(dataObj, {author: null}) {
    var res = _data.contains(dataObj);
    this._removeAll([dataObj], author: author);
    return res;
  }

  /**
   * Removes all objects that have [property] equal to [value] from this set.
   */
  Iterable removeBy(String property, dynamic value, {author: null}) {
    if (!_index.containsKey(property)) {
      throw new NoIndexException('Property $property is not indexed.');
    }

    this._removeAll(_index[property][value], author: author);
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


  lookup(Object object) => _data.lookup(object);

  bool containsAll(Iterable other) => _data.containsAll(other);

  void retainWhere(bool test(element), {author: null}) {
    this._removeWhere((data) => !test(data), author: author);
  }

  void retainAll(Iterable<Object> elements, {author: null}) {
    var toKeep = new Set.from(elements);
    this._removeWhere((data) => !toKeep.contains(data), author:author);
  }

  Set difference(Set other) => _data.difference(other);
  Set intersection(Set other) => _data.intersection(other);
  Set union(Set other) => _data.union(other);

  /**
   * Removes all data objects from the set.
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

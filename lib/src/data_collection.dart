// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

typedef bool DataTestFunction(DataView d);
typedef DataView DataTransformFunction(DataView d);

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
   DataCollectionView where(DataTestFunction filter);
  
   /**
    * Maps the data collection to a new collection w.r.t. the given [mapping].
    * 
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    * 
    * For the synchronization to work properly, the [test] function must nost:
    *  * change the source collection, or any of its elements
    *  * depend on a non-final outside variable
    */
   DataCollectionView map(DataTransformFunction mapping);
  
   /**
    * Unions the data collection with another [DataCollectionView] to form a new, [UnionedCollectionView].
    * 
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    * 
    * For the synchronization to work properly, the [test] function must nost:
    *  * change the source collection, or any of its elements
    *  * depend on a non-final outside variable
    */
   DataCollectionView union(DataCollectionView other);
   
   /**
    * Intersects the data collection with another [DataCollectionView] to form a new, [IntersectedCollectionView].
    * 
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    * 
    * For the synchronization to work properly, the [test] function must nost:
    *  * change the source collection, or any of its elements
    *  * depend on a non-final outside variable
    */
   DataCollectionView intersection(DataCollectionView other);
   
   /**
    * Minuses the data collection with another [DataCollectionView] to form a new, [SortedDataView].
    * 
    * The collection remains up-to-date w.r.t. to the source collection via
    * background synchronization.
    * 
    * For the synchronization to work properly, the [test] function must nost:
    *  * change the source collection, or any of its elements
    *  * depend on a non-final outside variable
    */
   DataCollectionView except(DataCollectionView other);
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

  final StreamController _onChangeController =
      new StreamController<ChangeSet>.broadcast();

  /**
   * Current state of the collection expressed by a [ChangeSet].
   */
  ChangeSet _changeSet = new ChangeSet();

  int get length => _data.length;
  bool contains(DataView dataObj) => _data.contains(dataObj);
  
  void unattachListeners() {
    _onChangeController.close();  
  }
  
  /**
   * Reset the change log of the collection.
   */
  void _clearChanges() {
    _changeSet = new ChangeSet();
  }

  /**
   * Stream all new changes marked in [ChangeSet].
   */
  void _notify() {
    Timer.run(() {
      if(!_changeSet.isEmpty) {
        _changeSet.prettify();
        _onChangeController.add(_changeSet);
        _clearChanges();
      }
    });
  }
  
  DataCollectionView where(DataTestFunction test) {
    return new FilteredCollectionView(this, test);
  }
  
  DataCollectionView map(DataTransformFunction mapping) {
    return new MappedCollectionView(this, mapping);
  }
  
  DataCollectionView union(DataCollectionView other) {
    return other == this 
           ? this 
           : new UnionedCollectionView(this, other);
  }
  
  DataCollectionView intersection(DataCollectionView other) {
    return other == this 
           ? this 
           : new IntersectedCollectionView(this, other);
  }
  
  DataCollectionView except(DataCollectionView other) {
    return new SortedDataView(this, other);
  }
  
  SortedCollectionView sort(List order) {
    return new SortedCollectionView(this, order);
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
    return collection;
  }

  /**
   * Appends the [dataObj] to the collection.
   *
   * Data objects should have unique IDs.
   */
  void add(DataView dataObj) {    
    _data.add(dataObj);
    _addOnDataChangeListener(dataObj);
    
    _changeSet.markAdded(dataObj);
    _notify();
  }

  /**
   * Removes a data object from the collection.
   */
  void remove(DataView dataObj) {
    if (!_data.contains(dataObj)) return;
    
    _data.remove(dataObj);
    _removeOnDataChangeListener(dataObj);
    //TODO: there should be markChanged of some kind here!
    _changeSet.markRemoved(dataObj);
    _notify();   
  }

  /**
   * Removes all data objects from the collection.
   */
  void clear() {
    for (var dataObj in _data) {
      _removeOnDataChangeListener(dataObj);
      _changeSet.markRemoved(dataObj);
    }
    _data.clear();
    _notify();
  }

  void _addOnDataChangeListener(DataView dataObj) {
    _dataListeners[dataObj] = dataObj.onChange.listen((changeEvent) {
      _changeSet.markChanged(dataObj, changeEvent);
      _notify();
    });
  }

  void _removeOnDataChangeListener(DataView dataObj) {
    _dataListeners[dataObj].cancel();
    _dataListeners.remove(dataObj);
  }
}

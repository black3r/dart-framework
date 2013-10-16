// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that is a result of a filtering operation on another collection.
 * 
 * TODO: implement a multi-property filter.
 */
class FilteredDataCollection extends Object with DataCollectionViewMixin,
IterableMixin<DataView> {
  
  static const FILTER_KEY = 0;
  static const FILTER_VALUE = 1;
  
  /**
   * The source [DataCollectionView] this collection is derived from. 
   */
  final DataCollectionView source;
  
  /**
   * The [filter] used to derive the data from the [source] collection.
   */
  final filter;

  /**
   * Filters a collection w.r.t. the given [filter].
   */
  Iterable<DataView> _filterAll(Iterable<DataView> items) =>
      items.where((DataView d) => _applyFilter(d));
  
  /**
   * Returns true iff the given [DataView] object complies to the [filter].
   */
  bool _applyFilter(DataView dataObj) => dataObj.containsKey(filter[FILTER_KEY]) &&
                                         dataObj[filter[FILTER_KEY]] == filter[FILTER_VALUE];
  
  /**
   * Creates a new filtered data collection from [source], w.r.t. [filter].
   */
  FilteredDataCollection(DataCollectionView this.source, this.filter) {

    // run the initial filtration on the source collection
    var filtered = _filterAll(source);
    _data.addAll(filtered);
    
    // start listening on [source] collection changes
    source.onChange.listen(_mergeIn);
  }
  
  
  /**
   * Reflects [changes] in the collection w.r.t. [filter].
   * @param changes [ChangeSet] applied to the collection.
   */
  void _mergeIn(ChangeSet changes) {
    
    // add "added" [DataView] objects that comply to the filter
    _filterAll(changes.addedItems).forEach((d) {
      _data.add(d);
      _changeSet.markAdded(d);
    });
    
    // remove "removed" [DataView] objects that comply to the filter
    _filterAll(changes.removedItems).forEach((d) {
      _data.remove(d);
      _changeSet.markRemoved(d);
    });

    // resolve items that were changed in the [source] collection
    for (var dataObj in changes.changedItems.keys){      
      _resolveChangedDataObject(dataObj, changes.changedItems);
    }
      
    if (!this._changeSet.isEmpty) {
      this._notify();
    }
  }
  
  /**
   * Decides whether a data object that has changed in the [source] collection
   * is added/changed/removed in this filtered collection.
   * 
   * @param dataObj a data object that was changed
   * @param changedItems changes made to the object.
   */
  void _resolveChangedDataObject(DataView dataObj, Map changedItems) {
    
    ChangeSet cs = changedItems[dataObj];
    
    bool isInData = _data.contains(dataObj);
    bool shouldBeInData = _applyFilter(dataObj);
    
    if (isInData) {
      if (shouldBeInData) {
        _changeSet.markChanged(dataObj, changedItems);
      } else {
        _data.remove(dataObj);
        _changeSet.markRemoved(dataObj);
      }
    } else if(shouldBeInData) {
        _data.add(dataObj);
        _changeSet.markAdded(dataObj);
    }
  }
}

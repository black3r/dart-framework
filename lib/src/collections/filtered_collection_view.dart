// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that is a result of a filtering operation on another collection.
 */
class FilteredCollectionView extends TransformedDataCollection {
  
  bool _filter(DataView dataObj) => config(dataObj);
  
  /**
   * Filters [items] w.r.t. the given [filter] function.
   */
  Iterable<DataView> _filterAll(Iterable<DataView> items) =>
      items.toList().where((DataView d) => _filter(d));
  
  /**
   * Creates a new filtered data collection from [source], w.r.t. [filter].
   */
  FilteredCollectionView(DataCollectionView source, DataTestFunction filter): super(source, null, filter);
  
  /**
   * Decides whether a [dataObj] that has changed in the [source] collection
   * should be added/changed/removed in this filtered collection.
   */
  void _resolveChangedDataObject(DataView dataObj, Map changedItems) {
    
    ChangeSet cs = changedItems[dataObj];
    
    bool isInData = _data.contains(dataObj);
    bool shouldBeInData = _filter(dataObj);
    
    if (isInData) {
      _changeSet.markChanged(dataObj, changedItems);

      if (!shouldBeInData) {
        _data.remove(dataObj);
        _changeSet.markRemoved(dataObj);
      }
      
    } else if(shouldBeInData) {
        _data.add(dataObj);
        _changeSet.markAdded(dataObj);
    }
  }

  void _init() {
    // run the initial filtration on the source collection
    _data.addAll(_filterAll(source1));
  }

  void _treatAddedItem(DataView dataObj, int sourceNumber) {
    if (!_data.contains(dataObj) && _filter(dataObj)) {
      _data.add(dataObj);
      _changeSet.markAdded(dataObj);
    }
  }

  void _treatChangedItem(DataView dataObj, ChangeSet c, int sourceNumber) {
    _resolveChangedDataObject(dataObj, c.changedItems);
  }

  void _treatRemovedItem(DataView dataObj, int sourceNumber) {
    if(_data.remove(dataObj)) {
      _changeSet.markRemoved(dataObj);
    }
  }
}

// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that is a result of a union operation on another collection.
 */
class UnionedDataCollection extends TransformedDataCollection{
  
  /**
   * Creates a new data collection from [source] where each element e from [source] 
   * is replaced by the result of mapping(e).
   */
  MappedDataCollection(DataCollectionView source1, DataCollectionView source2): super(source, null, {source2:source2});
  
  /**
   * Subscriptions for change events on mapped data objects.
   */
  Map<DataView, StreamSubscription> _subscriptions = new Map(); 
  
  /**
   *  Runs the initial mapping on the source collection.
   */
  void _init() => source.forEach((DataView d) => _addMapped(d,silent:true));

  /**
   * Adds a mapped data object and starts listening to changes on it.
   */
  void _addMapped(DataView dataObj,{bool silent : false}) {
    MappedDataView mappedObj = new MappedDataView(dataObj, config);
    _data.add(mappedObj);
    
    if(!silent) {
      _changeSet.markAdded(mappedObj);
    }
    
    // subscribe to onChange events of the mapped data object
    _subscriptions[mappedObj] = mappedObj.onChange.listen((ChangeSet cs) {
      _changeSet.markChanged(mappedObj, cs);
      _notify();
    });  
  }
  
  void _treatAddedItem(DataView d) => _addMapped(d);
  
  void _treatRemovedItem(DataView dataObj) {

    // find the mapped object and mark it as removed
    DataView mappedDataObj = _data.toList().where((d) => d.source == dataObj).first;
    _changeSet.markRemoved(mappedDataObj);    
    
    // remove the mapped object and its stream subscription as well
    _data.remove(mappedDataObj);
    _subscriptions[mappedDataObj].cancel();
  }
  
  void _treatChangedItem(DataView dataObj, ChangeSet changes) {
  }  
}

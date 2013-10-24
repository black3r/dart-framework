// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * DataView
 */
class MappedDataView extends Object with DataViewMixin implements DataView{
  
  /**
   * Source [DataView] object this object is derived from.
   */
  final DataView source;
  
  /**
   * Mapping function that maps a [DataView] to another [DataView]
   */
  final DataTransformFunction mapping;
  
  MappedDataView(DataView this.source, DataTransformFunction this.mapping) {
    _remap(silent: true);
    source.onChange.listen((c) =>_remap());
  }
  
  /**
   * Re-applies the mapping transformation on this data object. If [silent],
   * no changes will be broadcasted.  
   */
  void _remap({bool silent : false}) {
    
    var mappedObj = mapping(source);
    Set allKeys =new Set.from(mappedObj._fields.keys)
                        .union(new Set.from(_fields.keys));
    allKeys.forEach((key){
      
      // key does not appear in the new mapping
      if(!mappedObj.keys.contains(key)) {
        _fields.remove(key);
        _changeSet.markRemoved(key);
        return;
      }
      
      // key does not appear in the previously mapped object
      if (!_fields.keys.contains(key)) {
        // todo nema to byt aj mark changed?
        _changeSet.markAdded(key);
      } 
      
      // key is in both objects, but the value was maybe changed
      if (_fields[key] != mappedObj[key]) {
          _changeSet.markChanged(key,  new Change(_fields[key], mappedObj[key]));
      }
      
      // make sure the mapped property is updated
      _fields[key] = mappedObj[key];
    });
    
    // broadcast the changes if needed. Anyway, clear them before leaving.
    if (!silent && !_changeSet.isEmpty) {
      _notify();
    } else {
      _clearChanges();
    }
  }
}

/**
 * Represents a read-only data collection that is a result of a mapping operation on another collection.
 */
class MappedCollectionView extends TransformedDataCollection{
  
  /**
   * Creates a new data collection from [source] where each element e from [source] 
   * is replaced by the result of mapping(e).
   */
  MappedCollectionView(DataCollectionView source, DataView mapping(DataView d)): super(source, null, mapping);
  
  /**
   * Subscriptions for change events on mapped data objects.
   */
  Map<DataView, StreamSubscription> _subscriptions = new Map(); 
  
  /**
   *  Runs the initial mapping on the source collection.
   */
  void _init() => source1.forEach((DataView d) => _addMapped(d,silent:true));

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
  
  void _treatAddedItem(DataView d, int sourceNumber) => _addMapped(d);
  
  void _treatRemovedItem(DataView dataObj, int sourceNumber) {

    // find the mapped object and mark it as removed
    DataView mappedDataObj = _data.toList().where((d) => d.source == dataObj).first;
    _changeSet.markRemoved(mappedDataObj);    
    
    // remove the mapped object and its stream subscription as well
    _data.remove(mappedDataObj);
    _subscriptions[mappedDataObj].cancel();
  }
  
  void _treatChangedItem(DataView dataObj, ChangeSet changes, int sourceNumber) {
  }  
}

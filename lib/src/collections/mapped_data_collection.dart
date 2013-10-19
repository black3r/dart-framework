// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class MappedDataView extends Object with DataViewMixin implements DataView{
  
  final DataView source;
  final DataTransformFunction mapping;
  
  MappedDataView(DataView this.source, DataTransformFunction this.mapping) {
    _remap(silent: true);
    source.onChange.listen((c) =>_remap());
  }
  
  /**
   * Re-applies the mapping transformation on this data object. If not [silent],
   * any changes to the object will be broadcasted.  
   */
  void _remap({bool silent : false}) {
    
    var mappedObj = mapping(source);
    new Set.from(mappedObj.keys)
           .union(new Set.from(_fields.keys))
           .forEach((key){
      
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
 * Represents a read-only data collection that is a result of a filtering operation on another collection.
 */
class MappedDataCollection extends TransformedDataCollection{
  
  /**
   * Creates a new data collection from [source] where each element e from [source] 
   * is replaced by the result of mapping(e).
   */
  MappedDataCollection(DataCollectionView source, DataView mapping(DataView d)): super(source, mapping);

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
    
    dataObj.onChange.listen((ChangeSet cs) {
      _changeSet.markChanged(mappedObj, cs); 
      _notify();
    });  
  }
  
  void _treatAddedItem(DataView d) => _addMapped(d);
  
  void _treatRemovedItem(DataView dataObj) {
    DataView mappedDataObj = _data.toList().where((d) => d.source == dataObj).first;
    _data.remove(mappedDataObj);
    _changeSet.markRemoved(mappedDataObj);    
  }
  
  void _treatChangedItem(DataView d, ChangeSet c) {
    // NOOP - MappedDataView object takes care of this.
  }  
}

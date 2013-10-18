// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class MappedDataView extends Object with DataViewMixin implements DataView{
  
  final DataView source;
  final mapping;
  
  MappedDataView(DataView this.source, DataView this.mapping(DataView dataObj)) {
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
class MappedDataCollection extends Object with DataCollectionViewMixin,
IterableMixin<DataView> {
  
  /**
   * The source [DataCollectionView] this collection is derived from. 
   */
  final DataCollectionView source;
  
  /**
   * The [mapping] used to derive the data from the [source] collection.
   */
  final mapping;

  /**
   * Creates a new data collection from [source] where each element e from [source] 
   * is replaced by the result of mapping(e).
   */
  MappedDataCollection(DataCollectionView this.source, this.mapping) {
    // run the initial mapping on the source collection
    source.forEach((DataView dataObj){
      _addMapped(dataObj);
    });
    
    // start listening on [source] collection changes
    source.onChange.listen(_mergeIn);
  }
  
  /**
   * Adds a mapped data object and starts listening to changes on it.
   */
  void _addMapped(DataView dataObj) {
    MappedDataView mappedDataObj = new MappedDataView(dataObj, mapping);
    _data.add(mappedDataObj);
    
    dataObj.onChange.listen((ChangeSet cs) {
      _changeSet.markChanged(mappedDataObj, cs); 
      _notify();    
    });  
  }
  
  /**
   * Reflects [changes] in the collection w.r.t. [mapping].
   */
  void _mergeIn(ChangeSet changes) {
    
    // add "added" [DataView] objects
    changes.addedItems.forEach((dataObj){
      _addMapped(dataObj);
    });
    
    // remove mappings of "removed" [DataView] objects
    changes.removedItems.forEach((dataObj) {
      var mappedDataObj = _data.toList().where((MappedDataView d) => d.source == dataObj);
      _data.removeAll(mappedDataObj);
      _changeSet.markRemoved(mappedDataObj);
    });
      
    // ignore "changed" items - we get updates directly from corresponding objects
    
    if (!_changeSet.isEmpty) {
      _notify();
    }
  }
}
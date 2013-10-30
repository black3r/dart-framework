// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that is a result of a union operation on another collection.
 */
class UnionedCollectionView extends TransformedDataCollection{
  
  /**
   * Creates a new data collection from [source1] and [source2] with all elements from both collections. 
   */
  UnionedCollectionView(DataCollectionView source1, DataCollectionView source2): super(source1, source2, null);
  
  SetOp2<DataView> _srcRefs = new SetOp2<DataView>();
  
  /**
   *  Performs the initial union operation.
   */
  void _init() {
    source1.forEach((DataView d)  => _addDataObject(d, 1, silent:true));
    source2.forEach((DataView d)  => _addDataObject(d, 2, silent:true));
  }

  /**
   * Adds a reference to a data object.
   */
  void _addDataObject(DataView dataObj,int sourceRef, {bool silent : false}) {
    
    if (_srcRefs.hasRef(dataObj, sourceRef)) return;
    
    _srcRefs.addRef(dataObj, sourceRef);
    
    if (_data.contains(dataObj)) return;
    
    _data.add(dataObj);
    
    if(!silent) {
      _changeSet.markAdded(dataObj);
    }
  }
      
  void _treatAddedItem(DataView d, int sourceRef) => _addDataObject(d, sourceRef);
  
  void _treatRemovedItem(DataView dataObj, int sourceRef) {
    _srcRefs.removeRef(dataObj,sourceRef);
    
    if (_srcRefs.hasNoRefs(dataObj)) {
      _changeSet.markRemoved(dataObj);    
      _data.remove(dataObj);      
    }
  }
  
  void _treatChangedItem(DataView dataObj, ChangeSet changes, int sourceRef) {
    _changeSet.markChanged(dataObj, changes);
  }  
}

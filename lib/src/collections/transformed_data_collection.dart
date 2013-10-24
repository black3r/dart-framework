// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only, iterable data collection that is a result of a transformation operation.
 */
abstract class TransformedDataCollection extends DataCollectionView with IterableMixin<DataView>, DataCollectionViewMixin {
  
  /**
   * The source [DataCollectionView](s) this collection is derived from. 
   */
  final DataCollectionView source1;
  final DataCollectionView source2;
  
  /**
   * Any kind of configuration given to this collection in the constructor. Collection behaviour 
   * is based on the value of this variable.
   */
  final config;
 
  TransformedDataCollection(DataCollectionView this.source1,
                            DataCollectionView this.source2, 
                            dynamic this.config) {    
    _init();
    
    // start listening for changes on both sources
    source1.onChange.listen((ChangeSet changes) 
            =>_mergeIn(changes, SetOpMixin.MASK_SRC1));
    
    if (source2 != null) {
      source2.onChange.listen((ChangeSet changes) 
            =>_mergeIn(changes, SetOpMixin.MASK_SRC2));
    }
  }
  
  /**
   * Reflects [changes] in the collection w.r.t. [config].
   */
  void _mergeIn(ChangeSet changes, int sourceNumber) {
    changes.addedItems.forEach((dataObj) => _treatAddedItem(dataObj, sourceNumber));
    changes.removedItems.forEach((dataObj) => _treatRemovedItem(dataObj, sourceNumber));
    changes.changedItems.forEach((dataObj,changes) => _treatChangedItem(dataObj, changes, sourceNumber));
    
    _notify();
  }

  // Abstract methods follow
  void _init();
  void _treatAddedItem(DataView dataObj, int sourceNumber);
  void _treatRemovedItem(DataView dataObj, int sourceNumber);
  void _treatChangedItem(DataView dataObj, ChangeSet c, int sourceNumber);
}

/**
 * A mixin providing bitwise counting and set-op functionality.   
 */
abstract class SetOpMixin {
  
  static const MASK_SRC1 = 1;
  static const MASK_SRC2 = 2;
  
  /**
   * Information which sources does each data object in the collection appear in. Encoded as bit-array of size 2.
   * Break-down of value meanings:
   *  - 0 object is in neither collection
   *  - 1 (=MASK_SRC1) object is in the first source collection
   *  - 2 (=MASK_SRC2) object is in the second source collection
   *  - 3 (=MASK_SRC1|MASK_SRC2) object is in both collections
   */
  Map<DataView, int> _refMap = new Map(); 
  
  /**
   * Returns true iff there is a reference for [dataObj] in [sourceRef].
   */
  bool _hasRef(DataView dataObj, int sourceRef) {
    return _refMap.keys.contains(dataObj) &&
           (_refMap[dataObj] & sourceRef) != 0;  
  }
  
  /**
   * Adds a reference for [dataObj] to a source denoted by [sourceRef].
   */
  void _addRef(DataView dataObj, int sourceRef) {
    if (!_refMap.keys.contains(dataObj)) {
      _refMap[dataObj] = 0;
    }    
    _refMap[dataObj] |= sourceRef;
  }

  /**
   * Removes a reference for [dataObj] to source denoted by [sourceRef].
   */
  bool _removeRef(DataView dataObj, int sourceRef) {
    if (!_refMap.keys.contains(dataObj)) {
      return false;
    }    
    
    _refMap[dataObj] &= ~sourceRef;
    
    if (_refMap[dataObj] == 0) {
      _refMap.remove(dataObj);
      return false;
    }
  }
  
  /**
   * Returns true iff there are two references for [dataObj].
   */
  bool _hasBothRefs(DataView dataObj) 
        => _hasRef(dataObj, SetOpMixin.MASK_SRC1) &&
           _hasRef(dataObj, SetOpMixin.MASK_SRC2); 
  
  /**
   * Returns true iff there are no references for [dataObj].
   */
  bool _hasNoRefs(DataView dataObj) 
        => !_hasRef(dataObj, SetOpMixin.MASK_SRC1) &&
           !_hasRef(dataObj, SetOpMixin.MASK_SRC2); 
  
  /**
   * Returns true iff there are no references for [dataObj].
   */
  bool _hasOneRef(DataView dataObj) 
        => !(_hasBothRefs(dataObj) || _hasNoRefs(dataObj)); 
  
}
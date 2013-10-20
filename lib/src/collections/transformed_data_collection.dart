// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only, iterable data collection that is a result of a transformation operation.
 */
abstract class TransformedDataCollection extends DataCollectionView with IterableMixin<DataView>, DataCollectionViewMixin {
  
  /**
   * The source [DataCollectionView] this collection is derived from. 
   */
  final DataCollectionView source;
  
  /**
   * Any kind of configuration given to this collection in the constructor. Collection behaviour 
   * is based on the value of this variable.
   */
  final config;
  
  TransformedDataCollection(DataCollectionView this.source, dynamic this.config) {    
    _init();
    source.onChange.listen(_mergeIn);
  }
  
  /**
   * Reflects [changes] in the collection w.r.t. [config].
   */
  void _mergeIn(ChangeSet changes) {
    changes.addedItems.forEach((dataObj) => _treatAddedItem(dataObj));
    changes.removedItems.forEach((dataObj) => _treatRemovedItem(dataObj));
    changes.changedItems.forEach((dataObj,changes) => _treatChangedItem(dataObj,changes));
    
    _notify();
  }

  // Abstract methods follow
  void _init();
  void _treatAddedItem(DataView dataObj);
  void _treatRemovedItem(DataView dataObj);
  void _treatChangedItem(DataView dataObj, ChangeSet c);
}
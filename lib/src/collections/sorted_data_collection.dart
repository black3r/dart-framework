// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that is a result of a mapping operation on another collection.
 */
class SortedCollectionView extends TransformedDataCollection{
  
  static const ASCENDING = 1;
  static const DESCENDING = -1;
  static const SORT_ALL_THRESHOLD = 0;
  
  
  Iterator<DataView> get iterator => _items.iterator;
  
  final List<DataView> _items = new List<DataView>();
  List _order = new List<DataView>();
  
  /**
   * Creates a new data collection from [source] where each element e from [source] 
   * is replaced by the result of mapping(e).
   */
  SortedCollectionView(DataCollectionView source, dynamic order): super(source, null, order);
  
  void _sortAll() => _items.sort(_compare);

  int _compare(DataView d1, DataView d2) {
    
    for (int i=0; i<_order.length; i++) {
      var rule = _order[i],
          val1 = d1[rule[0]], 
          val2 = d2[rule[0]];
      
      int res = val1 > val2 
                ? 1 
                : (val2 > val1 ? -1 : 0);

      if (res == 0) continue;
      return rule[1] == ASCENDING 
             ? res
             : -res;
    }
    return 0;
  }
  
  /**
   *  Runs the initial mapping on the source collection.
   */
  void _init(){
    _items.addAll(source1);
    _order = config as List;

    _sortAll();
  }

    
  /**
   * Reflects [changes] in the collection w.r.t. [config].
   */
  void _mergeIn(ChangeSet changes, int sourceNumber) {
    int changeNumber = changes.addedItems.length +
                       changes.removedItems.length +
                       changes.changedItems.length;
    
    if (changeNumber < SORT_ALL_THRESHOLD) {
      _insertChanges(changes);    
    } else {
      changes.addedItems.forEach((d) {
        if(!_items.contains(d)) {
          _items.add(d);
          _changeSet.markAdded(d);
        }
      });
      
      changes.removedItems.forEach((d) {
        if(_items.contains(d)) {
          _items.remove(d);
          _changeSet.markRemoved(d);
        }
      });
      
      _sortAll();
    }
    
    changes.changedItems.forEach((d,c) => _changeSet.markChanged(d,c));
    
    _notify();
  }
  
  // TODO be smarter when doing this: 
  //   1. replace changes for removal+addition.
  //   2. sort all the add/remove operations with [_compare]
  //   3. do a classical one-pass merge with [_items]
  List _insertChanges(ChangeSet changes) {
    
    changes.changedItems.keys.forEach((d) => _items.remove(d));
    changes.removedItems.forEach((d) => _items.remove(d));
    
    changes.addedItems.forEach((d){
      int smaller = _items.takeWhile((d2) => _compare(d,d2) > 0).length;
      _items.insert(smaller, d);
    });
    
    changes.changedItems.keys.forEach((d){
      int smaller = _items.takeWhile((d2) => _compare(d,d2) > 0).length;
      _items.insert(smaller, d);
    });       
  }

  void _treatAddedItem(DataView dataObj, int sourceNumber) {
  }

  void _treatChangedItem(DataView dataObj, ChangeSet c, int sourceNumber) {
  }

  void _treatRemovedItem(DataView dataObj, int sourceNumber) {
  }
}

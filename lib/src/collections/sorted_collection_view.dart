// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that provides a sorted version of source collection w.r.t sorting parameters.
 * TODO specify compare semantics for NULL/undefined values (http://goo.gl/Lbfpdc).
 * TODO specify changeset semantics for sorted collections
 * TODO use insertion sort for small changes
 */
class SortedCollectionView extends TransformedDataCollection{

  static const ASCENDING = 1;
  static const DESCENDING = -1;

  Iterator<DataView> get iterator => _items.iterator;

  final List<DataView> _items = new List<DataView>();
  List _order = new List<DataView>();

  /**
   * Creates a new data collection from [source] where each element e from [source]
   * is replaced by the result of mapping(e).
   */
  SortedCollectionView(DataCollectionView source, dynamic this._order): super([source]) {
    // Runs the initial sort on the source collection.
    _items.addAll(source);
    _sortAll();
  }

  void _sortAll() => _items.sort(_compare);

  int _compare(DataView d1, DataView d2) {

    for (int i=0; i<_order.length; i++) {

      var rule = _order[i],
          attr = rule[0],
          multiplier = rule[1],
          nullOrMissing1 = !d1.containsKey(attr) || d1[attr] == null,
          nullOrMissing2 = !d2.containsKey(attr) || d2[attr] == null;

      // missing/null attribute semantics (undef/null < ANYTHING)
      if (nullOrMissing1 && !nullOrMissing2) return -multiplier;
      if (!nullOrMissing1 && nullOrMissing2) return  multiplier;
      if (nullOrMissing1 && nullOrMissing2) continue;

      // value semantics
      int res = d1[attr] < d2[attr]
                ? -1
                : (d2[attr] < d1[attr] ? 1 : 0);

      // still equal? Decide by next attribute
      if (res != 0) {
        return res * multiplier;
      }
    }

    // totally equal w.r.t. [order]
    return 0;
  }


  /**
   * Reflects [changes] in the collection w.r.t. [config].
   */
  void _mergeIn(ChangeSet changes, int sourceNumber) {
    int changeNumber = changes.addedItems.length +
                       changes.removedItems.length +
                       changes.changedItems.length;


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

    changes.changedItems.forEach((d,c) => _changeSet.markChanged(d,c));

    _sortAll();
    _notify();
  }
}

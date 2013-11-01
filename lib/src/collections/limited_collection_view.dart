// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only data collection that provides a sorted version of source collection w.r.t sorting parameters.
 */
class LimitedCollectionView extends SortedCollectionView {

  final _limit;
  final _offset;
  /**
   * Creates a new data collection from [source] where each element e from [source]
   * is replaced by the result of mapping(e). TODO: This is totally broken.
   */
  LimitedCollectionView(DataCollectionView source, {int limit, int offset}):
      _limit = limit,
      _offset = offset,
      super(source, []);

  /**
   *  Runs the initial sort on the source collection.
   */
  void _init() => _refresh(silent:true);

  /**
   * Recreates the from source
   */
  void _mergeIn(ChangeSet changes, int sourceNumber) {

    _refresh();
    changes.changedItems.forEach((d,c)
        {
      if (_items.contains(d)) {
        _changeSet.markChanged(d, c);
      }
    });

    _notify();
  }

  void _refresh({bool silent: false}) {

    Iterable<DataView> newItems = sources[0].skip(_offset);
    if(_limit > 0) {
      newItems = newItems.take(_limit);
    }

    if (!silent) {
      _makeDiff(_items, newItems);
    }

    _items.clear();
    _items.addAll(newItems);

  }

  _makeDiff(Iterable<DataView> oldObjs, Iterable<DataView> newObjs) {
    Set<DataView> olds = new Set.from(oldObjs);
    Set<DataView> news = new Set.from(newObjs);

    olds.forEach((d){
      if(!news.contains(d)) {
       _changeSet.markRemoved(d);
      }
    });

    news.forEach((d) {
      if(!olds.contains(d)) {
        _changeSet.markAdded(d);
      }
    });
  }

  void _treatAddedItem(DataView dataObj, int sourceNumber) {
  }

  void _treatChangedItem(DataView dataObj, ChangeSet c, int sourceNumber) {
  }

  void _treatRemovedItem(DataView dataObj, int sourceNumber) {
  }
}

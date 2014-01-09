// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only, iterable data collection that is a result of a transformation operation.
 */
abstract class TransformedDataCollection 
                extends DataCollectionView 
                with IterableMixin<ChangeNotificationsMixin> {

  /**
   * The source [DataCollectionView](s) this collection is derived from.
   */
  final List<DataCollectionView> sources;
  List<StreamSubscription> _sourcesSubscription;

  TransformedDataCollection(List<DataCollectionView> this.sources) {
    _sourcesSubscription = new List(this.sources.length);

    for (var i = 0; i < sources.length; i++) {
      this._sourcesSubscription[i] =
          this.sources[i].onChangeSync.listen((change) => _mergeIn(change['change'], i));
    }
  }

  /**
   * Reflects [changes] in the collection w.r.t. [config].
   */
  void _mergeIn(ChangeSet changes, int sourceNumber) {
    changes.addedItems.forEach((dataObj) => _treatAddedItem(dataObj, sourceNumber));
    changes.removedItems.forEach((dataObj) => _treatRemovedItem(dataObj, sourceNumber));
    changes.strictlyChanged.forEach((dataObj,changes) => _treatChangedItem(dataObj, changes, sourceNumber));
    var items = changes.addedItems.union(changes.removedItems).union(new Set.from(changes.changedItems.keys));
    for (var item in items) {
      _treatItem(item, changes.strictlyChanged[item]);
    }
    _notify();
  }

  // Overridable methods follow
  void _treatAddedItem(ChangeNotificationsMixin dataObj, int sourceNumber) {}
  void _treatRemovedItem(ChangeNotificationsMixin dataObj, int sourceNumber) {}
  void _treatChangedItem(ChangeNotificationsMixin dataObj, ChangeSet c, int sourceNumber) {}
  void _treatItem(dataObj, changeSet) {}

  void dispose() {
    _sourcesSubscription.forEach((subscription) => subscription.cancel());
    super.dispose();
  }
}
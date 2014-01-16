// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only, iterable data collection that is a result of a transformation operation.
 */
abstract class TransformedDataSet
                extends DataSetView
                with IterableMixin {

  /**
   * The source [DataSetView](s) this collection is derived from.
   */
  final List<DataSetView> sources;
  List<StreamSubscription> _sourcesSubscription;

  TransformedDataSet(List<DataSetView> this.sources) {
    _sourcesSubscription = new List(this.sources.length);

    for (var i = 0; i < sources.length; i++) {
      this._sourcesSubscription[i] =
          this.sources[i].onChangeSync.listen((change) => _mergeIn(change['change'], i));
    }
  }

  /**
   * Reflects [changes] in the collection w.r.t. [config].
   */
  void _mergeIn(ChangeSet changes, int sourceNumber, {author}) {
    changes.addedItems.forEach((dataObj) => _treatAddedItem(dataObj, sourceNumber));
    changes.removedItems.forEach((dataObj) => _treatRemovedItem(dataObj, sourceNumber));
    changes.strictlyChanged.forEach((dataObj,changes) => _treatChangedItem(dataObj, changes, sourceNumber));
    var items = changes.addedItems.union(changes.removedItems).union(new Set.from(changes.changedItems.keys));
    for (var item in items) {
      _treatItem(item, changes.strictlyChanged[item]);
    }
    _notify(author: author);
  }

  // Overridable methods follow
  void _treatAddedItem(dataObj, int sourceNumber) {}
  void _treatRemovedItem(dataObj, int sourceNumber) {}
  void _treatChangedItem(dataObj, ChangeSet c, int sourceNumber) {}
  void _treatItem(dataObj, changeSet) {}

  void dispose() {
    _sourcesSubscription.forEach((subscription) => subscription.cancel());
    super.dispose();
  }
}

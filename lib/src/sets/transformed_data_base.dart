// Copyright (c) 2014, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class TransformedDataBase implements ChangeNotificationsMixin {
  /**
   * The source [ChangeNotificationsMixin](s) this collection is derived from.
   */
  List<dynamic> sources;
  List<StreamSubscription> _sourcesSubscription;

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
}
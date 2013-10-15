// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * A representation of a single change in a scalar value.
 */
class Change {
  dynamic oldValue;
  dynamic newValue;

  /**
   * Creates new [Change] from information about the value before change
   * [oldValue] and after the change [newValue].
   */
  Change(this.oldValue, this.newValue);

  /**
   * Applies another [change] to get representation of whole change.
   */
  void mergeIn(Change change) {
    newValue = change.newValue;
  }

}

/**
 * A representation of a change of map like object.
 */
class ChangeSet {

  Set addedItems = new Set();
  Set removedItems = new Set();

  /**
   * Contains mapping between the changed children and respective changes.
   *
   * The changes are represented either by [ChangeSet] object or by [Change].
   */
  Map changedItems = new Map();

  /**
   * Creates an empty [ChangeSet].
   */
  ChangeSet();

  /**
   * Marks [child] as added.
   */
  void added(dynamic child) {
    if(this.removedItems.contains(child)) {
      this.removedItems.remove(child);
    } else {
      this.addedItems.add(child);
    }
  }

  /**
   * Marks [child] as removed.
   */
  void removed(dynamic child) {
    if(addedItems.contains(child)) {
      this.addedItems.remove(child);
    } else {
      this.removedItems.add(child);
    }
  }

  /**
   * Marks all the changes in [ChangeSet] or [Change] for a
   * given [child].
   */
  void changed(dynamic child, changeSet) {
    if(this.addedItems.contains(child)) return;

    if(this.changedItems.containsKey(child)) {
      this.changedItems[child].mergeIn(changeSet);
    } else {
      this.changedItems[child] = changeSet;
    }
  }

  /**
   * Merges two [ChangeSet]s together.
   */
  void mergeIn(ChangeSet changeSet) {
    for(var child in changeSet.addedItems ){
      this.added(child);
    }
    for(var child in changeSet.removedItems) {
      this.removed(child);
    }
    changeSet.changedItems.forEach((child,changeSet) {
      this.changed(child,changeSet);
    });
  }


  /**
   * Returns true if there are no changes in the [ChangeSet].
   */
  bool get isEmpty =>
    this.addedItems.isEmpty &&
    this.removedItems.isEmpty &&
    this.changedItems.isEmpty;
  
}

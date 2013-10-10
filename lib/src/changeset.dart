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
  void apply(Change change) {
    newValue = change.newValue;
  }

}

/**
 * A representation of a change of map like object.
 */
class ChangeSet {

  Set addedChildren = new Set();
  Set removedChildren = new Set();

  /**
   * Contains mapping between the changed children and respective changes.
   *
   * The changes are represented either by [ChangeSet] object or by [Change].
   */
  Map changedChildren = new Map();

  /**
   * Creates an empty [ChangeSet].
   */
  ChangeSet();

  /**
   * Marks [child] as added.
   */
  void addChild(dynamic child) {
    if(this.removedChildren.contains(child)) {
      this.removedChildren.remove(child);
    } else {
      this.addedChildren.add(child);
    }
  }

  /**
   * Marks [child] as removed.
   */
  void removeChild(dynamic child) {
    if(addedChildren.contains(child)) {
      this.addedChildren.remove(child);
    } else {
      this.removedChildren.add(child);
    }
  }

  /**
   * Marks all the changes in [ChangeSet] or [Change] for a
   * given [child].
   */
  void changeChild(dynamic child, changeSet) {
    if(this.addedChildren.contains(child)) return;

    if(this.changedChildren.containsKey(child)) {
      this.changedChildren[child].apply(changeSet);
    } else {
      this.changedChildren[child] = changeSet;
    }
  }

  /**
   * Merges two [ChangeSet]s together.
   */
  void apply(ChangeSet changeSet) {
    for(var child in changeSet.addedChildren ){
      this.addChild(child);
    }
    for(var child in changeSet.removedChildren) {
      this.removeChild(child);
    }
    changeSet.changedChildren.forEach((child,changeSet) {
      this.changeChild(child,changeSet);
    });
  }


  /**
   * Returns true if there are no changes in the [ChangeSet].
   */
  bool get isEmpty =>
    this.addedChildren.isEmpty &&
    this.removedChildren.isEmpty &&
    this.changedChildren.isEmpty;
}

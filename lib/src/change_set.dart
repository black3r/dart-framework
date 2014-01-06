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

  /**
   * Clones the [change].
   */
  Change clone() {
    return new Change(oldValue, newValue);
  }

  String toString() => "Change($oldValue->$newValue)";

}

/**
 * A representation of a change of map like object.
 */
class ChangeSet {

  Map addedItems = new Map();
  Map removedItems = new Map();

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
   * Creates [ChangeSet] from [other]
   */
  ChangeSet.from(ChangeSet changeSet) {
    addedItems = new Map.from(changeSet.addedItems);
    removedItems = new Map.from(changeSet.removedItems);
    changeSet.changedItems.forEach((key, change) {
      changedItems[key] = change.clone();
    });
  }

  /**
   * Clone changeSet.
   */
  ChangeSet clone() {
    return new ChangeSet.from(this);
  }

  /**
   * Marks [key] as added with value [value].
   */
  void markAdded(dynamic key, dynamic value) {
    if(this.removedItems.containsKey(key)) {
      var oldVal = this.removedItems.remove(key);
      this.markChanged(key, new Change(oldVal, value));
    } else {
      this.addedItems[key] = value;
    }
  }

  void markRemoved(dynamic key, dynamic value) {
    if(addedItems.containsKey(key)) {
      var oldVal = this.addedItems.remove(key);
      this.markChanged(key, new Change(oldVal, value));
    } else {
      this.removedItems[key] = value;
    }
  }

  /**
   * Marks all the changes in [ChangeSet] or [Change] for a
   * given [dataObj].
   */
  void markChanged(dynamic key, changeSet) {
    for (Map map in [addedItems, removedItems, changedItems]){
      if (map.containsKey(key)){
        map[key].mergeIn(changeSet);
        return;
      }
    }
    changedItems[key] = changeSet.clone();
  }

  /**
   * Merges two [ChangeSet]s together.
   */
  void mergeIn(ChangeSet changeSet) {
    changeSet.addedItems.forEach((key, value){
      markAdded(key, value);
    });
    changeSet.removedItems.forEach((key, value){
      markRemoved(key, value);
    });
    changeSet.changedItems.forEach((key, changeSet) {
      markChanged(key, changeSet);
    });
  }


  /**
   * Returns true if there are no changes in the [ChangeSet].
   */
  bool get isEmpty =>
    this.addedItems.isEmpty &&
    this.removedItems.isEmpty &&
    this.changedItems.isEmpty;


  /**
   * Strips redundant changedItems from the [ChangeSet].
   */
  void prettify() {
    addedItems.forEach((key, value) => changedItems.remove(key));
    removedItems.forEach((key, value) => changedItems.remove(key));

    var equalityChanges = new Set();
    changedItems.forEach((d,cs){
      if (cs is Change && cs.oldValue == cs.newValue) {
       equalityChanges.add(d);
      }
    });
    equalityChanges.forEach((droppableChange) {
      changedItems.remove(droppableChange);
    });
  }

  String toString() {
    return "ChangeSet(added:" + addedItems.toString() + " changed:" + changedItems.toString() + " removed:" + removedItems.toString()+ ')';
  }
}

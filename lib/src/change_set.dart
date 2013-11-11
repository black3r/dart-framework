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

  String toString() => "$oldValue->$newValue";
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
   * Creates [ChangeSet] from [other]
   */
  ChangeSet.from(ChangeSet changeSet) {
    addedItems = new Set.from(changeSet.addedItems);
    removedItems = new Set.from(changeSet.removedItems);
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
   * Marks [dataObj] as added.
   */
  void markAdded(dynamic dataObj) {
    if(this.removedItems.contains(dataObj)) {
      this.removedItems.remove(dataObj);
    } else {
      this.addedItems.add(dataObj);
    }
  }

  /**
   * Marks [dataObj] as removed.
   */
  void markRemoved(dynamic dataObj) {
    if(addedItems.contains(dataObj)) {
      this.addedItems.remove(dataObj);
    } else {
      this.removedItems.add(dataObj);
    }
  }

  /**
   * Marks all the changes in [ChangeSet] or [Change] for a
   * given [dataObj].
   */
  void markChanged(dynamic dataObj, changeSet) {
    if(changedItems.containsKey(dataObj)) {
      changedItems[dataObj].mergeIn(changeSet);
    } else {
      changedItems[dataObj] = changeSet.clone();
    }
  }

  /**
   * Merges two [ChangeSet]s together.
   */
  void mergeIn(ChangeSet changeSet) {
    for(var child in changeSet.addedItems ){
      markAdded(child);
    }
    for(var dataObj in changeSet.removedItems) {
      markRemoved(dataObj);
    }
    changeSet.changedItems.forEach((child, changeSet) {
      markChanged(child, changeSet);
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
    addedItems.forEach((key) => changedItems.remove(key));
    removedItems.forEach((key) => changedItems.remove(key));

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
    return "Added:" + addedItems.toString() + " Changed:" + changedItems.toString() + " Removed:" + removedItems.toString();
  }
}

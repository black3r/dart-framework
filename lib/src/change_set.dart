// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

mapEq(Map m1, Map m2){
  if (m1 == null && m2 == null) return true;
  if (m1 == null || m2 == null) return false;
  return m1.keys.length == m2.keys.length && m1.keys.every((k) => m1[k]==m2[k]);
}


class _Undefined {

  String toString(){
    return 'undefined';
  }
}

var undefined = new _Undefined();

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

  get isEqualityChange => oldValue == newValue;

//  /**
//   * Creates new [Change] from information about the value before change
//   * [oldValue] and after the change [newValue].
//   */
//  Change(this.oldValue, this.newValue) {
//    if(this.oldValue is DataReference) this.oldValue = this.oldValue.value;
//    if(this.newValue is DataReference) this.newValue = this.newValue.value;
//  }

  operator ==(dynamic other){
    if (other is Change){
      return this.oldValue == other.oldValue && this.newValue == other.newValue;
    } else {
      return false;
    }
  }

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

  /**
   * Contains mapping between the changed children and respective changes.
   *
   * The changes are represented either by [ChangeSet] object or by [Change].
   */
  Map changedItems = new Map();

  /**
   * Creates an empty [ChangeSet].
   */
  ChangeSet([Map changedItems = const {}]){
    this.changedItems = new Map.from(changedItems);
  }

  /**
   * Creates [ChangeSet] from [other]
   */
  ChangeSet.from(ChangeSet changeSet) {
    changeSet.changedItems.forEach((key, change) {
      changedItems[key] = change.clone();
    });
  }

  operator ==(dynamic other){
    if (other is ChangeSet){
      return mapEq(this.changedItems, other.changedItems);
    } else {
      return false;
    }
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
    markChanged(key, new Change(undefined, value));
  }

  void markRemoved(dynamic key, dynamic value) {
    markChanged(key, new Change(value, undefined));
  }

  get addedItems {
    var res = [];
    changedItems.forEach((key, dynamic change){
      if(change is Change && change.oldValue == undefined){
        res.add(key);
      }
    });
    return res;
  }

  get removedItems {
    var res = [];
    changedItems.forEach((key, dynamic change){
      if(change is Change && change.newValue == undefined){
        res.add(key);
      }
    });
    return res;
  }

  /**
   * Marks all the changes in [ChangeSet] or [Change] for a
   * given [dataObj].
   */
  void markChanged(dynamic key, change) {
    if(changedItems.containsKey(key)) {
      if(change is Change) {
        if(changedItems[key] is Change) {
          changedItems[key].mergeIn(change);
        }
        else { 
          changedItems[key] = change;
        }
      }
      else {
        if(changedItems[key] is Change) {}
        else {
          changedItems[key].mergeIn(change);
        }
      }
    } else {
      changedItems[key] = change.clone();
    }
  }

  /**
   * Merges two [ChangeSet]s together.
   */
  void mergeIn(ChangeSet changeSet) {
    changeSet.changedItems.forEach((key, changeSet) {
      markChanged(key, changeSet);
    });
  }


  /**
   * Returns true if there are no changes in the [ChangeSet].
   */
  bool get isEmpty =>
    this.changedItems.isEmpty;


  /**
   * Strips redundant changedItems from the [ChangeSet].
   */
  void prettify() {

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
    return 'ChangeSet(${changedItems.toString()})';
  }
}

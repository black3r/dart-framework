// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;


class _Undefined {

  final String type;

  const _Undefined(this.type);

  String toString(){
    return type;
  }
}

const undefined = const _Undefined('undefined');
const unset = const _Undefined('unset');

/**
 * A representation of a single change in a scalar value.
 */
class Change {
  dynamic oldValue;
  dynamic newValue;
  dynamic oldDereferencedValue;

  get isEmpty {
    return oldValue == unset && newValue == unset;
  }

  /**
   * Creates new [Change] from information about the value before change
   * [oldValue] and after the change [newValue].
   */
  Change([this.oldValue = unset, this.newValue = unset]) {
    if(this.oldValue is DataReference) this.oldDereferencedValue = this.oldValue.value;
  }

  bool equals(dynamic other) {
    dereference(value) {
      while (value is DataReference){
        value = value.value;
      }
      return value;
    }

    if (other is Change){
      return dereference(oldValue) == dereference(other.oldValue) &&
             dereference(newValue) == dereference(other.newValue);
    } else {
      return false;
    }
  }

  /**
   * Applies another [change] to get representation of whole change.
   */
  void mergeIn(Change change) {
    if (change.isEmpty) {
      return;
    }
//    print('change ${change.oldValue.runtimeType}');
//    print('change ${change.oldValue}');
//    print('change ${change.newValue.runtimeType}');
      var x = change.newValue;
      print('$x');
//    print('change ${change.newValue}');
    assert(isEmpty || change.oldValue == this.newValue ||
        change.oldValue.value == this.newValue.value);
    if (isEmpty) {
      oldValue = change.oldValue;
      oldDereferencedValue = change.oldDereferencedValue;
    }
    newValue = change.newValue;
  }

  /**
   * Clones the [change].
   */
  Change clone() {
    return new Change(oldValue, newValue)..oldDereferencedValue = this.oldDereferencedValue;
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

  ChangeSet([Map changedItems = const {}]) {
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
  bool equals (dynamic other) {
    if (other is ChangeSet){
      if (this.changedItems.keys.length != other.changedItems.keys.length) return false;
      for (var k in changedItems.keys){
        var v = changedItems[k];
        if (v is Change || v is ChangeSet) {
          if (!v.equals(other.changedItems[k])){
            return false;
          }
        } else {
          return false;
        }
      }
      return true;
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

  Set get addedItems {
    var res = new Set();
    changedItems.forEach((key, dynamic change){
      if(change is Change && change.oldValue == undefined){
        res.add(key);
      }
    });
    return res;
  }

  Set get removedItems {
    var res = new Set();
    changedItems.forEach((key, dynamic change){
      if(change is Change && change.newValue == undefined){
        res.add(key);
      }
    });
    return res;
  }

  get strictlyChanged {
    var res = {};
    changedItems.forEach((key, dynamic change) {
      if(change is ChangeSet)
        res[key] = change;
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

  String toString() {
    return 'ChangeSet(${changedItems.toString()})';
  }
}

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

final String CLEAN_UNDEFINED = '__clean_undefined';

/**
 * A representation of a single change in a scalar value.
 */
class Change {
  dynamic oldValue;
  dynamic newValue;

  get isEmpty {
    return oldValue == unset && newValue == unset;
  }

  /**
   * Creates new [Change] from information about the value before change
   * [oldValue] and after the change [newValue].
   */
  Change([this.oldValue = unset, this.newValue = unset]){
    assert(oldValue is! DataReference);
    assert(newValue is! DataReference);
  }

  bool equals(dynamic other) {
    if (other is Change){
      return oldValue == other.oldValue &&
             newValue == other.newValue;
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
    assert(isEmpty || change.oldValue == this.newValue);
    if (isEmpty) {
      oldValue = change.oldValue;
    }
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

  ChangeSet([Map changedItems = const {}]) {
    this.changedItems = new Map.from(changedItems);
  }

  ChangeSet.fromJson(Map json) {
    for (var key in json.keys) {

      // Change
      if (json[key] is List) {
        List changeList = json[key];

        var oldValue = changeList[0] == CLEAN_UNDEFINED ? undefined :
          changeList[0];
        var newValue = changeList[1] == CLEAN_UNDEFINED ? undefined :
          changeList[1];

        changedItems[key] = new Change(oldValue, newValue);

      } // ChangeSet
      else {
        changedItems[key] = new ChangeSet.fromJson(json[key]);
      }
    }
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
      if(change is Change && (change.oldValue != undefined && change.newValue != undefined))
        res[key] = change;
    });
    return res;
  }

  /**
   * Marks all the changes in [ChangeSet] or [Change] for a
   * given [dataObj].
   */

  void markChanged(dynamic key, change) {
    bool contains = changedItems.containsKey(key);
    bool oldIsChangeSet = contains && changedItems[key] is ChangeSet;
    bool newIsChangeSet = change is ChangeSet;
    bool oldIsChange = !oldIsChangeSet;
    bool newIsChange = !newIsChangeSet;

    if (!contains || oldIsChangeSet && newIsChange) {
      changedItems[key] = change.clone();
      return;
    }
    if (oldIsChange && newIsChange || oldIsChangeSet && newIsChangeSet){
      changedItems[key].mergeIn(change);
      return;
    }
    if (oldIsChange && newIsChangeSet) {
      // do nothing
      return;
    }
    // previous ifs should contain all possible cases
    assert(false);
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

  /**
   * Exports ChangeSet to JsonMap with some restriction of having map as key
   * only on top-level, in this case _id must be present.
   * This restriction does not allow to export nested [DataSet]
   */
  Map toJson({topLevel: true}) {
    Map jsonMap = {};

    for (var key in changedItems.keys) {
      var newKey;

      if(topLevel && key is Map) {
        if(!key.containsKey('_id')) throw new Exception('Key does not contain _id');
        newKey = key['_id'];
      }
      else newKey = key;

      if(!(newKey is String || newKey is num))
        throw new Exception('Key or key[\'id\'] must be primitive type');


      if (changedItems[key] is ChangeSet) {
        jsonMap[newKey] = changedItems[key].toJson(topLevel: false);
        continue;
      }
      else {
        jsonMap[newKey] = [changedItems[key].oldValue, changedItems[key].newValue]
          .map((E) => E == undefined ? CLEAN_UNDEFINED : E).toList();
      }
    }

    return jsonMap;
  }
}

/**
 * Applies json ChangeSet to [CleanSet], [CleanData], [CleanList].
 * If cleanData is DataSet, index on '_id' must be set.
 */

void applyJSON(Map jsonChangeSet, cleanData) {
  if(cleanData is DataSet) {
    jsonChangeSet.forEach((key, change) {
      if(change is List) {
        if(change[0] != CLEAN_UNDEFINED)
          cleanData.remove(cleanData.findBy('_id', key).single);
        if(change[1] != CLEAN_UNDEFINED)
         cleanData.add(change[1]);
      }
      else
        applyJSON(change, cleanData.findBy('_id', key).single);
    });
  }
  else if(cleanData is DataMap) {
    jsonChangeSet.forEach((key, change) {
      if(change is List) {
        if (change[1] != CLEAN_UNDEFINED) {
          cleanData[key] = change[1];
        } else {
            cleanData.remove(key);
        }
      }
      else applyJSON(change, cleanData[key]);
    });
  }
  else if(cleanData is DataList) {
    jsonChangeSet.forEach((key, change) {
      if(change is List) {
        if (change[1] == CLEAN_UNDEFINED) {
          cleanData.removeAt(key);
        } else if(change[0] == CLEAN_UNDEFINED) {
          cleanData.add(change[1]);
        }
        else {
          cleanData[key] = change[1];
        }
      }
      else applyJSON(change, cleanData[key]);
    });
  }
}

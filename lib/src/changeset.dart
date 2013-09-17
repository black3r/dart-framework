// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class Change {
  dynamic oldValue;
  dynamic newValue;
  
  apply(Change change) {
    newValue = change.newValue;
  }

  Change.fromValues(this.oldValue, this.newValue);
}

class ChangeSet {
  Set addedChildren = new Set();
  Set removedChildren = new Set();
  /* <children,Change> or <children, ChangeSet> */
  Map changedChildren = new Map();
  
  ChangeSet();
  factory ChangeSet.from(ChangeSet other) {
    var changeSet = new ChangeSet();
    changeSet.apply(other);
    return changeSet;
  }
  
  void addChild(dynamic child) {
    if(this.removedChildren.contains(child)) {
      this.removedChildren.remove(child);
    } else {
      this.addedChildren.add(child);
    }
  }
  
  void removeChild(dynamic child) {
    if(addedChildren.contains(child)) {
      this.addedChildren.remove(child);
    } else {
      this.removedChildren.add(child);
    }
  }
  
  void changeChild(dynamic child, ChangeSet changeSet) {
    if(this.addedChildren.contains(child)) return;
    
    if(this.changedChildren.containsKey(child)) {
      this.changedChildren[child].apply(changeSet);
    } else {
      this.changedChildren[child] = changeSet;
    }
  }
  
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
   * Removes all changes
   */
  void clear() {
    this.addedChildren.clear();
    this.removedChildren.clear();
    this.changedChildren.clear();
  }
  
  /*
   * Return if there are any changes
   */
  bool get isEmpty =>
      this.addedChildren.isEmpty && this.removedChildren.isEmpty &&
        this.changedChildren.isEmpty;
  
}

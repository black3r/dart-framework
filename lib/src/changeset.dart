// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class Change {
  var oldValue;
  var newValue;
  
  apply(Change change){
    newValue = change.newValue;
  }
  Change();
  Change.fromValues(this.oldValue,this.newValue);
  Change.withNew(this.newValue);
  
  toString(){
    return oldValue.toString() + ' '+  newValue.toString();
  }
}

class ChangeSet {
  Set addedChildren = new Set();
  Set removedChildren = new Set();
  /* <children,Change> or <children, ChangeSet> */
  Map changedChildren = new Map();
  
  addChild(child){
    if(this.removedChildren.contains(child)){
      this.removedChildren.remove(child);
    }
    else {
      this.addedChildren.add(child);
    }
  }
  
  removeChild(child){
    if(addedChildren.contains(child)){
      this.addedChildren.remove(child);
    }
    else {
      this.removedChildren.add(child);
    }
  }
  
  changeChild(child, changeSet){
    if(this.addedChildren.contains(child))
      return;
    if(this.changedChildren.containsKey(child)){
      this.changedChildren[child].apply(changeSet);
    }
    else {
      this.changedChildren[child] = changeSet;
    }
  }
  
  apply(ChangeSet changeSet){
    for(var child in changeSet.addedChildren)
      this.addChild(child);
    for(var child in changeSet.removedChildren)
      this.removeChild(child);
    changeSet.changedChildren.forEach( (child,changeSet){
      this.changeChild(child,changeSet);
    });
  }
  
  /**
   * Removes all changes
   */
  clear(){
    this.addedChildren.clear();
    this.removedChildren.clear();
    this.changedChildren.clear();
  }
  
  /*
   * Return if there are any changes
   */
  bool get isEmpty =>
      this.addedChildren.isEmpty && this.removedChildren.isEmpty 
        && this.changedChildren.isEmpty;
  
  String toString(){
    var sb = new StringBuffer();
    sb.writeln('AddedChildren: ' + this.addedChildren.toString());
    sb.writeln('RemovedChildren: ' + this.removedChildren.toString());
    sb.writeln('ChangedChildren: ' + this.changedChildren.toString());
    return sb.toString();
  }
}

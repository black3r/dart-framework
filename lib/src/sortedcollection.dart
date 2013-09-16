// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class SortedCollection extends ChildCollection {
  final compare;

  /**
   * Creates a [SortedCollection] from a parent [Collection] and a compare function.
   *
   * Compare function should be compatible with [List]'s sort() method.
   */
  SortedCollection(Collection parent, this.compare) : super(parent) {
    this.update(silent: true);
  }

  void update({silent: false}) {
    var removed = this._modelsList.toList();

    this._clear();
    for (var model in parent._modelsList) {
      this._add(model);
    }
    this._modelsList.sort(this.compare);

    var added = this._modelsList.toList();
    for(model in added)
      this.changeSet.addChild(model);
    for(model in removed)
      this.changeSet.removeChild(model);
        
    this._onChangeController.add(changeSet);
  }
}
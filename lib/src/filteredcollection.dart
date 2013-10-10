// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;


class FilteredCollection extends ChildCollection {
  final test;

  /**
   * Creates a [FilteredCollection] from a parent [Collection] and a [test] function.
   *
   * Filter function should return bool == True if a model passes the [test],
   * false if it does not pass (should not be included).
   */
  FilteredCollection(Collection parent, this.test) : super(parent) {
    this.update(silent: true);
  }

  void update({silent: false}) {
    var removed = this._modelsList.toList();
    this._clear();
    for (var model in parent._modelsList) {
      if (this.test(model)) {
        this._add(model);
      }
    }
    if(!silent) {
      var added = this._modelsList.toList();
      
      for(Model model in removed) {
        this.changeSet.removeChild(model);
      }
      for(Model model in added) {
        this.changeSet.addChild(model);
      }
      notify();
    }
  }
}

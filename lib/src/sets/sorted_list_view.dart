// Copyright (c) 2014, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class SortedDataListView extends TransformedDataList {
  dynamic _sorter;
  dynamic _refmap = {};

  SortedDataListView(source, this._sorter) : super([source]) {
    for (var value in source) {
      _silentAdd(value);
    }
    _list.sort((a, b) => this._sorter(a is DataReference ? a.value : a, b is DataReference ? b.value : b));
  }

  SortedDataListView.fromKey(source, key) : super([source]) {
    for (var value in source) {
      _silentAdd(value);
    }
    this._sorter = (a, b) {
      return key(a).compareTo(key(b));
    };
    _list.sort((a, b) => this._sorter(a is DataReference ? a.value : a, b is DataReference ? b.value : b));
  }

  void _treatAddedItem(dataObj, int sourceNumber) {
    _add(refcl(dataObj));
    _sort(this._sorter);
    _notify();
  }

  void _treatRemovedItem(dataObj, int sourceNumber) {
    bool removed = false;
    for(int i = 0; i < _list.length; i++) {
      if(_list[i] is DataReference) {
        if(_list[i].value == dataObj) { _remove(i); break; }
      }
      else if(_list[i] == dataObj) { _remove(i); break; }
    }
    _notify();
  }

  void _treatChangedItem(dataObj, ChangeSet c, int sourceNumber) {
    _sort(this._sorter);
    _notify();
  }
}
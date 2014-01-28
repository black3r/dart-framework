// Copyright (c) 2014, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class MappedDataSetView extends TransformedDataSet {
  dynamic _map;
  dynamic _mapper = {};
  MappedDataSetView(DataSetView source, this._map) : super([source]) {
    for (var dataObj in source) {
      _mapper[dataObj] = _map(dataObj);
      _data.add(_mapper[dataObj]);
    }
  }

  void _treatAddedItem(dataObj, int sourceNumber) {
    _addAll([_map(dataObj)]);
  }

  void _treatRemovedItem(dataObj, int sourceNumber) {
    if (_mapper.containsKey(dataObj))
      _removeAll([_mapper[dataObj]]);
  }
}
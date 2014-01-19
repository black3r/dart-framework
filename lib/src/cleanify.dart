// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSfile.

part of clean_data;

ChangeNotificationsMixin cleanify(data) {
  var ret;
  if(data is List || data is Map || data is Set || data is Iterable) {
    return _cleanify(data);
  }
  else {
    return new DataReference(data);
  }
}

_cleanify(data) {
  var ret;
  if(data is List) {
    return new DataList.from(data.map((elem) => _cleanify(elem)));
  }
  else if(data is Map) {
    Map map = new Map();
    data.forEach((K, V) => map[K] = _cleanify(V));
    return new DataMap.from(map);
  }
  else if(data is Set || data is Iterable || data is Iterator) {
    if(data is Iterator) data = new List(data);
    return new DataSet.from(data.map((elem) => _cleanify(elem)));
  }
  else {
    return data;
  }
}

dynamic decleanify(data) {
  if(data is DataList) {
    return new List.from(data.map((value) => decleanify(value)));
  }
  else if(data is DataMap) {
    return new Map.fromIterables(data.keys, data.values.map((value) => decleanify(value)));
  }
  else if(data is DataSet) {
    return new Set.from(data.map((value) => decleanify(value)));
  }
  else if(data is DataReference) {
    return data.value;
  }
  else {
    return data;
  }
}
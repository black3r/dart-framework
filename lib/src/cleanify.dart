// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSfile.

part of clean_data;

cleanify(data) {
  if (data is ChangeNotificationsMixin) {
    return data;
  }
  if(data is List) {
    return new DataList.from(data);
  }
  else if(data is Map) {
    return new DataMap.from(data);
  }
  else if(data is Set || data is Iterable || data is Iterator) {
    if(data is Iterator) data = new List(data);
    return new DataSet.from(data);
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

_clone(data) {
  return cleanify(decleanify(data));
}

ChangeNotificationsMixin clone(data) {
  if (data is DataList || data is DataMap || data is DataSet) {
    return _clone(data);
  }
}
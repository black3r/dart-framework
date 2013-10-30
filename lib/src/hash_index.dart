// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

class IndexException implements Exception{
  String cause;
  IndexException(this.cause);
}

class HashIndex<E> {
  
  Map<dynamic, Set<E>> _index = new Map<dynamic, Set<E>>();
  
  HashIndex();
  
  Set<E> operator[](dynamic value) => _index.containsKey(value) 
                                      ? _index[value] 
                                      : new Set<E>();
  
  void add(dynamic value, E obj){
    // create the key if not exists
    if (!_index.containsKey(value)) {
      _index[value] = new Set<E>();
    }
    
    _index[value].add(obj);
  }

}
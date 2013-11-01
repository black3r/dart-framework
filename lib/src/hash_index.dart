// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents an exception that is raised when an unindexed object is 
 * attempted to be treated as an object.
 */
class NoIndexException implements Exception{
  String cause;
  NoIndexException(this.cause);
}

/**
 * Really simple inverted index implementation.
 */
class HashIndex<E> {
  HashIndex();
  
  /**
   * Holds the mapping of values to data objects.
   */
  Map<dynamic, Set<E>> _index = new Map<dynamic, Set<E>>();
  
  /**
   * Returns a set of objects that have this value. If no such
   * object exists, empty Set is returned.  
   */
  Set<E> operator[](dynamic value) => _index.containsKey(value) 
                                      ? _index[value] 
                                      : new Set<E>();
                                      
  /**
   * Adds a [value] to [object] mapping to the index.
   */
  void add(dynamic value, E object){
    if (!_index.containsKey(value)) {
      _index[value] = new Set<E>();
    }
    
    _index[value].add(object);
  }

  /**
   * Removes a [value] to [object] mapping from the index.
   */
  void remove(dynamic value, E object){
    if (_index.containsKey(value)) {
      _index[value].remove(object);
    }
  }
}
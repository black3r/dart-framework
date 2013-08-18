// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library mvc.collection.sorted;
import 'model.dart';
import 'collection.dart';
import 'childcollection.dart';
import "dart:core";

class SortedCollection extends ChildCollection {  
  var compare_function;
  List<Model> sorted;
  Model operator[](key) => sorted[key];
  
  /**
   * Creates a [SortedCollection] from a parent [Collection] and a compare function.
   * 
   * Compare function should be compatible with [List]'s sort() method.
   */
  SortedCollection(Collection parent, filter) : super(parent) {
    this.read_only = true;
    this.compare_function = filter;
    this.sortCollection();
  }
  
  /**
   * (Re)sorts the collection.
   */
  void sortCollection() {
    sorted = new List<Model>();
    this.models.forEach((id, Model model) {
      sorted.add(model);
    });
    sorted.sort(compare_function);
  }
  
  /**
   * Adds the model and sorts the collection again.
   */
  void modelAdded(Model model) {
    this.read_only = false;
    this.add(model);
    this.sortCollection();
    this.read_only = true;
  }
  
  /**
   * Sorts the collection again.
   */
  void modelChanged(Model model, Map oldkeys, Map newkeys) {    
    this.sortCollection();
  }
 
  /**
   * Removes the model from the collection.
   */
  void modelRemoved(Model model) {
    this.read_only = false;
    this.remove(model);
    this.sortCollection();
    this.read_only = true;
  }
}
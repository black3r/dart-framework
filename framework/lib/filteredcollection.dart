// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library mvc.collection.filtered;
import 'model.dart';
import 'collection.dart';
import 'childcollection.dart';
import "dart:core";

class FilteredCollection extends ChildCollection {  
  var filter_function;
  
  /**
   * Creates a [FilteredCollection] from a parent [Collection] and a filter function.
   * 
   * Filter function should return bool == True if a model passes the filter,
   * false if it does not pass (should not be included)
   */
  FilteredCollection(Collection parent, filter) : super(parent) {
    this.read_only = true;
    this.filter_function = filter;
    this.filterCollection();
  }
  
  /**
   * Removes every [Model] that does not pass current filter from this [FilteredCollection].
   */
  void filterCollection() {    
    var toRemove = [];
    this.models.forEach((id,Model model) {
      if (!this.filterModel(model)) {
        toRemove.add(model);
      }
    });
    toRemove.forEach((Model model) {
      this.models.remove(model.id);      
    });    
  }
  
  /**
   * Checks if a [Model] passes through the filter.
   */
  bool filterModel(Model model) {
    return this.filter_function(model);
  }
  
  /**
   * Adds the [Model] to the collection if it passes the filter
   */
  void modelAdded(Model model) {
    this.read_only = false;
    if (this.filterModel(model)) {
      this.add(model);      
    }
    this.read_only = true;
  }  
  
  /**
   * If the [Model] didn't pass the filter before and now does, adds it.
   * If it passed the filter before and now it doesn't, removes it.
   */
  void modelChanged(Model model, Map oldkeys, Map newkeys) {
    this.read_only = false;
    if(this.contains(model)) {
      if (!this.filterModel(model)) {
        this.remove(model);
      }
    } else {
      if (this.filterModel(model)) {
        this.add(model);
      }
    }  
    this.read_only = true;
  }
 
  /**
   * If the model is in this collection removes it.
   */
  void modelRemoved(Model model) {
    this.read_only = false;
    this.remove(model);
    this.read_only = true;
  }
}
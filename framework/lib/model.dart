// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library mvc.model;
import "dart:core";
import "dart:async";

/**
 * Model
 */
class Model {
  Map _fields;
  dynamic get id => _fields['id'];
  dynamic operator[](key) => this._fields[key];
  
  Stream<Map> events;
  StreamController<Map> _eventsController;  

  /**
   * Creates a new model with set id
   */
  Model(id) {
    this._fields = new Map();
    this._fields['id'] = id;
    this.createEventStreams();
  }

  /**
   * Creates publicly accessible Event Streams.
   */
  void createEventStreams() {
    this._eventsController = new StreamController<Map>.broadcast();
    this.events = this._eventsController.stream;
  }

  /**
   * Creates a new model with set id and fields
   */
  Model.fromData(id, this._fields) {
    this.createEventStreams();
  }
  
  /**
   * Updates a field defined by key in model with value 
   */
  void operator[]=(String key, value) {
    if (key != 'id') {
      var new_value = value;
      if ((value is! Map) && (value is! List) && (value is! String) && (value is! int) && (value is! double) && (value is! bool)) {
        throw new ArgumentError("Model fields may only contain maps, lists & basic types"); 
      }
      // prepare event
      var old_value = this._fields[key];
      Map event = new Map();
      event['eventtype'] = 'modelChanged';
      event['old'] = new Map();
      event['old'][key] = old_value;
      event['new'] = new Map();
      event['new'][key] = new_value;      
      event['model'] = this;
      // assign value
      this._fields[key] = new_value;
      this._eventsController.add(event);
    } else {
      throw new ArgumentError("id field is read-only");
    }
  }
}

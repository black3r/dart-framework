// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library mvc.collection;
import 'model.dart';
import "dart:core";
import "dart:async";

/**
 * Collection of entries from database
 */
class Collection {
  /// Map containing (id, model) pairs
  Map<dynamic, Model> models;  
  Stream<Map> events;
  StreamController<Map> _eventsController;  
  
  /// You can't add or change entries in a read-only collection
  bool read_only = false;
  
  /// Number of models in collection
  int get length => this.models.length;

  /**
   * Creates publicly accessible Event Streams.
   */
  void createEventStreams() {
    this._eventsController = new StreamController<Map>.broadcast();
    this.events = this._eventsController.stream;    
  }  

  /**
   * Generates Collection from list of Models
   */
  Collection.fromList(List<Model> listmodel) {
    this.models = new Map<dynamic, Model>();
    listmodel.forEach((model) {
      this.models[model.id] = model;
      model.events.listen((Map event) {
        if (event['eventtype'] == 'modelChanged')
          this._eventsController.add(event);
      });
    });
    this.createEventStreams();
  }

  /**
   * Generates an empty collection with no parent
   */
  Collection() {
    this.models = new Map<dynamic, Model>();    
    this.createEventStreams();
  }
  
  /**
   * Adds model to collection if it isn't already contained.
   * 
   * Models should have unique id's.
   */
  void add(Model model, [bool sendEvents = true]) {
    if (this.read_only) {
      throw new Exception("Read-Only collections can't be edited!");
    }
    if (!this.models.containsKey(model.id)) {
      this.models[model.id] = model;
      if (sendEvents) {
        var event = new Map();        
        event['model'] = model;
        event['eventtype'] = 'modelAdded';
        this._eventsController.add(event);                
        model.events.listen((Map event) {
          if (event['type'] == 'modelChanged') 
            this._eventsController.add(event);
        });
      }
    }
  }

  /**
   * Removes a model from collection
   */
  void remove(Model model, [bool sendEvents = true]) {
    if (this.read_only) {
      throw new Exception("Read-Only collections can't be edited!");
    }    
    if (this.models.containsKey(model.id)) {
      this.models.remove(model.id);      
      if (sendEvents) {
        var event = new Map();        
        event['model'] = model;
        event['eventtype'] = 'modelRemoved';
        this._eventsController.add(event);
      }
    } else {
      throw new ArgumentError("No such model in this collection: $model.id");
    }
  }
  
  /**
   * Gets model specified by id
   */
  Model get(id) => this.models[id];
  /**
   * Gets model specified by id
   */
  Model operator[](id) => this.get(id);

  /**
   * Checks if this [Collection] contains selected [Model].
   */
  bool contains(Model model) {
    return this.models.containsKey(model.id); 
  }

}
// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * DataView
 * Listens to changes on [source] and transforms ([_remap]) itself correspondingly.
 * Clients could listen to its changes.
 */
class MappedDataView extends DataView {

  /**
   * Source [DataView] object this object is derived from.
   */
  final DataView source;
  StreamSubscription _sourceSubscription;

  /**
   * Mapping function that maps a [DataView] to another [DataView]
   */
  final DataTransformFunction _mapping;

  MappedDataView(DataView this.source, DataTransformFunction this._mapping) {
    var mappedObj = this._mapping(source);
    for (var key in mappedObj.keys) {
      _fields[key] = mappedObj[key];
    }
    _sourceSubscription = source.onChange.listen((c) =>_remap());
  }

  /**
   * Re-applies the mapping transformation on this data object.
   * TODO: Rewrite to work with synced.
   */
  void _remap() {
    var mappedObj = _mapping(source);
    Set allKeys = new Set.from(mappedObj.keys)
                        .union(new Set.from(_fields.keys));
    allKeys.forEach((key){

      // key does not appear in the new mapping
      if(!mappedObj.keys.contains(key)) {
        _fields.remove(key);
        _markRemoved(key);
        return;
      }

      // key does not appear in the previously mapped object
      if (!_fields.keys.contains(key)) {
        _markAdded(key);
      }

      // key is in both objects, but the value was maybe changed
      if (_fields[key] != mappedObj[key]) {
          _markChanged(key, new Change(_fields[key], mappedObj[key]));
      }

      // make sure the mapped property is updated
      _fields[key] = mappedObj[key];
    });

    // broadcast the changes if needed. Anyway, clear them before leaving.
    _notify();
  }

  void dispose() {
    _sourceSubscription.cancel();
  }
}

/**
 * Represents a read-only data collection that is a result of a mapping operation on another collection.
 */
//It took me a lot time to figure out so:
//DevNote: [add, remove] goes source -> This -> MappedDataView & others
//DevNote: [change] goes source_data_object -> MappedDataView -> This -> others
//DevNote: MappedCollection doesn't need DCLMixin.removedObjects
//  (as it has full power over them and recreates them when they are readed)
class MappedCollectionView extends TransformedDataCollection with DataChangeListenersMixin {

  final _mapping;

  /**
   * Creates a new data collection from [source] where each element e from [source]
   * is replaced by the result of mapping(e).
   */
  MappedCollectionView(DataCollectionView source, DataTransformFunction this._mapping): super([source]) {
    // Runs the initial mapping on the source collection.
    sources[0].forEach((DataView d) => _addMapped(d));
    _clearChanges();
  }

  /**
   * Adds a mapped data object and starts listening to changes on it.
   */
  void _addMapped(DataView dataObj) {
    MappedDataView mappedObj = new MappedDataView(dataObj, _mapping);
    _markAdded(mappedObj);

    _data.add(mappedObj);

    _addOnDataChangeListener(mappedObj);
  }

  void _treatAddedItem(DataView d, int sourceNumber) => _addMapped(d);

  void _treatRemovedItem(DataView dataObj, int sourceNumber) {
    // find the mapped object and mark it as removed
    DataView mappedDataObj = _data.toList().where((d) => d.source == dataObj).first;

    _markRemoved(mappedDataObj);

    // remove the mapped object and its stream subscription as well
    _data.remove(mappedDataObj);

    // remove listeners mappedDataObj -> source and this -> mappedDataObj
    mappedDataObj.dispose();
    _removeOnDataChangeListener(mappedDataObj);
  }

  void dispose(){
    super.dispose();
    _dataListeners.forEach((data, subscription) => subscription.cancel());
    _data.forEach((mdw) => mdw.dispose());
  }
}
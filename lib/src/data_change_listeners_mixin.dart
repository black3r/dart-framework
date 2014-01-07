part of clean_data;

abstract class DataChangeListenersMixin<T> {

  void _markChanged(T key, changeSet);
  void _notify({author});
  /**
   * Internal Set of data objects removed from Collection that still have DataListener listening.
   */
  Set<T> _removedObjects = new Set();
  /**
   * Internal set of listeners for change events on individual data objects.
   */
  final Map<dynamic, StreamSubscription> _dataListeners =
      new Map<dynamic, StreamSubscription>();

  /**
   * Removes listeners to all objects which have been removed and stacked in [_removedObjects]
   */
  void _onBeforeNotify() {
    // if this object was removed and then re-added in this event loop, don't
    // destroy onChange listener to it.
    for(T key in _removedObjects.toList()) {
      _removeOnDataChangeListener(key);
    }
    _removedObjects.clear();
  }

  /**
   * Starts listening to changes on [dataObj].
   */
  void _addOnDataChangeListener(T key, DataReference dataObj) {
    if (_dataListeners.containsKey(dataObj)) return;

    _dataListeners[key] = dataObj.onChangeSync.listen((changeEvent) {
      _markChanged(key, changeEvent['change']);
      _notify(author: changeEvent['author']);
    });
  }

  /**
   * Stops listening to changes on [dataObj]
   * Second possibility is to add to [_removedObjects] and call [_onBeforeNotify]
   */
  void _removeAllOnDataChangeListeners() {
    for(T key in _removedObjects.toList()) {
      _removeOnDataChangeListener(key);
    }
  }

  void _removeOnDataChangeListener(T key) {
    if (_dataListeners.containsKey(key)) {
      _dataListeners[key].cancel();
      _dataListeners.remove(key);
    }
  }
}

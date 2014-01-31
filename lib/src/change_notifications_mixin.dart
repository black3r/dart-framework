part of clean_data;


abstract class ChangeNotificationsMixin {

  /**
   * Controlls notification streams. Used to propagate change events to the outside world.
   */
  final StreamController<dynamic> _onChangeController =
      new StreamController.broadcast();

  final StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);

  /**
   * [_change] and [_changeSync] are either of a type Change or ChangeSet depending
   * on concrete implementation of a mixin
   */
  get _change;
  get _changeSync;

  /**
   * following wanna-be-abstract methods must be overriden
   */
  void _clearChanges();
  void _clearChangesSync();
  void _onBeforeNotify() {}


  /**
   * Stream populated with [ChangeSet] events whenever the collection or any
   * of data object contained gets changed.
   */
  Stream<ChangeSet> get onChange => _onChangeController.stream;

  /**
   * Stream populated with {'change': [ChangeSet], 'author': [dynamic]} events
   * synchronously at the moment when the collection or any data object contained
   * gets changed.
   */
  Stream<Map> get onChangeSync => _onChangeSyncController.stream;

  /**
   * Used to propagate change events to the outside world.
   */
  final StreamController<dynamic> _onBeforeAddedController =
      new StreamController.broadcast(sync: true);
  final StreamController<dynamic> _onBeforeRemovedController =
      new StreamController.broadcast(sync: true);

  /**
   * Stream populated with [DataMapView] events before any
   * data object is added.
   */
   Stream<dynamic> get onBeforeAdd => _onBeforeAddedController.stream;

  /**
   * Stream populated with [DataMapView] events before any
   * data object is removed.
   */
   Stream<dynamic> get onBeforeRemove => _onBeforeRemovedController.stream;

  /**
   * Streams all new changes marked in [_change].
   */
  void _notify({author: null}) {
    if (!_changeSync.isEmpty) {
      _onChangeSyncController.add({'author': author, 'change': _changeSync});
      _clearChangesSync();
    }

    Timer.run(() {
      if (!_change.isEmpty) {
        _onBeforeNotify();
        _onChangeController.add(_change);
        _clearChanges();
      }
    });
  }

  void _closeChangeStreams(){
    _onChangeController.close();
    _onChangeSyncController.close();
  }

}

abstract class ChangeChildNotificationsMixin implements ChangeNotificationsMixin {
  /**
   * Holds pending changes.
   */
  ChangeSet _change = new ChangeSet();
  ChangeSet _changeSync = new ChangeSet();

  /**
   * Internal set of listeners for change events on individual data objects.
   */
  final Map<dynamic, StreamSubscription> _dataListeners =
      new Map<dynamic, StreamSubscription>();

  _clearChanges() {
    _change = new ChangeSet();
  }

  _clearChangesSync() {
    _changeSync = new ChangeSet();
  }

  _markAdded(dynamic key, dynamic value) {
    _onBeforeAddedController.add(key);
    _changeSync.markAdded(key, value);
    _change.markAdded(key, value);
  }

  _markRemoved(dynamic key, dynamic value) {
    _onBeforeRemovedController.add(key);
    _change.markRemoved(key, value);
    _changeSync.markRemoved(key, value);
  }

  _markChanged(dynamic key, dynamic change) {
    if(change is Change) {
      if(change.oldValue == undefined)
        _onBeforeAddedController.add(key);
      if(change.newValue == undefined)
        _onBeforeAddedController.add(key);
    }
    _change.markChanged(key, change);
    _changeSync.markChanged(key, change);
  }

  /**
   * Starts listening to changes on [dataObj].
   */
  void _addOnDataChangeListener(key, dataObj) {
    if (_dataListeners.containsKey(dataObj)) return;

    _dataListeners[key] = dataObj.onChangeSync.listen((changeEvent) {
      _markChanged(key, changeEvent['change']);
      _notify(author: changeEvent['author']);
    });
  }

  void _removeOnDataChangeListener(key) {
    if (_dataListeners.containsKey(key)) {
      _dataListeners[key].cancel();
      _dataListeners.remove(key);
    }
  }

  void _dispose() {
    _closeChangeStreams();
    _dataListeners.forEach((K, V) => V.cancel());
    _onBeforeAddedController.close();
    _onBeforeRemovedController.close();
  }
}

abstract class ChangeValueNotificationsMixin implements ChangeNotificationsMixin {
  Change _change = new Change();
  Change _changeSync = new Change();

  _clearChanges() {
    _change = new Change();
  }

  _clearChangesSync() {
    _changeSync = new Change();
  }

  _markChanged(dynamic oldValue, dynamic newValue) {
    Change change = new Change(oldValue, newValue);
    _changeSync.mergeIn(change);
    _change.mergeIn(change);
  }

  void _dispose(){
    _closeChangeStreams();
  }

}

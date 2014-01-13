part of clean_data;

abstract class ChangeNotificationsMixin {

  /**
   * Controlls notification streams. Used to propagate change events to the outside world.
   */
  final StreamController<dynamic> _onChangeController =
      new StreamController.broadcast();

  final StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);

  get __change;
  get __changeSync;
  _clearChanges();
  _clearChangesSync();
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
   * Stream populated with [DataView] events before any
   * data object is added.
   */
   Stream<dynamic> get onBeforeAdd => _onBeforeAddedController.stream;

  /**
   * Stream populated with [DataView] events before any
   * data object is removed.
   */
   Stream<dynamic> get onBeforeRemove => _onBeforeRemovedController.stream;


  /**
   * Streams all new changes marked in [_change].
   */
  void _notify({author: null}) {
    if (!__changeSync.isEmpty) {
      _onChangeSyncController.add({'author': author, 'change': __changeSync});
      _clearChangesSync();
    }

    Timer.run(() {
      if (!__change.isEmpty) {
        _onBeforeNotify();
        _onChangeController.add(__change);
        _clearChanges();
      }
    });
  }
}

abstract class ChangeChildNotificationsMixin implements ChangeNotificationsMixin {
  /**
   * Holds pending changes.
   */
  ChangeSet _changeSet = new ChangeSet();
  ChangeSet _changeSetSync = new ChangeSet();

  get __change => _changeSet;
  get __changeSync => _changeSetSync;

  _clearChanges() {
    _changeSet = new ChangeSet();
  }

  _clearChangesSync() {
    _changeSetSync = new ChangeSet();
  }

  _markAdded(dynamic key, dynamic value) {
    _onBeforeAddedController.add(key);

    _changeSetSync.markAdded(key, value);
    _changeSet.markAdded(key, value);
  }

  _markRemoved(dynamic key, dynamic value) {
    _onBeforeRemovedController.add(key);

    _changeSet.markRemoved(key, value);
    _changeSetSync.markRemoved(key, value);
  }

  _markChanged(dynamic key, dynamic change) {
    _changeSet.markChanged(key, change);
    _changeSetSync.markChanged(key, change);
  }

  /**
   * Streams all new changes marked in [changeSet].
   */
  void _notify({author: null}) {
    if (!_changeSetSync.isEmpty) {
      _onChangeSyncController.add({'author': author, 'change': _changeSetSync});
      _clearChangesSync();
    }

    Timer.run(() {
      if (!_changeSet.isEmpty) {
        _onBeforeNotify();
        _onChangeController.add(_changeSet);
        _clearChanges();
      }
    });
  }
}

abstract class ChangeValueNotificationsMixin implements ChangeNotificationsMixin {
  Change _change = new Change();
  Change _changeSync = new Change();

  get __change => _change;
  get __changeSync => _changeSync;

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

}





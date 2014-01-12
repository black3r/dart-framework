part of clean_data;

abstract class ChangeNotificationsMixin {
  /**
   * Holds pending changes.
   */
  ChangeSet _changeSet = new ChangeSet();
  ChangeSet _changeSetSync = new ChangeSet();
  Change _change = null;
  Change _changeSync = null;

  /**
   * Controlls notification streams. Used to propagate change events to the outside world.
   */
  final StreamController<dynamic> _onChangeController =
      new StreamController.broadcast();

  final StreamController<Map> _onChangeSyncController =
      new StreamController.broadcast(sync: true);

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

  //======= changeSet manipulators =======

  _clearChanges() {
    _changeSet = new ChangeSet();
    _change = null;
  }

  _clearChangesSync() {
    _changeSetSync = new ChangeSet();
    _changeSync = null;
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

  _markChange(dynamic oldValue, dynamic newValue) {
    var change = new Change(oldValue, newValue);
    if (_change == null) {
      _change = change.clone();
    } else {
      _change.mergeIn(change);
    }
    if (_changeSync == null) {
      _changeSync = change.clone();
    } else {
      _changeSync.mergeIn(change);
    }
  }

  //======= /changeSet manipulators =======

  /**
   * Streams all new changes marked in [changeSet].
   */
  void _onBeforeNotify() {}

  void _notify({author: null}) {
    if (_changeSync != null) {
      _onChangeSyncController.add({'author': author, 'change': _changeSync});
      _clearChangesSync();
    } else
    if (!_changeSetSync.isEmpty) {
      _onChangeSyncController.add({'author': author, 'change': _changeSetSync});
      _clearChangesSync();
    }

    Timer.run(() {
      var change;
      if (_change != null) {
        change = _change;
      } else
      if (!_changeSet.isEmpty) {
        change = _changeSet;
      }
      if (change != null) {
        _onBeforeNotify();
        _onChangeController.add(change);
        _clearChanges();
      }
    });
  }
}

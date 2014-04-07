// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class FilteredDataSetBase extends TransformedDataSet {

  FilteredDataSetBase(List<DataSetView> sources) : super(sources) {
    // Performs the initial minus operation.
    for (var i = 0; i < sources.length; i++) {
      for (var dataObj in sources[i]) {
        if (_shouldContain(dataObj)) {
          _data.add(dataObj);
        }
      }
    }
  }

  /**
   * Returns true if [dataObj] should be present in the set.
   */
  bool _shouldContain(dataObj);

  /**
   * Decides whether a [dataObj] that has changed in the [source] set
   * should be added/changed/removed in this filtered set.
   */
  void _treatItem(dataObj, ChangeSet changes) {
    bool shouldBeContained = _shouldContain(dataObj);
    bool isContained = _data.contains(dataObj);

    if (isContained) {
      if (changes != null) {
        _markChanged(dataObj, changes);
      }

      if (!shouldBeContained) {
        _markRemoved(dataObj, dataObj);
        _data.remove(dataObj);
      }

    } else if(shouldBeContained) {
        _markAdded(dataObj, dataObj);
        _data.add(dataObj);
    }
  }
}
/**
 * Represents a read-only data set that is a result of a filtering
 * operation on another collection.
 */
class FilteredDataSetView extends FilteredDataSetBase {

  dynamic _filter;
  ChangeNotificationsMixin _args;
  StreamSubscription subscribtion = null;
  /**
   * Creates a new filtered data set from [source], using [filter].
   */
  FilteredDataSetView(DataSetView source,
      this._filter, [ChangeNotificationsMixin this._args = null]): super([source]) {
    if(_args != null) subscribtion = _args.onChangeSync.listen((_) {
      changeFilter(this._filter, _args);
    });
  }

  bool _shouldContain(dataObj) => sources[0].contains(dataObj) &&
      ((this._args == null && _filter(dataObj)) ||
          (this._args != null && _filter(dataObj, this._args)));

  changeFilter(newFilter, [ChangeNotificationsMixin newArgs = null]) {
    if(newArgs != _args) {
      if(subscribtion != null) subscribtion.cancel();
      if(_args != null) {
        subscribtion = _args.onChangeSync.listen((_) {
          changeFilter(this._filter, _args);
        });
      }
    }
    _args = newArgs;
    _filter = newFilter;
    for(var item in sources[0]) _treatItem(item, null);

    _notify();
  }
}


/**
 * Represents a read-only data set that is a result of an minus operation of two sets.
 */
class ExceptedDataSetView extends FilteredDataSetBase {

  /**
   * Creates a new data set from [source1] and [source2] only with elements that appear in A but not B.
   */
  ExceptedDataSetView(DataSetView source1,
      DataSetView source2): super([source1, source2]);

  bool _shouldContain(dataObj) =>
    sources[0].contains(dataObj) && !sources[1].contains(dataObj);


}

class IntersectedDataSetView extends FilteredDataSetBase {
  /**
   * Creates a new data set from [source1] and [source2] only with
   * elements that appear in both collections.
   */
  IntersectedDataSetView(DataSetView source1,
      DataSetView source2): super([source1, source2]);

  bool _shouldContain(dataObj) => sources[0].contains(dataObj) &&
      sources[1].contains(dataObj);
}

class UnionedDataSetView extends FilteredDataSetBase {
  /**
   * Creates a new data set from [source1] and [source2] with elements
   * that appear in at least one of the collections.
   */
  UnionedDataSetView(DataSetView source1,
      DataSetView source2): super([source1, source2]);

  bool _shouldContain(dataObj) => sources[0].contains(dataObj) ||
      sources[1].contains(dataObj);
}

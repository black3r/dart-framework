// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

abstract class FilteredCollectionBase extends TransformedDataCollection {

  FilteredCollectionBase(List<DataCollectionView> sources) : super(sources) {
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
   * Returns true if [dataObj] should be present in the collection.
   */
  bool _shouldContain(dataObj);

  /**
   * Decides whether a [dataObj] that has changed in the [source] collection
   * should be added/changed/removed in this filtered collection.
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
 * Represents a read-only data collection that is a result of a filtering
 * operation on another collection.
 */
class FilteredCollectionView extends FilteredCollectionBase {

  final _filter;

  /**
   * Creates a new filtered data collection from [source], using [filter].
   */
  FilteredCollectionView(DataCollectionView source,
      DataTestFunction this._filter): super([source]);

  bool _shouldContain(dataObj) => sources[0].contains(dataObj) &&
      _filter(dataObj);
}

/**
 * Represents a read-only data collection that is a result of an minus operation of two collections.
 */
class ExceptedCollectionView extends FilteredCollectionBase {

  /**
   * Creates a new data collection from [source1] and [source2] only with elements that appear in A but not B.
   */
  ExceptedCollectionView(DataCollectionView source1,
      DataCollectionView source2): super([source1, source2]);

  bool _shouldContain(dataObj) =>
    sources[0].contains(dataObj) && !sources[1].contains(dataObj);


}

class IntersectedCollectionView extends FilteredCollectionBase {
  /**
   * Creates a new data collection from [source1] and [source2] only with
   * elements that appear in both collections.
   */
  IntersectedCollectionView(DataCollectionView source1,
      DataCollectionView source2): super([source1, source2]);

  bool _shouldContain(dataObj) => sources[0].contains(dataObj) &&
      sources[1].contains(dataObj);
}

class UnionedCollectionView extends FilteredCollectionBase {
  /**
   * Creates a new data collection from [source1] and [source2] with elements
   * that appear in at least one of the collections.
   */
  UnionedCollectionView(DataCollectionView source1,
      DataCollectionView source2): super([source1, source2]);

  bool _shouldContain(dataObj) => sources[0].contains(dataObj) ||
      sources[1].contains(dataObj);
}

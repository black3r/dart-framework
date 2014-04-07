// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Represents a read-only, iterable data collection that is a result of a transformation operation.
 */
abstract class TransformedDataSet extends DataSetView with TransformedDataBase{

  TransformedDataSet(List<ChangeNotificationsMixin> sources) {
    this.sources = sources;
    _sourcesSubscription = new List(this.sources.length);

    for (var i = 0; i < sources.length; i++) {
      this._sourcesSubscription[i] =
          this.sources[i].onChangeSync.listen((change) => _mergeIn(change['change'], i));
    }
  }

  void dispose() {
    _sourcesSubscription.forEach((subscription) => subscription.cancel());
    super.dispose();
  }
}

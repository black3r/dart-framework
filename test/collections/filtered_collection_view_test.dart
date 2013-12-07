// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library filtered_collection_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(FilteredCollectionView)', () {

    setUp(() => setUpMonths());

    test('simple filtering. (T01)', () {
      // given

      // when
      var evenMonths = months.liveWhere((month) => month['number'] % 2 == 0);

      // then
      expect(evenMonths, unorderedEquals([february, april, june, august,
                                          october, december]));
    });

    test('multiple filtering. (T02)', () {
      // given
      var evenMonths = months.liveWhere((month) => month['number'] % 2 == 0);

      // when
      var evenLongMonths = evenMonths.liveWhere((month) => month['days'] > 30);

      // then
      expect(evenLongMonths, unorderedEquals([august, october, december]));
    });

  });
}

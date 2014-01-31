// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library filtered_set_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(FilteredsetView)', () {

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

    test('change Filter. (T03)', () {
      // given
      FilteredDataSetView evenLongMonths = months.liveWhere((month) => month['number'] % 2 == 0);
      evenLongMonths.changeFilter((month) => month['number'] % 2 == 0 && month['days'] > 30);

      // then
      expect(evenLongMonths, unorderedEquals([august, october, december]));
      evenLongMonths.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet.removedItems.length, equals(3));
      }));
    });

    test('change args of filter. (T04)', () {
      // given
      DataReference k = new DataReference(2);
      FilteredDataSetView everyKthMonth = months.liveWhere((month, key) => month['number'] % key.value == 0, k);

      // then
      expect(everyKthMonth, unorderedEquals([february, april, june, august,
                                             october, december]));
      k.value = 6;
      expect(everyKthMonth, unorderedEquals([june, december]));
    });

    test('change filter to filter with args. (T05)', () {
      // given
      DataReference k = new DataReference(2);
      FilteredDataSetView everySecondMonth = months.liveWhere((month) => month['number'] % 4 == 0);
      everySecondMonth.changeFilter((month, key) => month['number'] % key.value == 0, k);

      // then
      expect(everySecondMonth, unorderedEquals([february, april, june, august,
                                             october, december]));

    });


  });
}

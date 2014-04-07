// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unioned_set_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(UnionedDataSet)', () {

    setUp(() => setUpMonths());

    test('no intersection data is properly unioned. (T01)', () {
      // given

      // when
      var allMonths = oddMonths.liveUnion(evenMonths);

      // then
      expect(allMonths, unorderedEquals(months));
    });

    test('non-empty intersection data is properly unioned. (T02)', () {
      // given
      var firstThree = new DataSet.from([january, february, march]);
      var lastThree = new DataSet.from([february, march, april]);

      // when
      var allFour = firstThree.liveUnion(lastThree);

      // then
      expect(allFour, unorderedEquals([january, february, march, april]));
    });

    test('same intersection data is properly unioned. (T03)', () {
      // given

      // when
      var allMonths = months.liveUnion(months);

      // then
      expect(allMonths, unorderedEquals(months));
    });
  });
}

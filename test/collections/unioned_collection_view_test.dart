// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unioned_collection_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(UnionedDataCollection)', () {

    setUp(() => setUpMonths());

    test('no intersection data is properly unioned. (T01)', () {
      // given

      // when
      var allMonths = oddMonths.union(evenMonths);

      // then
      expect(allMonths, unorderedEquals(months));
    });

    test('non-empty intersection data is properly unioned. (T02)', () {
      // given
      var firstThree = new DataCollection.from([january, february, march]);
      var lastThree = new DataCollection.from([february, march, april]);

      // when
      var allFour = firstThree.union(lastThree);

      // then
      expect(allFour, unorderedEquals([january, february, march, april]));
    });

    test('same intersection data is properly unioned. (T03)', () {
      // given

      // when
      var allMonths = months.union(months);

      // then
      expect(allMonths, unorderedEquals(months));
    });

  });
}

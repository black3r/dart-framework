// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library excepted_collection_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(ExceptedDataCollection)', () {

    setUp(() => setUpMonths());

    test('data is properly excepted. (T01)', () {
      // given

      // when
      DataCollectionView excepted = months.liveDifference(evenMonths);

      // then
      expect(excepted, unorderedEquals(oddMonths));
    });
  });
}

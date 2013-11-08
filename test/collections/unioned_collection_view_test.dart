// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unioned_collection_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';

void main() {

  group('(UnionedDataCollection)', () {

    setUp(() => setUpMonths());

    test('data is properly unioned (single union). (T01)', () {
      // given

      // when
      var allMonths = oddMonths.union(evenMonths);

      // then
      expect(allMonths, unorderedEquals(months));
    });
  });
}

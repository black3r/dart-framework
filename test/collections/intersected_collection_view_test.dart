// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intersected_collection_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';

void main() {

  group('(IntersectedDataCollection)', () {

    setUp(() => setUpMonths());

    test('data is properly intersected (single intersection). (T01)', () {
      // given
      var longMonths = months.where((month) => month['days'] >= 31);

      // when
      var intersected = longMonths.intersection(evenMonths);

      // then
      expect(intersected, equals([august, october, december]));

    });
  });
}

// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intersected_collection_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';

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

    test('onBeforeAdd is fired before object is added - first source collection change. (T02)', () {
      // given
      var halfYear = new DataCollection.from([january, february, march, april, may, june]);
      var longMonths = new DataCollection.from([january, march, may, july, august, october, december]);
      var intersected = halfYear.intersection(longMonths);

      // when
      halfYear.add(july);

      // then
      intersected.onBeforeAdded.listen(expectAsync1((DataView d) {
          expect(d, equals(july));
          expect(intersected.contains(july), isFalse);
      }));
    });

    test('onBeforeAdd is fired before object is added - second source collection change. (T03)', () {
      // given
      var halfYear = new DataCollection.from([january, february, march, april, may, june]);
      var longMonths = new DataCollection.from([january, march, may, july, august, october, december]);
      var intersected = halfYear.intersection(longMonths);

      // when
      longMonths.add(february);

      // then
      intersected.onBeforeAdded.listen(expectAsync1((DataView d) {
          expect(d, equals(february));
          expect(intersected.contains(february), isFalse);
      }));
    });

    test('onBeforeRemove is fired before object is removed - first source collection change. (T04)', () {
      // given
      var halfYear = new DataCollection.from([january, february, march, april, may, june]);
      var longMonths = new DataCollection.from([january, march, may, july, august, october, december]);
      var intersected = halfYear.intersection(longMonths);

      // when
      halfYear.remove(january);

      // then
      intersected.onBeforeRemoved.listen(expectAsync1((DataView d) {
          expect(d, equals(january));
          expect(intersected.contains(january), isTrue);
      }));
    });

    test('onBeforeRemove is fired before object is removed - second source collection change. (T05)', () {
      // given
      var halfYear = new DataCollection.from([january, february, march, april, may, june]);
      var longMonths = new DataCollection.from([january, march, may, july, august, october, december]);
      var intersected = halfYear.intersection(longMonths);

      // when
      longMonths.remove(march);

      // then
      intersected.onBeforeRemoved.listen(expectAsync1((DataView d) {
          expect(d, equals(march));
          expect(intersected.contains(march), isTrue);
      }));
    });
  });
}

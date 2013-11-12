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

    test('onBeforeAdd is fired before object is added - first source collection change. (T04)', () {
      // given
      var jan = new DataCollection.from([january]);
      var feb = new DataCollection.from([february]);
      var unioned = jan.union(feb);

      // when
      jan.add(march);

      // then
      unioned.onBeforeAdded.listen(expectAsync1((DataView d) {
          expect(d, equals(march));
          expect(unioned.contains(march), isFalse);
      }));
    });

    test('onBeforeAdd is fired before object is added - second source collection change. (T05)', () {
      // given
      var jan = new DataCollection.from([january]);
      var feb = new DataCollection.from([february]);
      var unioned = jan.union(feb);

      // when
      feb.add(april);

      // then
      unioned.onBeforeAdded.listen(expectAsync1((DataView d) {
          expect(d, equals(april));
          expect(unioned.contains(april), isFalse);
      }));
    });

    test('onBeforeRemove is fired before object is removed - first source collection change. (T04)', () {
      // given
      var jan = new DataCollection.from([january]);
      var feb = new DataCollection.from([february]);
      var unioned = jan.union(feb);

      // when
      jan.remove(january);

      // then
      unioned.onBeforeRemoved.listen(expectAsync1((DataView d) {
          expect(d, equals(january));
          expect(unioned.contains(january), isTrue);
      }));
    });

    test('onBeforeRemove is fired before object is removed - second source collection change. (T04)', () {
      // given
      var jan = new DataCollection.from([january]);
      var feb = new DataCollection.from([february]);
      var unioned = jan.union(feb);

      // when
      feb.remove(february);

      // then
      unioned.onBeforeRemoved.listen(expectAsync1((DataView d) {
          expect(d, equals(february));
          expect(unioned.contains(february), isTrue);
      }));
    });
  });
}

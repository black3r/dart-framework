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
      var evenMonths = months.where((month) => month['number'] % 2 == 0);

      // then
      expect(evenMonths, unorderedEquals([february, april, june, august,
                                          october, december]));
    });

    test('multiple filtering. (T02)', () {
      // given
      var evenMonths = months.where((month) => month['number'] % 2 == 0);

      // when
      var evenLongMonths = evenMonths.where((month) => month['days'] > 30);

      // then
      expect(evenLongMonths, unorderedEquals([august, october, december]));
    });

    test('changing the source collection. (T03)', () {
      // given
      var fantasyMonth = new Data.fromMap(
          {'name': 'FantasyMonth', 'days': 13, 'number': 13});
      var oddMonths = months.where((month) => month['number'] % 2 == 1);


      // when
      months.add(fantasyMonth);

      // then
      oddMonths.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems, equals([fantasyMonth]));
      }));
    });

    test('changing a data object in the source collection. (T04)', () {
      // given
      var evenMonths = months.where((month) => month['number'] % 2 == 0);

      // when
      january['number'] = 0;

      // then
      evenMonths.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems, unorderedEquals([january]));
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(evenMonths, unorderedEquals([january, february, april, june,
                                            august, october, december]));
      }));
    });

    test('changing a data object in the filtered collection (T05)', () {
      // given
      var evenMonths = months.where((month) => month['number'] % 2 == 0);

      // when
      february['number'] = 13;

      // then
      evenMonths.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems, unorderedEquals([february]));
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems.isEmpty, isTrue);
        expect(evenMonths, unorderedEquals([april, june, august, october,
                                            december]));
      }));
    });
  });
}

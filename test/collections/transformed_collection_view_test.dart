// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library transformed_collection_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(TransformedDataCollection)', () {

    setUp(() => setUpMonths());

    test('Excepted collection reacts to source object changes with a change'
         ' event. (T01)', () {

      // given
      var excepted = months.except(evenMonths);

      // when
      january['temperature'] = -10;

      //then
      excepted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.keys, equals([january]));
        expect(event.changedItems[january].addedItems, equals(['temperature']));
      }));
    });

    test('excepted collection reacts to change of the first source collection.'
         ' (T02)', () {

      // given
      var excepted = months.except(evenMonths);
      var fantasyMonth = new Data.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);

      // then
      excepted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.addedItems, equals([fantasyMonth]));
      }));
    });

    test('excepted collection reacts to change of the second source collection.'
         ' (T03)', () {

      // given
      var excepted = months.except(evenMonths);

      // when
      evenMonths.add(january);

      //then
      excepted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems, equals([january]));
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

    test('adding and removing an object does not raise an event. (T06)', () {
      // given
      var excepted = months.except(evenMonths);
      var fantasyMonth = new Data.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);
      months.remove(fantasyMonth);

      // then
      excepted.onChange.listen((c) => expect(true, isFalse));
    });

    test('removal, change and add is broadcasted as change (T07)', () {
      // given
      var excepted = months.except(evenMonths);

      // when
      months.remove(january);
      january['temperature'] = -10;
      months.add(january);

      // then
      excepted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.keys, unorderedEquals([january]));
      }));
    });

    test('onBeforeAdd is fired before object is added. (T08)', () {

      // given
      var excepted = months.except(evenMonths);
      var fantasyMonth = new Data.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);

      // then
      excepted.onBeforeAdded.listen(expectAsync1((DataView d) {
          expect(d, equals(fantasyMonth));
          expect(excepted.contains(fantasyMonth), isFalse);
      }));
    });

    test('onBeforeRemove is fired before object is removed. (T09)', () {
      // given
      var excepted = months.except(evenMonths);

      // when
      months.remove(january);

      // then
      excepted.onBeforeRemoved.listen(expectAsync1((DataView d) {
          expect(d, equals(january));
          expect(excepted.contains(january), isTrue);
      }));
    });

    test('onChangeSync on derived collections  (T10)', () {
      // given
      var evenMonths = months.where((month) => month['number'] % 2 == 0);
      evenMonths.onChangeSync.listen(expectAsync1((changeSet) {}));

      // when
      february['number'] = 13;

      // then

    });

    test('dispose method (T11)', () {
      // given
      var evenMonths = months.where((month) => month['number'] % 2 == 0);

      //then
      evenMonths.onChangeSync.listen((changeSet) => guardAsync(() => expect(true, isFalse, reason: 'Should not be reached')));

      // when
      evenMonths.dispose();
      february['number'] = 13;
    });


  });
}

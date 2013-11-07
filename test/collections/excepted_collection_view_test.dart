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
      DataCollectionView excepted = months.except(evenMonths);

      // then
      expect(excepted, unorderedEquals(oddMonths));
    });

    test('excepted collection reacts to source object changes with a change event. (T02)',(){
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

    test('excepted collection reacts to change of the first source collection. (T03)', () {
      // given
      var excepted = months.except(evenMonths);
      var fantasyMonth = new Data.fromMap(
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

    test('excepted collection reacts to change of the second source collection. (T04)', () {
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

    test('adding and removing an object does not raise an event. (T05)', () {
      // given
      var excepted = months.except(evenMonths);
      var fantasyMonth = new Data.fromMap(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);
      months.remove(fantasyMonth);

      // then
      excepted.onChange.listen((c) => expect(true, isFalse));
    });

    test('removal, change and add is broadcasted as change (T06)',(){
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

  });
}

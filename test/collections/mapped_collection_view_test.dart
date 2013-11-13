// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mapped_collection_view_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import '../months.dart';

void main() {

  var hoursInMonth = (month) => {'hours': month['days'] * 24};

  group('(MappedDataView)', () {

    setUp(() => setUpMonths());

    test('data object is mapped.', () {
      // given

      // when
      var januaryHours = new MappedDataView(january, hoursInMonth);

      //then
      expect(januaryHours['hours'], equals(31 * 24));
    });

    test('mapped object changes once the source object has changed.', () {
      // given
      var februaryHours = new MappedDataView(february, hoursInMonth);

      // when
      february['days'] = 29;

      // then
      februaryHours.onChange.listen(expectAsync1((ChangeSet event) {
        expect(februaryHours['hours'], equals(29 * 24));
        expect(event.changedItems.keys, equals(['hours']));
      }));
    });

  });

  group('(MappedDataCollection)', () {

    var dataNames, dataNums;
    DataCollection collectionNames, collectionNumbers;

    var verifyHoursMatch = (DataCollectionView source, DataCollectionView mapped) {
      var hoursInMonths = source.toList().map((month) => month['days'] * 24);
      var computedHours = mapped.toList().map((hours) => hours['hours']);
      expect(hoursInMonths, unorderedEquals(computedHours));
    };


    setUp(() => setUpMonths());

    test('data is properly mapped.', () {
      // given

      //when
      var monthsHours = months.map(hoursInMonth);

      // then
      verifyHoursMatch(months, monthsHours);
    });


    test('value is added to the source collection.', () {
      // given
      var monthsHours = months.map(hoursInMonth);
      var fantasyMonth = new Data.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);

      // then
      monthsHours.onChange.listen(expectAsync1((ChangeSet event) {
        verifyHoursMatch(months, monthsHours);
        expect(event.addedItems.length, equals(1));
      }));
    });

    test('value is removed from the source collection.', () {
      // given
      var monthsHours = months.map(hoursInMonth);

      // when
      months.remove(january);

      // then
      monthsHours.onChange.listen(expectAsync1((ChangeSet event) {
        verifyHoursMatch(months, monthsHours);
        expect(event.removedItems.length, equals(1));
      }));
    });

    test('value is changed in the source collection.', () {
      // given
      var monthsHours = months.map(hoursInMonth);

      // when
      january['days'] = 10;

      // then
      monthsHours.onChange.listen(expectAsync1((ChangeSet event) {
        verifyHoursMatch(months, monthsHours);
        expect(event.changedItems.length, equals(1));
      }));
    });

    test('remove an object and change it.', () {
      // given
      var monthsHours = months.map(hoursInMonth);

      // when
      months.remove(january);
      january['days'] = 10;

      // then
      monthsHours.onChange.listen(expectAsync1((ChangeSet event) {
        verifyHoursMatch(months, monthsHours);
        expect(event.changedItems.isEmpty, isTrue);
      }));
    });


    test('onBeforeAdd is fired before object is added.', () {
      // given
      var monthsHours = months.map(hoursInMonth);
      var fantasyMonth = new Data.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);

      // then
      monthsHours.onBeforeAdded.listen(expectAsync1((MappedDataView mdv) {
        expect(mdv.source, equals(fantasyMonth));
        expect(monthsHours.contains(fantasyMonth), isFalse);
      }));
    });

    test('onBeforeRemove is fired before object is removed.', () {
      // given
      var monthsHours = months.map(hoursInMonth);

      // when
      months.remove(january);

      // then
      monthsHours.onBeforeRemoved.listen(expectAsync1((MappedDataView mdv) {
        expect(mdv.source, equals(january));
        expect(monthsHours.contains(mdv), isTrue);
      }));
    });


    test('dispose method.', () {
       // given
       var monthsHours = months.map(hoursInMonth);

       //then
       monthsHours.onChangeSync.listen((changeSet) => guardAsync(() {
         expect(true, isFalse, reason: 'Should not be called.');
       }));

       // when
       monthsHours.dispose();

       months.remove(january);
       january['days'] = 10;
     });
  });
}

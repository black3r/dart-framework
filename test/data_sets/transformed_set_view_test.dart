// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library transformed_set_view_test;

import 'package:unittest/unittest.dart';
import '../months.dart';
import 'package:clean_data/clean_data.dart';
import '../matchers.dart' as matchers;

var equals = matchers.equals;

void main() {
  var conf = unittestConfiguration;
  conf.timeout = new Duration(seconds: 2);
  unittestConfiguration = conf;

  group('(TransformedDataSet)', () {

    setUp(() => setUpMonths());

    test('Excepted set reacts to source object changes with a change'
         ' event. (T01)', () {

      // given
      var excepted = months.liveDifference(evenMonths);

      // when
      january['temperature'] = -10;

      //then
      excepted.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          january: new ChangeSet({'temperature': new Change(undefined, -10)})
        })));
      }));
    });

    test('excepted set reacts to change of the first source set.'
         ' (T02)', () {

      // given
      var excepted = months.liveDifference(evenMonths);
      var fantasyMonth = new DataMap.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);

      // then
      excepted.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          fantasyMonth: new Change(undefined, fantasyMonth)
        })));
      }));
    });

    test('excepted set reacts to change of the second source set.'
         ' (T03)', () {

      // given
      var excepted = months.liveDifference(evenMonths);

      // when
      evenMonths.add(january);

      //then
      excepted.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          january: new Change(january, undefined)
        })));
      }));
    });

    test('changing a data object in the source set. (T04)', () {
      // given
      var evenMonths = months.liveWhere((month) => month['number'] % 2 == 0);

      // when
      january['number'] = 0;

      // then
      evenMonths.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          january: new Change(undefined, january)
        })));
        expect(evenMonths, unorderedEquals([january, february, april, june,
                                            august, october, december]));
      }));
    });

    test('changing a data object in the filtered set (T05)', () {
      // given
      var evenMonths = months.liveWhere((month) => month['number'] % 2 == 0);

      // when
      february['number'] = 13;

      // then
      evenMonths.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          february: new Change(february, undefined)
        })));
        expect(evenMonths, unorderedEquals([april, june, august, october,
                                            december]));
      }));
    });

    test('adding and removing an object does not raise an event. (T06)', () {
      // given
      var excepted = months.liveDifference(evenMonths);
      var fantasyMonth = new DataMap.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      months.add(fantasyMonth);
      months.remove(fantasyMonth);

      // then
      excepted.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          fantasyMonth: new Change(undefined, undefined)})));
      }));
    });

    test('removal, change and add is broadcasted (T07)', () {
      // given
      var excepted = months.liveDifference(evenMonths);

      // when
      months.remove(january);
      january['temperature'] = -10;
      months.add(january);

      // then
      excepted.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          january: new Change(january, january)
        })));
      }));
    });

    test('onBeforeAdd is fired before object is added. (T08)', () {

      // given
      var excepted = months.liveDifference(evenMonths);
      var fantasyMonth = new DataMap.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // then
      excepted.onBeforeAdd.listen(expectAsync1((DataMapView d) {
          expect(d, equals(fantasyMonth));
          expect(excepted.contains(fantasyMonth), isFalse);
      }));

      // when
      months.add(fantasyMonth);
    });

    test('onBeforeRemove is fired before object is removed. (T09)', () {
      // given
      var excepted = months.liveDifference(evenMonths);

      // then
      excepted.onBeforeRemove.listen(expectAsync1((DataMapView d) {
          expect(d, equals(january));
          expect(excepted.contains(january), isTrue);
      }));

      // when
      months.remove(january);
    });

    test('onChangeSync on derived sets  (T10)', () {
      // given
      var evenMonths = months.liveWhere((month) => month['number'] % 2 == 0);
      evenMonths.onChangeSync.listen(expectAsync1((changeSet) {}));

      // when
      february['number'] = 13;

      // then

    });

    test('dispose method (T11)', () {
      // given
      var evenMonths = months.liveWhere((month) => month['number'] % 2 == 0);

      //then
      evenMonths.onChangeSync.listen((changeSet) => guardAsync(() => expect(true, isFalse, reason: 'Should not be reached')));

      // when
      evenMonths.dispose();
      february['number'] = 13;
    });

    // TODO what is this?
    test('is working properly with non DataView elements. (T12)', () {
      // given
      var SpringSet = new DataSet.from([march, april, may]),
          SummerSet = new DataSet.from([june, july, august]),
          AutumnSet = new DataSet.from([september, october, november]),
          WinterSet = new DataSet.from([december, january, february]),
          seasons = new DataSet.from([SpringSet, SummerSet,
                                             AutumnSet, WinterSet]);

      var warmSeasons = new DataSet.from([SpringSet, SummerSet]);
      var coldSeasons = new DataSet.from([AutumnSet, WinterSet]);
      var windySeasons = new DataSet.from([AutumnSet]);

      // when
      var except = seasons.liveDifference(warmSeasons);
      expect(except, unorderedEquals(coldSeasons));

      var union = warmSeasons.liveUnion(coldSeasons);
      expect(union, unorderedEquals(seasons));

      var intersection = coldSeasons.liveIntersection(windySeasons);
      expect(intersection, unorderedEquals([AutumnSet]));

      var where = seasons.where(
          (seasons) => seasons.fold(0, (prev, DataMap month) => prev + month['days']) == 92);
      expect(where, unorderedEquals([SummerSet, SpringSet]));
    });

    test('is working properly with non listenable elements. (T13)', () {
      var seasons = new DataSet.from(['spring', 'summer', 'autumn', 'winter']);
      var warmSeasons = new DataSet.from(['spring', 'summer']);
      var coldSeasons = new DataSet.from(['autumn', 'winter']);
      var windySeasons = new DataSet.from(['autumn']);

      // when
      var except = seasons.liveDifference(warmSeasons);
      expect(except, unorderedEquals(coldSeasons));

      var union = warmSeasons.liveUnion(coldSeasons);
      expect(union, unorderedEquals(seasons));

      var intersection = coldSeasons.liveIntersection(windySeasons);
      expect(intersection, unorderedEquals(['autumn']));

      var where = seasons.where(
          (seasons) => seasons.startsWith('s'));
      expect(where, unorderedEquals(['summer', 'spring']));
    });
  });
}

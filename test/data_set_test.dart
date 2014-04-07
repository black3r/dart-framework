// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_set_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';
import 'months.dart';
import 'matchers.dart' as matchers;

var equals = matchers.equals;

void main() {

  group('(DataSet)', () {

    setUp(() => setUpMonths());

    test('initialize. (T01)', () {
      // when
      var set = new DataSet();

      // then
      expect(set.length, equals(0));
      expect(set, equals([]));
    });

    test('initialize with data. (T02)', () {
      // given
      var winter = [december, january, february];

      // when
      var winterSet = new DataSet<DataMap>.from(winter);

      // then
      expect(winterSet.length, equals(3));
      expect(winterSet, unorderedEquals(winter));
    });

    //TODO: delete
    test('add data object. (T04)', () {
      // given
      DataSet<DataMap> winterSet = new DataSet<DataMap>();
      var winter = [december, january, february];

      // when
      for (var month in winter) {
        winterSet.add(month);
      }

      // then
      expect(winterSet.contains(january), isTrue);
      expect(winterSet, unorderedEquals(winter));
      expect(winterSet.length, equals(3));
    });

    //TODO: delete
    test('remove dataObject. (T05)', () {
      // given
      DataSet<DataMap> year = new DataSet.from([december, january, february]);

      // when
      year.remove(january);

      // then
      expect(year.contains(january), isFalse);
      expect(year, unorderedEquals([december, february]));
    });

    test('clear. (T06)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);

      // when
      winterSet.clear();

      // then
      expect(winterSet.isEmpty, isTrue);
    });


    test('Find by index. (T17)', () {
      // given
      var year = new DataSet.from(months);

      // when
      year.addIndex(['number']);

      // then
      expect(year.findBy('number', 7), equals([july]));
      expect(year.findBy('number', 13).isEmpty, isTrue);
    });

    test('Find by non-existing index. (T18)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);

      // when

      // then
      expect(() => winterSet.findBy('number', 1),
          throwsA(new isInstanceOf<NoIndexException>("NoIndexException")));
    });

    test('Initialize and find by index. (T19)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      january['temperature'] = -10;
      february['temperature'] = -15;

      // when
      winterSet.addIndex(['temperature']);

      // then
      expect(winterSet.findBy('temperature', -10), unorderedEquals([january]));
    });

    test('Index updated synchronously after addition. (T20)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      winterSet.addIndex(['number']);

      // when
      winterSet.add(march);

      // then
      var result = winterSet.findBy('number', 3);
      expect(result, equals([march]));
    });

    test('Index updated synchronously after deletion. (T21)', () {

      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      winterSet.addIndex(['number']);

      // when
      winterSet.remove(january);

      // then
      expect(winterSet.findBy('number', 1).isEmpty, isTrue);
      expect(winterSet.findBy('number', 2), equals([february]));
    });

    test('Index updated synchronously after change. (T22)', () {

      // given
      var winterSet = new DataSet<DataMap>.from([december, january,
                                                      february]);
      winterSet.addIndex(['number']);

      // when
      january['number'] = 13;

      // then
      expect(winterSet.findBy('number', 13), equals([january]));
      expect(winterSet.findBy('number', 1).isEmpty, isTrue);
    });

    test('Remove by index works. (T23)', () {

      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      winterSet.addIndex(['number']);

      // when
      winterSet.removeBy('number', 2);

      // then
      expect(winterSet.findBy('number', 2).isEmpty, isTrue);
      expect(winterSet, unorderedEquals([december, january]));
    });

    test('Remove by index works (version with no items to remove). (T24)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      winterSet.addIndex(['number']);

      // when
      winterSet.removeBy('number', 13);

      // then
      expect(winterSet, unorderedEquals([december, january, february]));
    });

    test('Remove by index raises an exception on unindexed property. (T25)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      winterSet.addIndex(['number']);

      // when

      // then
      expect(() => winterSet.removeBy('temperature', -10),
          throwsA(new isInstanceOf<NoIndexException>("NoIndexException")));
    });

    test('Index updated synchronously after deletion. (T26)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      winterSet.addIndex(['number']);

      // when
      winterSet.remove(january);

      // then
      expect(winterSet.findBy('number', 1).isEmpty, isTrue);
    });

   test('Index updated synchronously after addition. (T27)', () {
     // given
     var winterSet = new DataSet.from([december, january,
                                                      february]);
     winterSet.addIndex(['number']);

     // when
     winterSet.add(march);

     // then
     expect(winterSet.findBy('number', 3), equals([march]));
   });

   test('is ignoring non DataView elements, when finding by index.', () {
     // given
     DataSet<DataMap> springSet = new DataSet.from([march, april, may]),
         summerSet = new DataSet.from([june, july, august]),
         autumnSet = new DataSet.from([september, october, november]),
         winterSet = new DataSet.from([december, january, february]),
         seasons = new DataSet.from([springSet, summerSet,
                                     autumnSet, winterSet]);

     var year = new DataSet.from(
         months..add(seasons)
           ..addAll(['spring', 'summer', 'autumn', 'winter']));

     // when
     year.addIndex(['number']);

     // then
     expect(year.findBy('number', 7), equals([july]));
     expect(year.findBy('number', 13).isEmpty, isTrue);
   });

    test('removeWhere spec. (T29)', () {

      // given & when
      DataSet<DataMap> longMonths = new DataSet<DataMap>.from(months)
      ..removeWhere((month) => month['days'] <= 30);

      // then
      expect(longMonths, unorderedEquals([january, march, may, july, august, october, december]));
    });

    test('removeAll spec. (T30)', () {

      // given
      DataSet year = new DataSet.from(months);

      //when
      year.removeAll(evenMonths);

      // then
      expect(year, unorderedEquals(oddMonths));
    });



    test('onBeforeAdd on add is fired before object is added. (T31)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                     february]);

      Mock mock = new Mock();

      winterSet.onBeforeAdd.listen((d) {
          mock.handler(d);
          expect(winterSet.contains(march), isFalse);
          expect(d, equals(march));
      });

      // when
      winterSet.add(march);

      // then
      mock.log.verify(happenedOnce);
    });

    test('onBeforeRemove on remove is fired before object is removed. (T32)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                     february]);

      Mock mock = new Mock();

      winterSet.onBeforeRemove.listen((d) {
          mock.handler(d);
          expect(winterSet.contains(december), isTrue);
          expect(d, equals(december));
      });

      // when
      winterSet.remove(december);

      // then
      mock.log.verify(happenedOnce);
    });

    test('onBeforeRemove on removeAll is fired before object is removed. (T33)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                     february]);

      Mock mock = new Mock();

      winterSet.onBeforeRemove.listen((d) {
          mock.handler(d);
          expect(winterSet.contains(december), isTrue);
          expect(winterSet.contains(january), isTrue);
          expect(winterSet.contains(february), isTrue);
      });

      // when
      winterSet.clear();

      // then
      mock.log.verify(happenedExactly(3));
    });

    test('onBeforeRemove on removeBy is fired before object is removed. (T34)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                     february]);

      winterSet.addIndex(['number']);

      Mock mock = new Mock();

      winterSet.onBeforeRemove.listen((d) {
          mock.handler(d);
          expect(winterSet.contains(february), isTrue);
          expect(d, equals(february));
      });

      // when
      winterSet.removeBy('number', 2);

      // then
      mock.log.verify(happenedOnce);
    });


    test('dispose method (T35)', () {
      // given
      var winterSet = new DataSet.from([december, january,
      february]);
      //then
      winterSet.onChangeSync.listen((changeSet) => guardAsync(() => expect(true, isFalse, reason: 'Should not be reached')));

      // when
      winterSet.dispose();
      february['days'] = 29;

    });

    test('addAll method (T36)', () {
      // given
      DataSet<DataMap> winterSet = new DataSet<DataMap>();
      var winter = [december, january, february];

      // when
      winterSet.addAll(winter);

      // then
      expect(winterSet, unorderedEquals(winter));
    });

    test('retainWhere method (T37)', () {
      // given
      var set = new DataSet<DataMap>.from(months);

      // when
      set.retainWhere((month) => month['number'] % 2 == 1);

      // then
      expect(set, unorderedEquals(oddMonths));
    });

    test('retainAll method (T38)', () {
      // given
      var set = new DataSet<DataMap>.from(evenMonths);
      var winter = [december, january, february];
      // when
      set.retainAll(winter);

      // then
      expect(set, unorderedEquals([december, february]));
    });

    test('add data object return value. (T39)', () {
      // given
      var winterSet = new DataSet<DataMap>.from([december, january, february]);

      // then
      expect(winterSet.add(january), isFalse);
      expect(winterSet.add(march), isTrue);
    });

    test('remove data object returns value. (T40)', () {
      // given
      var winterSet = new DataSet.from([december, january, february]);

      // then
      expect(winterSet.remove(january), isTrue);
      expect(winterSet.remove(march), isFalse);
    });

    test('addAll onChangeSync stream fires just one event on bulk add (T41)', () {
      // given
      var count=0;
      evenMonths.onChangeSync.listen((_) => count++);

      // when
      evenMonths.addAll(oddMonths);

      // then
      expect(count, 1);
    });

    test('removeAll onChangeSync stream fires just one event on bulk add (T42)', () {
      // given
      var count=0;
      evenMonths.onChangeSync.listen((_) => count++);

      // when
      evenMonths.removeAll([january, february, march, april, may, june]);

      // then
      expect(count, 1);
    });


    test('Map is listening properly for Set.', () {
      //given
      DataMap<String, DataSet> seasons = new DataMap<String, DataSet>.from({
        'spring': new DataSet.from([march, april, may]),
        'summer': new DataSet.from([june, july, august]),
        'autumn': new DataSet.from([september, october, november]),
        'winter': new DataSet.from([december, january, february])
      });

      //when
      february['days'] = 29;

      //then
      seasons.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'winter': new ChangeSet({
            february: new ChangeSet({'days': new Change(28, 29)})
          })
        })));
      }));
    });

    test('Set is listening properly for Set.', () {
      //given
      DataSet<DataMap> springSet = new DataSet.from([march, april, may]),
          summerSet = new DataSet.from([june, july, august]),
          autumnSet = new DataSet.from([september, october, november]),
          winterSet = new DataSet.from([december, january, february]),
          seasons = new DataSet.from([springSet, summerSet,
                                             autumnSet, winterSet]);

      //when
      february['days'] = 29;

      //then
      seasons.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          winterSet: new ChangeSet({
            february: new ChangeSet({'days': new Change(28, 29)})
          })
        })));
      }));
    });

    test('is accepting also non clean_data elements.', () {
      var springSet = new DataSet.from([march, april, may]),
          summerSet = new DataSet.from([june, july, august]),
          autumnSet = new DataSet.from([september, october, november]),
          winterSet = new DataSet.from([december, january, february]);
      var seasonsData = new DataSet.from(['spring', 'summer', 'autumn', 'winter',
                                                 springSet, summerSet,
                                                 autumnSet, winterSet]);
      seasonsData.remove('summer');

      expect(seasonsData.length, equals(7));
      expect(seasonsData.contains('spring'), isTrue);
      expect(seasonsData.contains('summer'), isFalse);
      expect(seasonsData.contains(springSet), isTrue);
    });

  });

}

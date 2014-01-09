// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_collection_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';
import 'months.dart';


void main() {

  group('(Collection)', () {

    setUp(() => setUpMonths());

    test('initialize. (T01)', () {
      // when
      var collection = new DataCollection();

      // then
      expect(collection.length, equals(0));
      expect(collection, equals([]));
    });

    test('initialize with data. (T02)', () {
      // given
      var winter = [december, january, february];

      // when
      var winterCollection = new DataCollection.from(winter);

      // then
      expect(winterCollection.length, equals(3));
      expect(winterCollection, unorderedEquals(winter));
    });

    //TODO: delete
    test('add data object. (T04)', () {
      // given
      var winterCollection = new DataCollection();
      var winter = [december, january, february];

      // when
      for (var month in winter) {
        winterCollection.add(month);
      }

      // then
      expect(winterCollection.contains(january), isTrue);
      expect(winterCollection, unorderedEquals(winter));
      expect(winterCollection.length, equals(3));
    });

    //TODO: delete
    test('remove dataObject. (T05)', () {
      // given
      var year = new DataCollection.from([december, january, february]);

      // when
      year.remove(january);

      // then
      expect(year.contains(january), isFalse);
      expect(year, unorderedEquals([december, february]));
    });

    test('clear. (T06)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);

      // when
      winterCollection.clear();

      // then
      expect(winterCollection.isEmpty, isTrue);
    });


    test('Find by index. (T17)', () {
      // given
      var year = new DataCollection.from(months);

      // when
      year.addIndex(['number']);

      // then
      expect(year.findBy('number', 7), equals([july]));
      expect(year.findBy('number', 13).isEmpty, isTrue);
    });

    test('Find by non-existing index. (T18)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);

      // when

      // then
      expect(() => winterCollection.findBy('number', 1),
          throwsA(new isInstanceOf<NoIndexException>("NoIndexException")));
    });

    test('Initialize and find by index. (T19)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      january['temperature'] = -10;
      february['temperature'] = -15;

      // when
      winterCollection.addIndex(['temperature']);

      // then
      expect(winterCollection.findBy('temperature', -10), unorderedEquals([january]));
    });

    test('Index updated synchronously after addition. (T20)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      winterCollection.addIndex(['number']);

      // when
      winterCollection.add(march);

      // then
      var result = winterCollection.findBy('number', 3);
      expect(result, equals([march]));
    });

    test('Index updated synchronously after deletion. (T21)', () {

      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      winterCollection.addIndex(['number']);

      // when
      winterCollection.remove(january);

      // then
      expect(winterCollection.findBy('number', 1).isEmpty, isTrue);
      expect(winterCollection.findBy('number', 2), equals([february]));
    });

    test('Index updated synchronously after change. (T22)', () {

      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      winterCollection.addIndex(['number']);

      // when
      january['number'] = 13;

      // then
      expect(winterCollection.findBy('number', 13), equals([january]));
      expect(winterCollection.findBy('number', 1).isEmpty, isTrue);
    });

    test('Remove by index works. (T23)', () {

      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      winterCollection.addIndex(['number']);

      // when
      winterCollection.removeBy('number', 2);

      // then
      expect(winterCollection.findBy('number', 2).isEmpty, isTrue);
      expect(winterCollection, unorderedEquals([december, january]));
    });

    test('Remove by index works (version with no items to remove). (T24)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      winterCollection.addIndex(['number']);

      // when
      winterCollection.removeBy('number', 13);

      // then
      expect(winterCollection, unorderedEquals([december, january, february]));
    });

    test('Remove by index raises an exception on unindexed property. (T25)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      winterCollection.addIndex(['number']);

      // when

      // then
      expect(() => winterCollection.removeBy('temperature', -10),
          throwsA(new isInstanceOf<NoIndexException>("NoIndexException")));
    });

    test('Index updated synchronously after deletion. (T26)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      winterCollection.addIndex(['number']);

      // when
      winterCollection.remove(january);

      // then
      expect(winterCollection.findBy('number', 1).isEmpty, isTrue);
    });

   test('Index updated synchronously after addition. (T27)', () {
     // given
     var winterCollection = new DataCollection.from([december, january,
                                                      february]);
     winterCollection.addIndex(['number']);

     // when
     winterCollection.add(march);

     // then
     expect(winterCollection.findBy('number', 3), equals([march]));
   });


    test('removeWhere spec. (T29)', () {

      // given & when
      DataCollection longMonths = new DataCollection.from(months)
      ..removeWhere((month) => month['days'] <= 30);

      // then
      expect(longMonths, unorderedEquals([january, march, may, july, august, october, december]));
    });

    test('removeAll spec. (T30)', () {

      // given
      DataCollection year = new DataCollection.from(months);

      //when
      year.removeAll(evenMonths);

      // then
      expect(year, unorderedEquals(oddMonths));
    });



    test('onBeforeAdd on add is fired before object is added. (T31)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                     february]);

      Mock mock = new Mock();

      winterCollection.onBeforeAdd.listen((d) {
          mock.handler(d);
          expect(winterCollection.contains(march), isFalse);
          expect(d, equals(march));
      });

      // when
      winterCollection.add(march);

      // then
      mock.log.verify(happenedOnce);
    });

    test('onBeforeRemove on remove is fired before object is removed. (T32)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                     february]);

      Mock mock = new Mock();

      winterCollection.onBeforeRemove.listen((d) {
          mock.handler(d);
          expect(winterCollection.contains(december), isTrue);
          expect(d, equals(december));
      });

      // when
      winterCollection.remove(december);

      // then
      mock.log.verify(happenedOnce);
    });

    test('onBeforeRemove on removeAll is fired before object is removed. (T33)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                     february]);

      Mock mock = new Mock();

      winterCollection.onBeforeRemove.listen((d) {
          mock.handler(d);
          expect(winterCollection.contains(december), isTrue);
          expect(winterCollection.contains(january), isTrue);
          expect(winterCollection.contains(february), isTrue);
      });

      // when
      winterCollection.clear();

      // then
      mock.log.verify(happenedExactly(3));
    });

    test('onBeforeRemove on removeBy is fired before object is removed. (T34)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                     february]);

      winterCollection.addIndex(['number']);

      Mock mock = new Mock();

      winterCollection.onBeforeRemove.listen((d) {
          mock.handler(d);
          expect(winterCollection.contains(february), isTrue);
          expect(d, equals(february));
      });

      // when
      winterCollection.removeBy('number', 2);

      // then
      mock.log.verify(happenedOnce);
    });


    test('dispose method (T35)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
      february]);
      //then
      winterCollection.onChangeSync.listen((changeSet) => guardAsync(() => expect(true, isFalse, reason: 'Should not be reached')));

      // when
      winterCollection.dispose();
      february['days'] = 29;

    });

    test('addAll method (T36)', () {
      // given
      var winterCollection = new DataCollection();
      var winter = [december, january, february];

      // when
      winterCollection.addAll(winter);

      // then
      expect(winterCollection, unorderedEquals(winter));
    });

    test('retainWhere method (T37)', () {
      // given
      var collection = new DataCollection.from(months);

      // when
      collection.retainWhere((month) => month['number'] % 2 == 1);

      // then
      expect(collection, unorderedEquals(oddMonths));
    });

    test('retainAll method (T38)', () {
      // given
      var collection = new DataCollection.from(evenMonths);
      var winter = [december, january, february];
      // when
      collection.retainAll(winter);

      // then
      expect(collection, unorderedEquals([december, february]));
    });

    test('add data object return value. (T39)', () {
      // given
      var winterCollection = new DataCollection.from([december, january, february]);

      // then
      expect(winterCollection.add(january), isFalse);
      expect(winterCollection.add(march), isTrue);
    });

    test('remove data object return value. (T40)', () {
      // given
      var winterCollection = new DataCollection.from([december, january, february]);

      // then
      expect(winterCollection.remove(january), isTrue);
      expect(winterCollection.remove(march), isFalse);
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
      Data seasons = new Data.from({'spring': new DataCollection.from([march, april, may]),
                      'summer': new DataCollection.from([june, july, august]),
                      'autumn': new DataCollection.from([september, october, november]),
                      'winter': new DataCollection.from([december, january, february])});
      
      //when
      february['days'] = 29;
      
      //then
      seasons.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet.changedItems.keys, unorderedEquals(['winter']));
        expect(changeSet.changedItems['winter'].changedItems.containsKey(february), isTrue);        
      }));
    });
    
    test('Set is listening properly for Set.', () { 
      //given 
      var springCollection = new DataCollection.from([march, april, may]),
          summerCollection = new DataCollection.from([june, july, august]),
          autumnCollection = new DataCollection.from([september, october, november]),
          winterCollection = new DataCollection.from([december, january, february]),
          seasons = new DataCollection.from([springCollection, summerCollection, 
                                             autumnCollection, winterCollection]);
      
      //when
      february['days'] = 29;
      
      //then
      seasons.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet.changedItems.keys, unorderedEquals([winterCollection]));
        expect(changeSet.changedItems[winterCollection].changedItems.containsKey(february), isTrue);        
      }));
    });
    
    test('is ignoring non DataView elements, when finding by index.', () {
      // given
      var springCollection = new DataCollection.from([march, april, may]),
          summerCollection = new DataCollection.from([june, july, august]),
          autumnCollection = new DataCollection.from([september, october, november]),
          winterCollection = new DataCollection.from([december, january, february]),
          seasons = new DataCollection.from([springCollection, summerCollection, 
                                             autumnCollection, winterCollection]);
      
      var year = new DataCollection.from(
          months..add(seasons)
                ..addAll(['spring', 'summer', 'autumn', 'winter']));
      
      // when
      year.addIndex(['number']);

      // then
      expect(year.findBy('number', 7), equals([july]));
      expect(year.findBy('number', 13).isEmpty, isTrue);
    });
    
    test('is accepting also non clean_data elements.', () {
      var springCollection = new DataCollection.from([march, april, may]),
          summerCollection = new DataCollection.from([june, july, august]),
          autumnCollection = new DataCollection.from([september, october, november]),
          winterCollection = new DataCollection.from([december, january, february]);
      var seasonsData = new DataCollection.from(['spring', 'summer', 'autumn', 'winter',
                                                 springCollection, summerCollection, 
                                                 autumnCollection, winterCollection]);
      seasonsData.remove('summer');
      
      expect(seasonsData.length, equals(7));
      expect(seasonsData.contains('spring'), isTrue);
      expect(seasonsData.contains('summer'), isFalse);
      expect(seasonsData.contains(springCollection), isTrue);
    });
    
  });

}
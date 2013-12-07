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

    test('multiple listeners listen to onChange. (T03)', () {
      // given
      var collection = new DataCollection();

      // when
      collection.onChange.listen((event) => null);
      collection.onChange.listen((event) => null);

      // Then no exception is thrown.
    });

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

    test('listen on data object added. (T07)', () {
      // given
      var collection = new DataCollection();
      var mock = new Mock();
      collection.onChangeSync.listen((event) => mock.handler(event));
      // when
      collection.add(january, author: 'John Doe');

      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().logs.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'].addedItems, unorderedEquals([january]));

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems, unorderedEquals([january]));
      }));
    });

    test('listen on data object removed. (T08)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      var mock = new Mock();
      winterCollection.onChangeSync.listen((event) => mock.handler(event));

      // when
      winterCollection.remove(january, author: "John Doe");

      // then
      mock.log.verify(happenedOnce);
      var event = mock.log.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'].removedItems, unorderedEquals([january]));

      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems, unorderedEquals([january]));
      }));
    });

    test('listen synchronously on multiple data objects removed. (T09)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      var mock = new Mock();
      winterCollection.onChangeSync.listen((event) => mock.handler(event));

      // when
      winterCollection.remove(january, author: 'John Doe');
      winterCollection.remove(february, author: 'Peter Pan');

      // then
      mock.log.verify(happenedExactly(2));
      var event1 = mock.log.logs[0].args.first;
      var event2 = mock.log.logs[1].args.first;

      expect(event1['author'], equals('John Doe'));
      expect(event1['change'].removedItems, equals([january]));

      expect(event2['author'], equals('Peter Pan'));
      expect(event2['change'].removedItems, equals([february]));
    });

    test('listen on data object changes. (T10)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      var mock = new Mock();
      winterCollection.onChangeSync.listen((event) => mock.handler(event));

      // when
      january.add('temperature', -10, author: 'John Doe');

      // then
      mock.log.verify(happenedOnce);
      var event = mock.log.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'].changedItems[january].addedItems, equals(['temperature']));

      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.length, equals(1));
        expect(event.changedItems[january].addedItems,
            unorderedEquals(['temperature']));
      }));
    });

    test('do not listen on removed data object changes. (T11)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                february]);

      // when
      winterCollection.remove(january);
      january['temperature'] = -10;

      // then
      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
      }));
    });

    test('do not listen on cleared data object changes. (T12)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);

      // when
      winterCollection.clear();
      january['temperature'] = -10;

      // then
      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
      }));
    });

    test('propagate multiple changes in single [ChangeSet]. (T13)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      var fantasyMonth = new Data.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      winterCollection.remove(january);
      winterCollection.add(fantasyMonth);
      february['temperature'] = -15;
      december['temperature'] = 5;

      // then
      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems, unorderedEquals([fantasyMonth]));
        expect(event.removedItems, unorderedEquals([january]));
        expect(event.changedItems.keys,
            unorderedEquals([february, december]));
      }));
    });

    test('propagate multiple data object changes in single [ChangeSet]. (T14)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);

      // when
      january['temperature'] = -10;
      february['temperature'] = -15;

      // then
      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.keys,
            unorderedEquals([january, february]));
      }));

    });

    test('add, change, remove in one event loop propagate a change. (T15)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);

      // when
      winterCollection.remove(january);
      january['temperature'] = -10;
      winterCollection.add(january);

      // then
      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.keys, unorderedEquals([january]));
      }));
    });

    test('after removing, collection does not listen to changes on object anymore. (T16)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);

      // when
      winterCollection.remove(january);
      Timer.run(() {
        january['temperature'] = -10;
        winterCollection.onChange.listen((c) => expect(true, isFalse));
      });

      // then
      winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems, equals([january]));
      }));
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

   test('change on data object propagates correctly to the collection. (T28)', () {

     // given
     var winterCollection = new DataCollection.from([december, january,
                                                     february]);

     // when
     february.remove('days');
     february['days'] = 29;

     // then
     winterCollection.onChange.listen(expectAsync1((ChangeSet event) {
       expect(event.addedItems.isEmpty, isTrue);
       expect(event.removedItems.isEmpty, isTrue);
       expect(event.changedItems.keys, unorderedEquals([february]));

       // verify the data object changeset is valid
       ChangeSet changes = event.changedItems[february];
       expect(changes.addedItems.isEmpty, isTrue);
       expect(changes.removedItems.isEmpty, isTrue);
       expect(changes.changedItems.length, equals(1));

       Change change = changes.changedItems['days'];
       expect(change.oldValue, equals(28));
       expect(change.newValue, equals(29));
      }));
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
      expect(winterCollection.contains(january), isTrue);
      expect(winterCollection, unorderedEquals(winter));
      expect(winterCollection.length, equals(3));
    });
    
    test('retainWhere method (T36)', () {
      // given
      var collection = new DataCollection.from(months);

      // when
      collection.retainWhere((E) => E['number'] % 2 == 1);
      
      // then
      expect(collection, unorderedEquals(oddMonths));
    });
    
    test('retainAll method (T36)', () {
      // given
      var collection = new DataCollection.from(evenMonths);
      var winter = [december, january, february];
      // when
      collection.retainAll(winter);
      
      // then
      expect(collection, unorderedEquals([december, february]));
    });
  });
}
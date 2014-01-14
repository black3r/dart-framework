// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library change_streams_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';
import 'months.dart';

addedEquals(ChangeSet changeSet, Iterable added){
  expect(changeSet.addedItems, unorderedEquals(added));
  expect(changeSet.strictlyChanged, isEmpty);
  expect(changeSet.removedItems, isEmpty);
}

removedEquals(ChangeSet changeSet, Iterable removed){
  expect(changeSet.addedItems, isEmpty);
  expect(changeSet.strictlyChanged, isEmpty);
  expect(changeSet.removedItems, unorderedEquals(removed));
}


void main() {

  group('(ChangeStreams)', () {

    setUp(() => setUpMonths());

    test('multiple listeners listen to onChange. (T03)', () {
      // given
      var collection = new DataCollection();

      // when
      collection.onChange.listen((event) => null);
      collection.onChange.listen((event) => null);

      // Then no exception is thrown.
    });


    test('listen on data object changes. (T10)', () {
      // given
      var winterCollection = new DataCollection.from([december, january,
                                                      february]);
      var mock = new Mock();
      winterCollection.onChangeSync.listen((event) => mock.handler(event));

      // when
      january.add('temperature', -10);

      // then
      mock.log.verify(happenedOnce);
      var event = mock.log.first.args.first;
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
        expect(event.strictlyChanged.isEmpty, isTrue);
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
        expect(event.strictlyChanged.keys,
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
        expect(event.strictlyChanged.keys,
            unorderedEquals([january, february]));
      }));

    });

    test('remove, change, add in one event loop propagate a change. (T15)', () {
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
        expect(event.strictlyChanged.isEmpty, isTrue);
        expect(event.changedItems.keys, unorderedEquals([january]));
        expect(event.changedItems[january], new isInstanceOf<Change>());
        expect(event.changedItems[january].newValue.value, january);
        expect(event.changedItems[january].oldValue.value, january);
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
        expect(event.strictlyChanged.keys, unorderedEquals([february]));

        // verify the data object changeset is valid
        ChangeSet changes = event.changedItems[february];
        expect(changes.addedItems.isEmpty, isTrue);
        expect(changes.removedItems.isEmpty, isTrue);
        expect(changes.changedItems.length, equals(1));

        Change change = changes.changedItems['days'];
        expect(change.oldValue.value, equals(28));
        expect(change.newValue.value, equals(29));
      }));
    });

    test('onChangeSync produces correct results when removeAll multiple elements multiple times (T43)', () {
      // given

      DataCollection selection = new DataCollection.from([february, march, april, may]);

      var changeSet;
      var count=0;
      selection.onChangeSync.listen(
        (Map map){
          changeSet = map['change'];
          count++;
        }
      );

      //when
      selection.removeAll(winter);
      //then
      removedEquals(changeSet, [february]);
      //when
      selection.removeAll(spring);
      //then
      removedEquals(changeSet, spring);
      //when
      changeSet = null;
      selection.removeAll(summer);
      //then
      expect(changeSet, isNull);
      expect(count, equals(2));
      selection.onChangeSync.listen(expectAsync1((_){}, count:0));
    });

    test('onChange produces correct results when removeAll multiple elements multiple times ', () {

      // given
      DataCollection selection = new DataCollection.from([february, march, april, may, june]);
      var onChange = new Completer();

      //when
      selection.removeAll(winter);
      selection.removeAll(spring);

      //then
      selection.onChange.listen(expectAsync1(
          (changeSet){
             removedEquals(changeSet, [february, march, april, may]);
          },
          count : 1
      ));
    });

    test('onChangeSync produces correct results when addAll multiple elements multiple times (T43)', () {

      // given
      DataCollection selection = new DataCollection.from([february, march, april, may]);

      var changeSet;

      var count=0;
      selection.onChangeSync.listen(
        (Map map){
          count++;
          changeSet = map['change'];
        }
      );

      //when
      selection.addAll(winter);
      //then
      addedEquals(changeSet, [december, january]);
      //when
      selection.addAll(summer);
      //then
      addedEquals(changeSet, summer);
      //when
      changeSet=null;
      selection.addAll(summer);
      //then
      expect(changeSet, isNull);
      expect(count, equals(2));
      selection.onChangeSync.listen(expectAsync1((_){}, count:0));
    });

    test('onChange produces correct results when addAll multiple elements multiple times (T43)', () {

      // given
      DataCollection selection = new DataCollection.from([february, march, april, may]);
      var onChange = new Completer();

      //when
      selection.addAll(winter);
      selection.addAll(spring);
      selection.addAll(summer);

      //then
      selection.onChange.listen(expectAsync1(
          (changeSet){
             addedEquals(changeSet, [december, january, june, july, august]);
          },
          count : 1
      ));
    });


    test('onChangeSync gives correct author, when adding, removing, changing', (){
      // given
      DataCollection selection = new DataCollection.from(autumn);

      var changeSet;
      var author;

      selection.onChangeSync.listen(
        (Map map){
          changeSet = map['change'];
          author = map['author'];
        }
      );

      //when
      selection.addAll(winter, author: 'Bond. James Bond.');
      //then
      expect(author, equals('Bond. James Bond.'));
      //when
      selection.removeAll([february, march], author: 'Winnie the pooh');
      //then
      expect(author, equals('Winnie the pooh'));
      //when
      Data data = selection.first;
      data.add("days", 32, author: 'Guybrush Threepwood');
      //then
      expect(author, equals('Guybrush Threepwood'));
      //when
      selection.clear(author: 'King Arthur');
      //then
      expect(author, equals('King Arthur'));
    });

    test('''do not stop listening on object that was removed and added in
         the same event loop''', (){
      DataCollection selection = new DataCollection.from([january, february]);
      selection.remove(january);
      selection.remove(february);
      selection.add(january);
      num count = 0;
      selection.onChange.listen((data){count++;});
      return new Future.delayed(new Duration(milliseconds: 100))
        .then((_){
          // january should be listened on now, therefore
          // count++ happens here
          january['days'] = 100;
        }).then((_){
          return new Future.delayed(new Duration(milliseconds: 100));
        }).then((_){
          expect(count, equals(2));
        });
    });

//    solo_test('pokus', () {
//      // given
//      var winterCollection = new DataCollection.from([december, january,
//                                                      february]);
//      // when
//
//      winterCollection.onChangeSync.listen((event) {
//        print(event['change']);
//      });
//
//      print(march);
//
//      winterCollection.add(march);
//      winterCollection.remove(march);
//
//      // then
//      winterCollection.onChange.listen((ChangeSet event) {
//        print(event);
//      });
//    });

  });


}
// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library set_streams_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';
import 'months.dart';
import 'matchers.dart' as matchers;

var equals = matchers.equals;

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
      var set = new DataSet();

      // when
      set.onChange.listen((event) => null);
      set.onChange.listen((event) => null);

      // Then no exception is thrown.
    });


    test('listen on data object changes. (T10)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      var mock = new Mock();
      winterSet.onChangeSync.listen((changeSet) => mock.handler(changeSet));

      // when
      january.add('temperature', -10);

      // then
      mock.log.verify(happenedOnce);
      var event = mock.log.first.args.first;
      expect(event['change'].changedItems[january].addedItems, equals(['temperature']));

      winterSet.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          january: new ChangeSet({
            'temperature': new Change(undefined, -10)
          })})));
      }));
    });

    test('do not listen on removed data object changes. (T11)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                february]);

      // when
      winterSet.remove(january);
      january['temperature'] = -10;

      // then
      winterSet.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          january: new Change(january, undefined)
        })));
      }));
    });

    test('propagate multiple changes in single [ChangeSet]. (T13)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);
      var fantasyMonth = new DataMap.from(
          {"name": "FantasyMonth", "days": 13, "number": 13});

      // when
      winterSet.remove(january);
      winterSet.add(fantasyMonth);
      february['temperature'] = -15;
      december['temperature'] = 5;

      // then
      winterSet.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          january: new Change(january, undefined),
          fantasyMonth: new Change(undefined, fantasyMonth),
          february: new ChangeSet({'temperature': new Change(undefined, -15)}),
          december: new ChangeSet({'temperature': new Change(undefined, 5)})
        })));
      }));
    });

    test('remove, change, add in one event loop propagate a change. (T15)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);

      // when
      winterSet.remove(january);
      january['temperature'] = -10;
      winterSet.add(january);

      // then
      winterSet.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event, equals(new ChangeSet(
            {january: new Change(january, january)})));
      }));
    });

    test('after removing, set does not listen to changes on object anymore. (T16)', () {
      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);

      // when
      winterSet.remove(january);
      Timer.run(() {
        january['temperature'] = -10;
        winterSet.onChange.listen((c) => expect(true, isFalse));
      });

      // then
      winterSet.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet.removedItems, equals([january]));
      }));
    });

    test('change on data object propagates correctly to the set. (T28)', () {

      // given
      var winterSet = new DataSet.from([december, january,
                                                      february]);

      // when
      february.remove('days');
      february['days'] = 29;

      // then
      winterSet.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event, equals(new ChangeSet(
            {february: new ChangeSet({'days': new Change(28, 29)})})));
      }));
    });

    test('onChangeSync produces correct results when removeAll multiple elements multiple times (T43)', () {
      // given

      DataSet selection = new DataSet.from([february, march, april, may]);

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
      DataSet selection = new DataSet.from([february, march, april, may, june]);
      var onChange = new Completer();

      //when
      selection.removeAll(winter);
      selection.removeAll(spring);

      //then
      selection.onChange.listen(expectAsync1((changeSet){
             removedEquals(changeSet, [february, march, april, may]);
      }, count : 1));
    });

    test('onChangeSync produces correct results when addAll multiple elements multiple times (T43)', () {

      // given
      DataSet selection = new DataSet.from([february, march, april, may]);

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
      DataSet selection = new DataSet.from([february, march, april, may]);
      var onChange = new Completer();

      //when
      selection.addAll(winter);
      selection.addAll(spring);
      selection.addAll(summer);

      //then
      selection.onChange.listen(expectAsync1((changeSet){
             addedEquals(changeSet, [december, january, june, july, august]);
          },count : 1));
    });


    test('onChangeSync gives correct author, when adding, removing, changing', (){
      // given
      DataSet selection = new DataSet.from(autumn);

      var changeSet;
      var author;

      selection.onChangeSync.listen(
        (Map event){
          changeSet = event['change'];
          author = event['author'];
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
      DataMap data = selection.first;
      data.add("days", 32, author: 'Guybrush Threepwood');
      //then
      expect(author, equals('Guybrush Threepwood'));
      //when
      selection.clear(author: 'King Arthur');
      //then
      expect(author, equals('King Arthur'));
    });

    //TODO rewrite with onChangeSync
    test('''do not stop listening on object that was removed and added in
         the same event loop''', (){
      DataSet selection = new DataSet.from([january, february]);
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
  });

}

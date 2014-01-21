// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_list_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'package:unittest/mock.dart';
import 'dart:async';
import 'matchers.dart' as matchers;

var equals = matchers.equals;

void main() {

  group('(DataList)', () {
    test('initiliaze. (T01)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);
      list.add('four');
      expect(list.length, equals(4));
      expect(list, orderedEquals(['one', 'two', 'three', 'four']));
    });

    test('adding element fires change. (T02)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);

      list.onChangeSync.listen(expectAsync1((Map event) {
        expect(event['change'], equals(new ChangeSet({3: new Change(undefined, 'four')})));
      }, count: 1));

      list.add('four');

      expect(list.length, equals(4));
      expect(list, orderedEquals(['one', 'two', 'three', 'four']));
    });

    test('removing last element fires change. (T03)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);

      list.onChangeSync.listen(expectAsync1((Map event) {
        expect(event['change'], equals(new ChangeSet({2: new Change('three', undefined)})));
      }, count: 1));

      list.removeLast();

      expect(list.length, equals(2));
      expect(list, orderedEquals(['one', 'two']));
    });

    test('removing element fires change. (T04)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);

      list.onChangeSync.listen(expectAsync1((Map event) {
        expect(event['change'], equals(new ChangeSet({
          1: new Change('two', 'three'),
          2: new Change('three', undefined)
        })));
      }, count: 1));

      list.remove('two');

      expect(list.length, equals(2));
      expect(list, orderedEquals(['one', 'three']));
    });

    test('add more items at once. (T05)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);

      list.onChangeSync.listen(expectAsync1((Map event) {
        expect(event['change'], equals(new ChangeSet({
          3: new Change(undefined, 'four'),
          4: new Change(undefined, 'five')
        })));
      }, count: 1));

      list.addAll(['four', 'five']);

      expect(list.length, equals(5));
      expect(list, orderedEquals(['one', 'two', 'three', 'four', 'five']));
    });

    test('set an item to any index. (T06)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);

      list.onChangeSync.listen(expectAsync1((Map event) {
        expect(event['change'], equals(new ChangeSet({
          2: new Change('three', 'TWO')
        })));
      }, count: 1));

      list.set(2, 'TWO', author: 'clean_data');

      expect(list.length, equals(3));
      expect(list, orderedEquals(['one', 'two', 'TWO']));
    });

    test('removeWhere (T06)', () {
      // given
      DataList dataList = new DataList.from(['element1','doge', 'doge', 'element4']);

      var changeSet;

      dataList.onChangeSync.listen((Map event) {
        changeSet = event['change'];
      });

      // when
      dataList.removeWhere((el) => el == 'doge');

      // then
      expect(changeSet, equals(new ChangeSet({
        1: new Change('doge', 'element4'),
        2: new Change('doge', undefined),
        3: new Change('element4', undefined)
      })));

      expect(dataList, orderedEquals(['element1', 'element4']));

    });

    test('retainWhere (T07)', () {
      // given
      DataList dataList = new DataList.from(['element1','doge', 'doge', 'element4']);
      var changeSet;
      dataList.onChangeSync.listen((Map event) {
        changeSet = event['change'];
      });

      // when
      dataList.retainWhere((el) => el != 'doge');

      // then

      expect(changeSet, equals(new ChangeSet({
        1: new Change('doge', 'element4'),
        2: new Change('doge', undefined),
        3: new Change('element4', undefined)})
      ));

      expect(dataList, orderedEquals(
          ['element1', 'element4']));
    });

    test('sort (T08)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'three', 'four', 'five']);

      list.onChangeSync.listen(expectAsync1((Map event) {
        var changeSet = event['change'];
        expect(changeSet.changedItems.length, equals(5));
      }, count: 1));

      // when
      list.sort();

      // then
      expect(new List.from(list), orderedEquals(
          ['five', 'four', 'one', 'three', 'two']));
    });

    test('shuffle (T09)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'three', 'four', 'five']);

      list.onChangeSync.listen(expectAsync1((Map event) {
      }, count: 1));

      // when
      list.shuffle();
    });

    test('removeRange (T09)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'three', 'four', 'five']);
      var changeSet;
      list.onChangeSync.listen((Map event) {
        expect(changeSet, equals(null));
        changeSet = event['change'];
      });

      //when
      list.removeRange(1, 3);

      //then
      expect(changeSet, equals(new ChangeSet({
        1: new Change('two', 'four'),
        2: new Change('three', 'five'),
        3: new Change('four', undefined),
        4: new Change('five', undefined),
      })));

      expect(list, orderedEquals(
          ['one', 'four', 'five']));
    });

    test('setRange (T10)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'three', 'four', 'five']);
      var ref2 = list.ref(1);
      var ref3 = list.ref(2);
      list.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          1: new Change('two', 'TWO'),
          2: new Change('three', 'THREE')
        })));
      }, count: 1));

      // when
      list.setRange(1, 3, ['TWO', 'THREE']);
      expect(list, orderedEquals(
          ['one', 'TWO', 'THREE', 'four', 'five']));
    });

    test('replaceRange (T11)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'three', 'four', 'five']);

      list.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          1: new Change('two', 'TWO'),
          2: new Change('three', 'THREE'),
          3: new Change('four', undefined),
          4: new Change('five', undefined)
        })));
      }, count: 1));

      // when
      list.replaceRange(1, 5, ['TWO', 'THREE']);
      expect(list, orderedEquals(
          ['one', 'TWO', 'THREE']));
    });

    test('insert (T12)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'three', 'five']);

      list.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          3: new Change('five', 'four'),
          4: new Change(undefined, 'five')
        })));
      }, count: 1));

      // when
      list.insert(3, 'four');
      expect(list, orderedEquals(
          ['one', 'two', 'three', 'four', 'five']));
    });

    test('insertAll (T13)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'five']);

      list.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          2: new Change('five', 'three'),
          3: new Change(undefined, 'four'),
          4: new Change(undefined, 'five')
        })));
      }, count: 1));

      // when
      list.insertAll(2, ['three', 'four']);
      expect(list, orderedEquals(
          ['one', 'two', 'three', 'four', 'five']));
    });

    group('nested', () {
      test('listens to changes of its children. (T14)', () {
        // given
        DataList dataList = new DataList.from([new DataMap(), new DataMap()]);

        // when
        dataList[0]['name'] = 'John Doe';
        dataList[1]['name'] = 'Mills';

        // then
        dataList.onChange.listen(expectAsync1((ChangeSet event) {
          expect(event, equals(new ChangeSet({
            0: new ChangeSet({'name': new Change(undefined, 'John Doe')}),
            1: new ChangeSet({'name': new Change(undefined, 'Mills')})
          })));
        }));
      });

      test('do not listen to removed children changes. (T15)', () {
        // given
        var child = new DataMap();
        DataList dataList = new DataList.from([child]);
        var onChange = new Mock();

        // when
        dataList.removeAt(0);
        var future = new Future.delayed(new Duration(milliseconds: 20), () {
          dataList.onChangeSync.listen((e) => onChange(e));
          child['name'] = 'John Doe';
        });

        // then
        return future.then((_) {
          onChange.getLogs().verify(neverHappened);
        });
      });

      test('do not listen after remove multiple children with removeRange. (T16)', () {
        // given
        var child1 = new DataMap();
        var child2 = new DataMap();
        DataList dataList = new DataList.from([new DataMap(), child1, child2]);
        var onRemove = new Mock();
        var onChange = new Mock();
        dataList.onChangeSync.listen((event) => onRemove.handler(event));

        // when
        dataList.removeRange(1,3);

        // then
        var future = new Future.delayed(new Duration(milliseconds: 20), () {
          dataList.onChangeSync.listen((e) => onChange(e));
          child1['name'] = 'John Doe';
          child2['name'] = 'Mills';
        });

        future.then((_) {
          onChange.getLogs().verify(neverHappened);
        });

        // but async onChange drops information about changes in removed items.
        dataList.onChange.listen(expectAsync1((changeSet) {
          expect(changeSet, equals(new ChangeSet({
            1: new Change(child1, undefined),
            2: new Change(child2, undefined)
          })));
        }));
      });
    });

    test('Cleanify value when adding ', (){
      var _data = [{'aa': 1}, [1,2,3]];
      var data = new DataList.from(_data);
      var cdata = cleanify(_data);
      expect(data[0] is DataMap, isTrue);
      expect(data[1] is DataList, isTrue);
      expect(data, equals(cdata));
    });

    test('Do not change values that are already cleanified ', (){
      var child = new DataMap.from({'aa': 1});
      var data = new DataList.from([child]);
      expect(data[0] == child, isTrue);
    });
  });

}
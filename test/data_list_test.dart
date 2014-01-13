// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_list_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'package:unittest/mock.dart';
import 'dart:async';
import 'months.dart';

class ChangeEquals extends Matcher {
  Change change;
  ChangeEquals(this.change) {}
  bool matches(Change item, Map matchState) {
    return compare(item.oldValue, change.oldValue) &&
        compare(item.newValue, change.newValue);
  }
  
  bool compare(var a, var b) {
    if(a is DataReference) a = a.value;
    if(b is DataReference) b = b.value;
    return a == b;
  }

  /** This builds a textual description of the matcher. */
  Description describe(Description description) {
    return description.addDescriptionOf(change.toString());
  }

  Description describeMismatch(item, Description mismatchDescription,
      Map matchState, bool verbose) => mismatchDescription;
}
Matcher changeEquals(Change change) => new ChangeEquals(change);

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
        var changeSet = event['change'];
        expect(changeSet.changedItems[3], changeEquals(new Change(undefined, 'four')));
        expect(changeSet.changedItems.length, equals(1));
      }, count: 1));
      
      list.add('four');
      
      expect(list.length, equals(4));
      expect(list, orderedEquals(['one', 'two', 'three', 'four']));
    });
    
    test('removing last element fires change. (T03)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);
      
      list.onChangeSync.listen(expectAsync1((Map event) {
        var changeSet = event['change'];
        expect(changeSet.changedItems[2], changeEquals(new Change('three', undefined)));
        expect(changeSet.changedItems.length, equals(1));
      }, count: 1));
      
      list.removeLast();
      
      expect(list.length, equals(2));
      expect(list, orderedEquals(['one', 'two']));
    });
    
    test('removing element fires change. (T04)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);
      
      list.onChangeSync.listen(expectAsync1((Map event) {
        var changeSet = event['change'];
        expect(changeSet.changedItems.length, equals(2));
        expect(changeSet.changedItems[1], changeEquals(new Change('two', 'three')));
        expect(changeSet.changedItems[2], changeEquals(new Change('two', undefined)));
      }, count: 1));
      
      list.remove('two');
      
      expect(list.length, equals(2));
      expect(list, orderedEquals(['one', 'three']));     
    });
    
    test('add more items at once. (T05)', () {
      DataList list = new DataList.from(['one', 'two', 'three']);
      
      list.onChangeSync.listen(expectAsync1((Map event) {
        var changeSet = event['change'];
        expect(changeSet.changedItems.length, equals(2));
        expect(changeSet.changedItems[3], changeEquals(new Change(undefined, 'four')));
        expect(changeSet.changedItems[4], changeEquals(new Change(undefined, 'five')));
      }, count: 1));
      
      list.addAll(['four', 'five']);
      
      expect(list.length, equals(5));
      expect(list, orderedEquals(['one', 'two', 'three', 'four', 'five']));
    });
    
    test('removeWhere (T06)', () {
      // given
      DataList dataList = new DataList.from(['element1','doge', 'doge', 'element4']);

      dataList.onChangeSync.listen(expectAsync1((Map event) {
        var changeSet = event['change'];
        expect(changeSet.changedItems.length, equals(3));
        expect(changeSet.changedItems[1], changeEquals(new Change('doge', 'element4')));
        expect(changeSet.changedItems[2], changeEquals(new Change('doge', undefined)));
        expect(changeSet.changedItems[3], changeEquals(new Change('doge', undefined)));
      }, count: 1));
      
      // when
      dataList.removeWhere((el) => el == 'doge');

      // then
      expect(new List.from(dataList), unorderedEquals(
          ['element1', 'element4']));
    });
    
    test('retainWhere (T07)', () {
      // given
      DataList list = new DataList.from(['element1','doge', 'doge', 'element4']);

      list.onChangeSync.listen(expectAsync1((Map event) {
        var changeSet = event['change'];
        expect(changeSet.changedItems.length, equals(3));
        expect(changeSet.changedItems[1], changeEquals(new Change('doge', 'element4')));
        expect(changeSet.changedItems[2], changeEquals(new Change('doge', undefined)));
        expect(changeSet.changedItems[3], changeEquals(new Change('doge', undefined)));
      }, count: 1));
      
      // when
      list.retainWhere((el) => el != 'doge');

      // then
      expect(list, orderedEquals(
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

      list.onChangeSync.listen(expectAsync1((Map event) {
        var changeSet = event['change'];
        expect(changeSet.changedItems.length, equals(4));
        expect(changeSet.changedItems[1], changeEquals(new Change('two', 'four')));
        expect(changeSet.changedItems[2], changeEquals(new Change('three', 'five')));
        expect(changeSet.changedItems[3], changeEquals(new Change('two', undefined)));
        expect(changeSet.changedItems[4], changeEquals(new Change('three', undefined)));
      }, count: 1));
      
      // when
      list.removeRange(1, 3);
      expect(list, orderedEquals(
          ['one', 'four', 'five']));
    });
    
    test('setRange (T10)', () {
      // given
      DataList list = new DataList.from(['one', 'two', 'three', 'four', 'five']);
      var ref2 = list.ref(1);
      var ref3 = list.ref(2);
      list.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet.changedItems.length, equals(2));
        expect(changeSet.changedItems[1], changeEquals(new Change(ref2, ref2)));
        expect(changeSet.changedItems[2], changeEquals(new Change(ref3, ref3)));
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
        expect(changeSet.changedItems.length, equals(4));
        expect(changeSet.changedItems[1], changeEquals(new Change('two', 'TWO')));
        expect(changeSet.changedItems[2], changeEquals(new Change('three', 'THREE')));
        expect(changeSet.changedItems[3], changeEquals(new Change('four', undefined)));
        expect(changeSet.changedItems[4], changeEquals(new Change('five', undefined)));
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
        expect(changeSet.changedItems.length, equals(2));
        expect(changeSet.changedItems[3], changeEquals(new Change('five', 'four')));
        expect(changeSet.changedItems[4], changeEquals(new Change(undefined, 'five')));
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
        expect(changeSet.changedItems.length, equals(3));
        expect(changeSet.changedItems[2], changeEquals(new Change('five', 'three')));
        expect(changeSet.changedItems[3], changeEquals(new Change(undefined, 'four')));
        expect(changeSet.changedItems[4], changeEquals(new Change(undefined, 'five')));
      }, count: 1));
      
      // when
      list.insertAll(2, ['three', 'four']);
      expect(list, orderedEquals(
          ['one', 'two', 'three', 'four', 'five']));
    });
    
    group('nested', () {
      test('listens to changes of its children.', () {
        // given
        DataList dataList = new DataList.from([new Data(), new Data()]);

        // when
        dataList[0]['name'] = 'John Doe';
        dataList[1]['name'] = 'Mills';

        // then
        dataList.onChange.listen(expectAsync1((ChangeSet event) {
          expect(event.changedItems[0].addedItems, equals(['name']));
          expect(event.changedItems[1].addedItems, equals(['name']));
        }));
      });
      
      test('do not listen to removed children changes.', () {
        // given
        var child = new Data();
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
      
      test('do not listen after remove multiple children with removeRange.', () {
        // given
        var child1 = new Data();
        var child2 = new Data();
        DataList dataList = new DataList.from([new Data(), child1, child2]);
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
          expect(changeSet.removedItems, unorderedEquals([1,2]));
          expect(changeSet.addedItems.isEmpty, isTrue);
          expect(changeSet.strictlyChanged.isEmpty, isTrue);
        }));
      });
    });
  });
  
}
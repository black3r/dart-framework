// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'package:unittest/mock.dart';
import 'dart:async';


void main() {

  group('(Data)', () {

    test('initialize. (T01)', () {

      // when
      var data = new Data();

      // then
      expect(data.isEmpty, isTrue);
      expect(data.isNotEmpty, isFalse);
      expect(data.length, 0);
    });

    test('initialize with data. (T02)', () {
      // given
      var data = {
        'key1': 'value1',
        'key2': 'value2',
        'key3': 'value3',
      };

      // when
      var dataObj = new Data.from(data);

      // then
      expect(dataObj.isEmpty, isFalse);
      expect(dataObj.isNotEmpty, isTrue);
      expect(dataObj.length, equals(data.length));
      expect(dataObj.keys, equals(data.keys));
      expect(dataObj.values, equals(data.values));
      for (var key in data.keys) {
        expect(dataObj[key], equals(data[key]));
      }
    });

    test('is accessed like a map. (T03)', () {
      // given
      var dataObj =  new Data();

      // when
      dataObj['key'] = 'value';

      // then
      expect(dataObj['key'], equals('value'));
    });

    test('remove multiple keys. (T04)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      var dataObj = new Data.from(data);

      // when
      dataObj.removeAll(['key1', 'key2']);

      // then
      expect(dataObj.keys, equals(['key3']));
    });

    test('add multiple items. (T05)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      var dataObj = new Data();

      // when
      dataObj.addAll(data);

      // then
      expect(dataObj.length, equals(data.length));
      for (var key in dataObj.keys) {
        expect(dataObj[key], equals(data[key]));
      }
    });

    test('listen on multiple keys removed. (T06)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      var keysToRemove = ['key1', 'key2'];
      var dataObj = new Data.from(data);
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.removeAll(keysToRemove, author: 'John Doe');

      // then sync onChange propagates information about all changes and
      // removals

      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      var changeSet = event['change'];
      expect(changeSet.removedItems, unorderedEquals(keysToRemove));

      // but async onChange drops information about changes in removed items.
      dataObj.onChange.listen(expectAsync1((changeSet) {
        expect(changeSet.removedItems, unorderedEquals(keysToRemove));
        expect(changeSet.addedItems.isEmpty, isTrue);
      }));
    });

    test('listen on multiple keys added. (T07)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      var dataObj = new Data();
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.addAll(data, author: 'John Doe');

      // then sync onChange propagates information about all changes and
      // adds

      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args.first;
      expect(event['author'], equals('John Doe'));

      var changeSet = event['change'];
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.addedItems, unorderedEquals(data.keys));
      expect(changeSet.changedItems.length, equals(3));

      // but async onChange drops information about changes in added items.
      dataObj.onChange.listen(expectAsync1((changeSet) {
        expect(changeSet.addedItems, unorderedEquals(data.keys));
        expect(changeSet.removedItems.isEmpty, isTrue);
      }));
    });

    test('listen on {key, value} added. (T08)', () {
      // given
      var dataObj = new Data();

      // when
      dataObj['key'] = 'value';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.addedItems, equals(['key']));
      }));

    });

    test('listen synchronously on {key, value} added. (T09)', () {
      // given
      var dataObj = new Data();
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.add('key', 'value', author: 'John Doe');

      // then
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      expect(event['change'].addedItems, equals(['key']));
      expect(event['change'].changedItems.keys, equals(['key']));
    });

    test('listen synchronously on multiple {key, value} added. (T10)', () {
      // given
      var dataObj = new Data();
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj['key1'] = 'value1';
      dataObj['key2'] = 'value2';

      // then
      mock.getLogs().verify(happenedExactly(2));
      var event1 = mock.getLogs().logs[0].args.first;
      var event2 = mock.getLogs().logs[1].args.first;
      expect(event1['change'].addedItems, equals(['key1']));
      expect(event2['change'].addedItems, equals(['key2']));
    });

    test('listen on {key, value} removed. (T11)', () {
      // given
      var data = {'key': 'value'};
      var dataObj = new Data.from(data);

      // when
      dataObj.remove('key');

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems, unorderedEquals(['key']));
      }));

    });

    test('listen synchronously on {key, value} removed. (T12)', () {
      // given
      var dataObj = new Data.from({'key': 'value'});
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.remove('key', author: 'John Doe');

      // then
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().logs.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'].addedItems.isEmpty, isTrue);
      expect(event['change'].removedItems, unorderedEquals(['key']));
      expect(event['change'].changedItems.length, equals(1));

    });

    test('listen on {key, value} changed. (T13)', () {
      // given
      var data = {'key': 'oldValue'};
      var dataObj = new Data.from(data);
      
      // when
      dataObj['key'] = 'newValue';
      
      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.length, equals(1));
        var change = event.changedItems['key'];
        expect(change.oldValue, equals('oldValue'));
        expect(change.newValue, equals('newValue'));
      }));
    });

    test('propagate multiple changes in single [ChangeSet]. (T14)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);

      // when
      dataObj['key1'] = 'newValue1';
      dataObj.remove('key2');
      dataObj['key3'] = 'value3';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.keys, unorderedEquals(['key1', 'key2', 'key3']));
        expect(event.removedItems, unorderedEquals(['key2']));
        expect(event.addedItems, unorderedEquals(['key3']));
      }));
    });

    test('when property is added then changed, only addition is in the [ChangeSet]. (T15)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);

      // when
      dataObj['key3'] = 'John Doe';
      dataObj['key3'] = 'John Doe II.';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems, unorderedEquals(['key3']));
        expect(event.removedItems, unorderedEquals([]));
      }));
    });

    test('when existing property is removed then re-added, this is a change. (T16)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);

      // when
      dataObj.remove('key1');
      dataObj['key1'] = 'John Doe II.';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.keys, unorderedEquals(['key1']));

        Change change = event.changedItems['key1'];
        expect(change.oldValue.value, equals('value1'));
        expect(change.newValue.value, equals('John Doe II.'));

        expect(event.addedItems, unorderedEquals([]));
        expect(event.removedItems, unorderedEquals([]));
      }));
    });

    test('when property is changed then removed, only deletion is in the [ChangeSet]. (T17)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);

      dataObj['key1'] = 'John Doe';

      // when
      dataObj.remove('key1');

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems, unorderedEquals(['key1']));
      }));
    });

    test('when property is added then removed, no changes are broadcasted. (T18)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);

      // when
      dataObj['key3'] = 'John Doe';
      dataObj.remove('key3');

      // then
      dataObj.onChange.listen(protectAsync1((e) => expect(true, isFalse)));
     });

    test('when property is added, changed then removed, no changes are broadcasted. (T19)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);

      // when
      dataObj['key3'] = 'John Doe';
      dataObj['key3'] = 'John Doe II';
      dataObj.remove('key3');

      // then
      dataObj.onChange.listen(protectAsync1((e) => expect(true, isFalse)));
     });

    test('Data implements map.clear(). (T20)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.clear(author: 'John Doe');

      // then
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      expect(dataObj.isEmpty, isTrue);
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems, unorderedEquals(['key1', 'key2']));
      }));

    });

    test('Data implements map.containsValue(). (T21)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};

      // when
      var dataObj = new Data.from(data);

      // then
      expect(dataObj.containsValue('value1'), isTrue);
      expect(dataObj.containsValue('notInValues'), isFalse);
    });

    test('Data implements map.forEach(). (T22)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.from(data);
      var dataCopy = new Data();

      // when
      dataObj.forEach((key, value) {
        dataCopy[key] = value;
      });

      // then
      expect(dataCopy, equals(data));
    });

    test('Data implements map.putIfAbsent(). (T23)', () {
      // given
      Map<String, int> data = {'key1': "value1"};
      var dataObj = new Data.from(data);

      // when
        dataObj.putIfAbsent('key1', () => '');
        dataObj.putIfAbsent('key2', () => '');

      // then
      expect(dataObj['key1'], equals('value1'));
      expect(dataObj['key2'], equals(''));
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems,unorderedEquals(['key2']));
      }));
    });
  });


  group('(Nested Data)', () {

    test('listens to changes of its children.', () {
      // given
      var dataObj = new Data.from({'child': new Data()});

      // when
      dataObj['child']['name'] = 'John Doe';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems['child'].addedItems, equals(['name']));
      }));
    });

    test('do not listen to removed children changes.', () {
      // given
      var child = new Data();
      var dataObj = new Data.from({'child': child});
      var onChange = new Mock();

      // when
      dataObj.remove('child');
      var future = new Future.delayed(new Duration(milliseconds: 20), () {
        dataObj.onChangeSync.listen((e) => onChange(e));
        child['name'] = 'John Doe';
      });

      // then
      future.then((_) {
        onChange.getLogs().verify(neverHappened);
      });
    });

    test('do not listen to changed children changes.', () {
      // given
      var childOld = new Data();
      var childNew = new Data();
      var dataObj = new Data.from({'child': childOld});
      var onChange = new Mock();

      // when
      dataObj['child'] = childNew;
      var future = new Future.delayed(new Duration(milliseconds: 20), () {
        dataObj.onChangeSync.listen((e) { onChange(e); print(e); });
        childOld['name'] = 'John Doe';
      });

      // then
      future.then((_) {
        onChange.getLogs().verify(neverHappened);
      });
    });

    test('listen on multiple children added.', () {
      // given
      var data = {'child1': new Data(), 'child2': new Data(), 'child3': new Data()};
      var dataObj = new Data();
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.addAll(data, author: 'John Doe');

      // then sync onChange propagates information about all changes and
      // adds
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args.first;
      expect(event['author'], equals('John Doe'));

      var changeSet = event['change'];
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.addedItems, unorderedEquals(data.keys));
      expect(changeSet.changedItems.length, equals(3));

      // but async onChange drops information about changes in added items.
      dataObj.onChange.listen(expectAsync1((changeSet) {
        expect(changeSet.addedItems, unorderedEquals(data.keys));
        expect(changeSet.removedItems.isEmpty, isTrue);
      }));
    });

    test('remove children.', () {
      // given
      var dataObj = new Data.from({'child1': new Data(), 'child2': new Data(), 'child3': new Data()});
      List keysToRemove = ['child1', 'child2'];
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.removeAll(keysToRemove, author: 'John Doe');

      // then
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      var changeSet = event['change'];
      expect(changeSet.removedItems, unorderedEquals(keysToRemove));

      // but async onChange drops information about changes in removed items.
      dataObj.onChange.listen(expectAsync1((changeSet) {
        expect(changeSet.removedItems, unorderedEquals(keysToRemove));
        expect(changeSet.addedItems.isEmpty, isTrue);
      }));
    });

    test('when property is added then removed, no changes are broadcasted. (T18)', () {
      // given
      var dataObj = new Data();
      var child = new Data();

      // when
      dataObj['child'] = child;
      dataObj.remove('child');

      // then
      dataObj.onChange.listen(protectAsync1((e) => expect(true, isFalse)));
    });

    test('when child Data is removed then added, this is a change.', () {
      // given
      var childOld = new Data();
      var childNew = new Data();
      var dataObj = new Data.from({'child': childOld});
      var onChange = new Mock();

      // when
      dataObj.remove('child');
      dataObj.add('child', childNew);

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.keys, unorderedEquals(['child']));

        Change change = event.changedItems['child'];
        expect(change.oldValue.value, equals(childOld));
        expect(change.newValue.value, equals(childNew));

        expect(event.addedItems, unorderedEquals([]));
        expect(event.removedItems, unorderedEquals([]));
      }));
    });

    test('when child Data is removed then added, only one subsription remains.', () {
      // given
      var child = new Data();
      var dataObj = new Data.from({'child': child});
      var onChange = new Mock();

      // when
      dataObj.remove('child');
      dataObj.add('child', child);

      var future = new Future.delayed(new Duration(milliseconds: 20), () {
        dataObj.onChangeSync.listen((e) => onChange(e));
        child['key'] = 'value';
      });

      // then
      future.then((_) {
        onChange.getLogs().verify(happenedOnce);
      });
    });
    
    test('data can be replaced by another data.', () {
      // given
      var dataObj = new Data.from({'child': new Data()});

      // when
      dataObj['child']['name'] = 'John Doe';
      dataObj['child'] = new Data();

      // then no Error is thrown
    });
  });
  
  group('(DataReference)', () {
    test('is assigned to elements key. (T1)', () { 
      //given
      var data1 = new Data();
      var data2 = new Data();
      
      //when
      data1['key'] = data2;
      data1['key2'] = 'value';
      
      //then
      expect(data1.ref('key').value, equals(data2));
      expect(data1.ref('key2').value, equals('value'));
    });
    
    test('does not change, when changing value. (T2)', () { 
      //given
      var data = new Data();
      var data1 = new Data();
      var data2 = new Data();
      
      //when
      data['key'] = data1;
      DataReference ref1 = data.ref('key');
      data['key'] = data2;
      DataReference ref2 = data.ref('key');
      
      //then
      expect(ref1, equals(ref2));
    });
    
    test('is unique for key. (T3)', () { 
      //given
      var data = new Data();
      var data1 = new Data();
      
      //when
      data['key1'] = data1;
      DataReference ref1 = data.ref('key1');
      data['key2'] = data1;
      DataReference ref2 = data.ref('key2');
      
      //then
      expect(ref1, isNot(equals(ref2)));
    });
    
    test('changes when element is removed and re-added. (T4)', () { 
      //given
      var data = new Data();
      var data1 = new Data();
      
      //when
      data['key'] = data1;
      DataReference ref1 = data.ref('key');
      data.remove('key');
      
      data['key'] = data1;
      DataReference ref2 = data.ref('key');
      
      //then
      expect(ref1, isNot(equals(ref2)));
    });
    
    test('are passed in Change / ChangeSet. (T5)', () {
      // given
      var childOld = new Data();
      var childNew = new Data();
      var dataObj = new Data.from({'child': childOld});
      var onChange = new Mock();

      // when
      DataReference refOld = dataObj.ref('child');
      dataObj.remove('child');
      dataObj.add('child', childNew);
      DataReference refNew = dataObj.ref('child');
      
      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.keys, unorderedEquals(['child']));

        Change change = event.changedItems['child'];
        expect(change.oldValue, equals(refOld));
        expect(change.newValue, equals(refNew));
      }));
    });
  });
}

// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_map_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'package:unittest/mock.dart';
import 'dart:async';
import 'matchers.dart' as matchers;

var equals = matchers.equals;

void main() {

  group('(DataMap)', () {

    test('initialize. (T01)', () {

      // when
      var data = new DataMap();

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
      var dataObj = new DataMap.from(data);

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
      var dataObj =  new DataMap();

      // when
      dataObj['key'] = 'value';

      // then
      expect(dataObj['key'], equals('value'));
      expect(dataObj['nonexistent key'], equals(null));
    });

    test('remove multiple keys. (T04)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      var dataObj = new DataMap.from(data);

      // when
      dataObj.removeAll(['key1', 'key2']);

      // then
      expect(dataObj.keys, equals(['key3']));
    });

    test('add multiple items. (T05)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      var dataObj = new DataMap();

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
      var dataObj = new DataMap.from(data);
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.removeAll(keysToRemove, author: 'John Doe');

      // then sync onChange propagates information about all changes and
      // removals
      ChangeSet expectedChangeSet = new ChangeSet({
        'key1': new Change('value1', undefined),
        'key2': new Change('value2', undefined)
      });
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      expect(event['change'], equals(expectedChangeSet));

      // but async onChange drops information about changes in removed items.
      dataObj.onChange.listen(expectAsync1((changeSet) {
        expect(changeSet, equals(expectedChangeSet));
      }));
    });

    test('listen on multiple keys added. (T07)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
      var dataObj = new DataMap();
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.addAll(data, author: 'John Doe');

      // then sync onChange propagates information about all changes and
      // adds

      ChangeSet expectedChangeSet = new ChangeSet({
        'key1': new Change(undefined, 'value1'),
        'key2': new Change(undefined, 'value2'),
        'key3': new Change(undefined, 'value3')
      });

      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'], equals(expectedChangeSet));

      // but async onChange drops information about changes in added items.
      dataObj.onChange.listen(expectAsync1((changeSet) {
        expect(changeSet, equals(expectedChangeSet));
      }));
    });

    test('listen on {key, value} added. (T08)', () {
      // given
      var dataObj = new DataMap();

      // when
      dataObj['key'] = 'value';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key': new Change(undefined, 'value')
        })));
      }));

    });

    test('listen synchronously on {key, value} added. (T09)', () {
      // given
      var dataObj = new DataMap();
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.add('key', 'value', author: 'John Doe');

      // then
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      expect(event['change'], equals(new ChangeSet({
        'key': new Change(undefined, 'value')
      })));
    });

    test('listen synchronously on multiple {key, value} added. (T10)', () {
      // given
      var dataObj = new DataMap();
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
      var dataObj = new DataMap.from(data);

      // when
      dataObj.remove('key');

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key': new Change('value', undefined)
        })));
      }));

    });

    test('listen synchronously on {key, value} removed. (T12)', () {
      // given
      var dataObj = new DataMap.from({'key': 'value'});
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.remove('key', author: 'John Doe');

      // then
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().logs.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'], equals(new ChangeSet({
        'key': new Change('value', undefined)
      })));
    });

    test('listen on {key, value} changed. (T13)', () {
      // given
      var data = {'key': 'oldValue'};
      var dataObj = new DataMap.from(data);

      // when
      dataObj['key'] = 'newValue';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        var ref = dataObj.ref('key');
        expect(event, equals(new ChangeSet({
          'key': new Change('oldValue', 'newValue')
        })));
      }));
    });

    test('propagate multiple changes in single [ChangeSet]. (T14)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new DataMap.from(data);

      // when
      dataObj['key1'] = 'newValue1';
      dataObj.remove('key2');
      dataObj['key3'] = 'value3';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key1': new Change('value1', 'newValue1'),
          'key2': new Change('value2', undefined),
          'key3': new Change(undefined, 'value3')})));
      }));
    });

    test('when property is added then changed, only addition is in the [ChangeSet]. (T15)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new DataMap.from(data);

      // when
      dataObj['key3'] = 'John Doe';
      dataObj['key3'] = 'John Doe II.';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key3': new Change(undefined, 'John Doe II.')
        })));
      }));
    });

    test('when existing property is removed then re-added, this is a change. (T16)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new DataMap.from(data);

      // when
      dataObj.remove('key1');
      dataObj['key1'] = 'John Doe II.';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key1': new Change('value1', 'John Doe II.')
        })));
      }));
    });

    test('when property is changed then removed, only deletion is in the [ChangeSet]. (T17)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new DataMap.from(data);

      dataObj['key1'] = 'John Doe';

      // when
      dataObj.remove('key1');

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key1': new Change('value1', undefined)
        })));
      }));
    });

    test('when property is added then removed, changes are broadcasted. (T18)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new DataMap.from(data);

      // when
      dataObj['key3'] = 'John Doe';
      dataObj.remove('key3');

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event, equals(new ChangeSet({
          'key3': new Change(undefined, undefined)
        })));
      }));
     });

    test('Data implements map.clear(). (T20)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new DataMap.from(data);
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));

      // when
      dataObj.clear(author: 'John Doe');

      // then
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      expect(event['change'], equals(new ChangeSet({
        'key1': new Change('value1', undefined),
        'key2': new Change('value2', undefined)
      })));
      expect(dataObj.isEmpty, isTrue);

      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key1': new Change('value1', undefined),
          'key2': new Change('value2', undefined)
        })));
      }));

    });

    test('Data implements map.containsValue(). (T21)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};

      // when
      var dataObj = new DataMap.from(data);

      // then
      expect(dataObj.containsValue('value1'), isTrue);
      expect(dataObj.containsValue('notInValues'), isFalse);
    });

    test('Data implements map.forEach(). (T22)', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new DataMap.from(data);
      var dataCopy = new DataMap();

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
      var dataObj = new DataMap.from(data);

      // when
        dataObj.putIfAbsent('key1', () => '');
        dataObj.putIfAbsent('key2', () => '');

      // then
      expect(dataObj['key1'], equals('value1'));
      expect(dataObj['key2'], equals(''));
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(new ChangeSet({
          'key2': new Change(undefined, '')
        })));
      }));
    });

    test('Cleanify value when adding ', (){
      var _data = {'a': {'aa': 1}, 'b': [1,2,3]};
      var data = new DataMap.from(_data);
      var cdata = cleanify(_data);
      expect(data['a'] is DataMap, isTrue);
      expect(data['b'] is DataList, isTrue);
      expect(data, equals(cdata));
    });

    test('Do not change values that are already cleanified ', (){
      var child = new DataMap.from({'aa': 1});
      var data = new DataMap.from({'a': child});
      expect(data['a'] == child, isTrue);
    });

  });

  group('(Nested Data)', () {

    test('listens to changes of its children.', () {
      // given
      var dataObj = new DataMap.from({'child': new DataMap()});

      // when
      dataObj['child']['name'] = 'John Doe';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems['child'].addedItems, equals(['name']));
      }));
    });

    test('do not listen to removed children changes.', () {
      // given
      var child = new DataMap();
      var dataObj = new DataMap.from({'child': child});
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
      var childOld = new DataMap();
      var childNew = new DataMap();
      var dataObj = new DataMap.from({'child': childOld});
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
      var data = {'child1': new DataMap(), 'child2': new DataMap(), 'child3': new DataMap()};
      var dataObj = new DataMap();
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

      expect(event['change'], equals(new ChangeSet({
        'child1': new Change(undefined, data['child1']),
        'child2': new Change(undefined, data['child2']),
        'child3': new Change(undefined, data['child3'])
      })));

      // but async onChange drops information about changes in added items.
      dataObj.onChange.listen(expectAsync1((changeSet) {
        expect(changeSet.addedItems, unorderedEquals(data.keys));
        expect(changeSet.removedItems.isEmpty, isTrue);
      }));
    });

    test('remove children.', () {
      // given
      var data = {'child1': new DataMap(), 'child2': new DataMap(), 'child3': new DataMap()};
      var dataObj = new DataMap.from(data);
      List keysToRemove = ['child1', 'child2'];
      var mock = new Mock();
      dataObj.onChangeSync.listen((event) => mock.handler(event));
      // when
      dataObj.removeAll(keysToRemove, author: 'John Doe');

      // then
      ChangeSet expected = new ChangeSet({
        'child1': new Change(data['child1'],undefined),
        'child2': new Change(data['child2'],undefined),
      });
      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().first.args[0];
      expect(event['author'], equals('John Doe'));
      expect(event['change'], equals(expected));

      // but async onChange drops information about changes in removed items.
      dataObj.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet, equals(expected));
      }));
    });

    test('when child Data is removed then added, this is a change.', () {
      // given
      var childOld = new DataMap();
      var childNew = new DataMap();
      var dataObj = new DataMap.from({'child': childOld});
      var onChange = new Mock();

      // when
      dataObj.remove('child');
      dataObj.add('child', childNew);

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event, equals(new ChangeSet({
          'child': new Change(childOld, childNew)
        })));
      }));
    });

    test('when child Data is removed then added, only one subsription remains.', () {
      // given
      var child = new DataMap();
      var dataObj = new DataMap.from({'child': child});
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
      DataMap data = new DataMap();
      data['name'] = new DataMap();
      data['name'] = new DataMap();
      data['name']['first'] = 'Guybrush';

      data.onChange.listen(expectAsync1((change){
        expect(change.equals(new ChangeSet({'name': new Change(undefined, data['name'])})), isTrue);
      }));
    });
  });

  group('(DataReference)', () {
    test('is assigned to elements key. (T1)', () {
      //given
      var data1 = new DataMap();
      var data2 = new DataMap();

      //when
      data1['key'] = data2;
      data1['key2'] = 'value';

      //then
      expect(data1.ref('key').value, equals(data2));
      expect(data1.ref('key2').value, equals('value'));
      expect(data1.ref('nonexistent key'), equals(null));
    });

    test('does not change, when changing value. (T2)', () {
      //given
      var data = new DataMap();
      var data1 = new DataMap();
      var data2 = new DataMap();
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
      var data = new DataMap();
      var data1 = new DataMap();

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
      var data = new DataMap();
      var data1 = new DataMap();

      //when
      data['key'] = data1;
      DataReference ref1 = data.ref('key');
      data.remove('key');
      data['key'] = data1;
      DataReference ref2 = data.ref('key');

      //then
      expect(ref1, isNot(equals(ref2)));
    });

    test('are not passed in Change / ChangeSet. (T5)', () {
      // given
      var childOld = new DataMap();
      var childNew = new DataMap();
      var dataObj = new DataMap.from({'child': childOld});
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
        expect(change.oldValue, equals(refOld.value));
        expect(change.newValue, equals(refNew.value));
      }));
    });
  });

}

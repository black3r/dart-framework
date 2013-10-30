// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('Collection', () {

    var data;
    setUp(() {
      data = [];
      for (var i = 0; i <= 10; i++) {
        data.add(new Data.fromMap({'id': i}));
      }
    });

    test('initialize.', () {
      // when
      var collection = new DataCollection();

      // then
      expect(collection.length, equals(0));
      expect(collection, equals([]));
    });

    test('initialize with data.', () {
      // when
      var collection = new DataCollection.from(data);

      // then
      expect(collection.length, equals(data.length));
      expect(collection, unorderedEquals(data));
    });

    test('multiple listeners listen to onChange.', () {
      // given
      var collection = new DataCollection();

      // when
      collection.onChange.listen((event) => null);
      collection.onChange.listen((event) => null);

      // Then no exception is thrown.
    });

    test('add data object.', () {
      // given
      var collection = new DataCollection();

      // when
      for (var dataObj in data) {
        collection.add(dataObj);
      }

      // then
      expect(collection.contains(data[0]), isTrue);
      expect(collection, unorderedEquals(data));
    });

    test('remove dataObject.', () {
      // given
      var dataObjs = [new Data(), new Data()];
      var collection = new DataCollection.from(dataObjs);

      // when
      collection.remove(dataObjs[0]);

      // then
      expect(collection.contains(dataObjs[0]), isFalse);
      expect(collection, unorderedEquals([dataObjs[1]]));
    });

    test('clear.', () {
      // given
      var collection = new DataCollection.from(data);

      // when
      collection.clear();

      // then
      expect(collection.isEmpty, isTrue);
    });

    test('listen on data object added.', () {
      // given
      var collection = new DataCollection();
      var mock = new Mock();
      collection.onChangeSync.listen((event) => mock.handler(event));

      // when
      collection.add(data[0], author: 'John Doe');

      mock.getLogs().verify(happenedOnce);
      var event = mock.getLogs().logs.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'].addedItems, unorderedEquals([data[0]]));

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems, unorderedEquals([data[0]]));
      }));
    });

    test('listen on data object removed.', () {
      // given
      var collection = new DataCollection.from(data);
      var mock = new Mock();
      collection.onChangeSync.listen((event) => mock.handler(event));

      // when
      collection.remove(data[0], author: "John Doe");

      // then
      mock.log.verify(happenedOnce);
      var event = mock.log.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'].removedItems, unorderedEquals([data[0]]));

      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems, unorderedEquals([data[0]]));
      }));
    });

    test('listen synchronously on multiple data objects removed.', () {
      // given
      var collection = new DataCollection.from(data);
      var mock = new Mock();
      collection.onChangeSync.listen((event) => mock.handler(event));

      // when
      collection.remove(data[0], author: 'John Doe');
      collection.remove(data[1], author: 'Peter Pan');

      // then
      mock.log.verify(happenedExactly(2));
      var event1 = mock.log.logs[0].args.first;
      var event2 = mock.log.logs[1].args.first;

      expect(event1['author'], equals('John Doe'));
      expect(event1['change'].removedItems, equals([data[0]]));

      expect(event2['author'], equals('Peter Pan'));
      expect(event2['change'].removedItems, equals([data[1]]));
    });

    test('listen on data object changes.', () {
      // given
      var collection = new DataCollection.from(data);
      var mock = new Mock();
      collection.onChangeSync.listen((event) => mock.handler(event));

      // when
      data[0].add('size', 'XXL', author: 'John Doe');

      // then
      mock.log.verify(happenedOnce);
      var event = mock.log.first.args.first;
      expect(event['author'], equals('John Doe'));
      expect(event['change'].changedItems[data[0]].addedItems, equals(['size']));

      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.length, equals(1));
        expect(event.changedItems[data[0]].addedItems,
            unorderedEquals(['size']));
      }));
    });

    test('do not listen on removed data object changes.', () {
      // given
      var collection = new DataCollection.from(data);

      // when
      collection.remove(data[0]);
      data[0]['name'] = 'John Doe';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
      }));
    });

    test('do not listen on cleared data object changes.', () {
      // given
      var collection = new DataCollection.from(data);

      // when
      collection.clear();
      data[0]['name'] = 'John Doe';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
      }));
    });

    test('propagate multiple changes in single [ChangeSet].', () {
      // given
      var collection = new DataCollection.from(data);
      var newDataObj = new Data();

      // when
      collection.remove(data[0]);
      collection.add(newDataObj);
      data[1]['name'] = 'James Bond';
      data[2]['name'] = 'John Doe';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems, unorderedEquals([newDataObj]));
        expect(event.removedItems, unorderedEquals([data[0]]));
        expect(event.changedItems.keys,
            unorderedEquals([data[1], data[2]]));
      }));
    });

  });
}

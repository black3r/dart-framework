// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library DataCollectionTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

void main() {

  group('(Collection)', () {

    var data, data1, dataMarienka;
    setUp(() {
      data = [];
      
      for (var i = 0; i <= 10; i++) {
        data.add(new Data.fromMap({'id': i}));
      }
      dataMarienka = new Data.fromMap({'id': 100, 'name': 'Marienka'});
      
    });

    test('initialize. (T01)', () {
      // when
      var collection = new DataCollection();

      // then
      expect(collection.length, equals(0));
      expect(collection, equals([]));
    });

    test('initialize with data. (T02)', () {
      // when
      var collection = new DataCollection.from(data);

      // then
      expect(collection.length, equals(data.length));
      expect(collection, unorderedEquals(data));
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
      var collection = new DataCollection();

      // when
      for (var dataObj in data) {
        collection.add(dataObj);
      }

      // then
      expect(collection.contains(data[0]), isTrue);
      expect(collection, unorderedEquals(data));
    });

    test('remove dataObject. (T05)', () {
      // given
      var dataObjs = [new Data(), new Data()];
      var collection = new DataCollection.from(dataObjs);

      // when
      collection.remove(dataObjs[0]);

      // then
      expect(collection.contains(dataObjs[0]), isFalse);
      expect(collection, unorderedEquals([dataObjs[1]]));
    });

    test('clear. (T06)', () {
      // given
      var collection = new DataCollection.from(data);

      // when
      collection.clear();

      // then
      expect(collection.isEmpty, isTrue);
    });

    test('listen on data object added. (T07)', () {
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

    test('listen on data object removed. (T08)', () {
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

    test('listen synchronously on multiple data objects removed. (T09)', () {
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

    test('listen on data object changes. (T10)', () {
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

    test('do not listen on removed data object changes. (T11)', () {
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

    test('do not listen on cleared data object changes. (T12)', () {
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

    test('propagate multiple changes in single [ChangeSet]. (T13)', () {
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
    
    test('propagate multiple data object changes in single [ChangeSet]. (T14)', () {
      // given
      var collection = new DataCollection.from(data);

      // when
      data[0]['name'] = 'John Doe';
      data[1]['name'] = 'James Bond';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.keys,
            unorderedEquals([data[0], data[1]]));
      }));
      
    });

    test('add, change, remove in one event loop propagate a change. (T15)', () {
      // given
      var collection = new DataCollection.from(data);
      
      // when
      collection.remove(data[0]);
      data[0]['id'] = 5;
      collection.add(data[0]);
      
      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.keys, unorderedEquals([data[0]]));
      }));
    });
    
    test('after removing, collection does not listen to changes on object anymore. (T16)', () {
      // given
      var collection = new DataCollection.from(data);
      
      // when
      collection.remove(data[0]);
      Timer.run(() {
        data[0]['key'] = 'value';
        collection.onChange.listen((c) => expect(true, isFalse)); 
      });
      
      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedItems, equals([data[0]]));
      }));
    });

    test('Find by index. (T17)', () {
      
      // given
      var collection = new DataCollection.from(data);

      // when
      collection.addIndex(['id']);

      // then
      expect(collection.findBy('id', 7), equals([data[7]]));
      expect(collection.findBy('id', 11).isEmpty, isTrue);
    });
  
    test('Find by non-existing index. (T18)', () {
      
      // given
      var collection = new DataCollection.from(data);
      
      // when      

      // then
      expect(() => collection.findBy('name', 'John Doe'), throws);
    });
  
    test('Initialize and find by index. (T19)', () {
      
      // given
      var collection = new DataCollection.from(data);
      data[0]['name'] = 'Jozef';
      data[1]['name'] = 'Jozef';
      data[2]['name'] = 'Anicka';
      
      // when      
      collection.addIndex(['id','name']);
      
      // then
      expect(collection.findBy('name', 'Jozef'), unorderedEquals([data[0], data[1]]));
    });
    
    test('Index updated synchronously after addition. (T20)', () {
      
      // given
      var collection = new DataCollection.from(data);
      collection.addIndex(['id','name']);
      
      // when      
      collection.add(dataMarienka);
      
      // then
      var result = collection.findBy('name', 'Marienka');
      expect(result, equals([dataMarienka]));
    });
    
    test('Index updated synchronously after deletion. (T21)', () {
      
      // given
      var collection = new DataCollection.from(data); 
      collection.addIndex(['id']);
      
      // when      
      collection.remove(data[0]);
      
      // then
      expect(collection.findBy('id', 0).isEmpty, isTrue);
      expect(collection.findBy('id', 1), equals([data[1]]));
    });

    test('Index updated synchronously after change. (T22)', () {
      
      // given
      var collection = new DataCollection.from(data);      
      collection.addIndex(['id']);
      
      // when      
      data[0]['id'] = 47;
      
      // then
      expect(collection.findBy('id', 47), equals([data[0]]));
      expect(collection.findBy('id', 0).isEmpty, isTrue);
    });

    test('Remove by index works. (T23)', () {
      
      // given
      var collection = new DataCollection.from(data);      
      collection.addIndex(['id']);
      data[1]['id'] = 0;
      
      // when      
      collection.removeBy('id', 0);
      
      // then
      expect(collection.findBy('id', 0).isEmpty, isTrue);      
    });

    test('Remove by index works (version with no items to remove). (T24)', () {
      
      // given
      var collection = new DataCollection.from(data);      
      collection.addIndex(['id']);
      
      // when      
      collection.removeBy('id', 47);
      
      // then
      expect(true, isTrue); // no exception was thrown      
    });
    
    test('Remove by index raises an exception on unindexed property. (T25)', () {
      
      // given
      var collection = new DataCollection.from(data);      
      collection.addIndex(['id']);
      
      // when            
      
      // then
      expect(() => collection.removeBy('name', 'John Doe'), throws);           
    });
    
   test('Index updated synchronously after deletion. (T26)', () {
      
      // given
      var collection = new DataCollection.from(data);      
      collection.addIndex(['id']);
      
      // when      
      collection.remove(data[0]);
      
      // then
      expect(collection.findBy('id', 0).isEmpty, isTrue);
    });
   
   test('Index updated synchronously after addition. (T27)', () {
     
     // given
     data1 = new Data.fromMap({"id":42});
     var collection = new DataCollection.from(data);      
     collection.addIndex(['id']);
     
     // when      
     collection.add(data1);
     // data[1]['id'] = 45; --> this won't work. It takes one event loop to propagate the change.
     
     // then
     expect(collection.findBy('id', 42), equals([data1]));
   });
  });
}
// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library DataCollectionTest;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(Collection)', () {

    var data0, data1, data2, data3, data100;
    var data;
    setUp(() {
      data = [];
      for (var i = 0; i <= 10; i++) {
        data.add(new Data.fromMap({'id': i}));
      }
      data100 = new Data.fromMap({'id': 100, 'name': 'Marienka'});
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

      // when
      collection.add(data[0]);

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

      // when
      collection.remove(data[0]);

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems, unorderedEquals([data[0]]));
      }));
    });

    test('listen on data object changes.', () {
      // given
      var collection = new DataCollection.from(data);

      // when
      data[0]['name'] = 'John Doe';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.length, equals(1));
        expect(event.changedItems[data[0]].addedItems,
            unorderedEquals(['name']));
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

    test('propagate multiple add/remove changes in single [ChangeSet].', () {
      // given
      var collection = new DataCollection.from(data);
      var newDataObj = new Data();

      // when
      collection.remove(data[0]);
      collection.add(newDataObj);

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems, unorderedEquals([newDataObj]));
        expect(event.removedItems, unorderedEquals([data[0]]));
      }));
    });

    test('propagate multiple data object changes in single [ChangeSet].', () {
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

    test('propagate multiple data object changes in single [ChangeSet].', () {
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


    test('Find by index. (T15)', () {
      
      // given
      var collection = new DataCollection.from(data);

      // when
      collection.addIndex(['id']);

      // then
      expect(collection.findBy('id', 7), equals([data[7]]));
      expect(collection.findBy('id', 11).isEmpty, isTrue);
    });
  
    test('Find by non-existing index. (T16)', () {
      
      // given
      var collection = new DataCollection.from(data);
      
      // when      

      // then
      expect(() => collection.findBy('name', 'John Doe'), throws);
    });
  
    test('Initialize and find by index. (T17)', () {
      
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
    
    test('Index updated in real-time after addition. (T18)', () {
      
      // given
      var collection = new DataCollection.from(data);
      collection.addIndex(['id','name']);
      
      // when      
      collection.add(data100);
      
      // then
      var result = collection.findBy('name', 'Marienka');
      expect(result, equals([data100]));
    });
    
    
  });
  
  
}

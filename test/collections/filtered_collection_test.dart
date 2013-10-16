// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('Collection', () {

    var data0, data1, data2, data3;
    var data;
    setUp(() {
      
      data = [];
      for (var i = 0; i <= 10; i++) {
        data.add(new Data.fromMap({'id': i}));
      }
      
      
      var map11 = {'id': 11, 'name': 'jozef'};
      var map12 = {'id': 12, 'name': 'jozef'};
      
      data.add(new Data.fromMap(map11));
      data.add(new Data.fromMap(map12));      
    });


    test('simple filtering.', () {
      // given
      var collection = new DataCollection.from(data);
      
      // when
      var filteredData = collection.where((d)=>d['id']==7);
      var filteredData2 = collection.where((d)=>d['id']==100);
      var filteredData3 = collection.where((d)=>d['ID']==1);
      
      //then
      expect(filteredData, unorderedEquals([data[7]]));
      expect(filteredData2, unorderedEquals([]));
      expect(filteredData3, unorderedEquals([]));
    });
    

    test('double/triple filtering.', () {
      // given 
      var collection = new DataCollection.from(data);
      
      // when
      var filteredData = collection.where((d)=>d['id'] == 7)
                                   .where((d)=>d['id'] == 7);
      var filteredData2 = collection.where((d)=>d['name']=='jozef');      
      var filteredData3 = filteredData2.where((d)=>d['id']==11);
      var filteredData4 = filteredData3.where((d)=>d['id']==17);
      
      // then
      expect(filteredData, unorderedEquals([data[7]]));
      expect(filteredData2, unorderedEquals([data[11], data[12]]));
      expect(filteredData3, unorderedEquals([data[11]]));
      expect(filteredData4.isEmpty, isTrue);
    });
    

    test('adding a new data object to the filtered collection', () {
      // given
      var collection = new DataCollection.from(data);
      var filteredData = collection.where((d)=>d['name']=='jozef');  //data[11], data[12]
      
      // when 
        // this one will make it to [filteredData]
      var map = {'id': 47, 'name': 'jozef'};
      collection.add(new Data.fromMap(map));
      
        // and this one won't
      map = {'id': 49, 'name': 'anicka'};
      collection.add(new Data.fromMap(map));
      
      filteredData.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems.length, equals(1));
        expect(event.addedItems.first['id'], equals(47));
      }));
      
      
    });
    
    test('removing a data object from the filtered collection', () {
      // given
      var collection = new DataCollection.from(data);
      var filteredData = collection.where((d)=>d['name']=='jozef'); //data[11], data[12]

      // when
      data[11]['name'] = "Anicka";
      
      filteredData.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems.length, equals(1));
        expect(event.removedItems.first['id'], equals(11));
      }));
    });
    
    
    test('changing a data object in the underlying collection - gets added to the filtered collection', () {
      // given
      var collection = new DataCollection.from(data);
      var filteredData = collection.where((d)=>d['name']=='jozef'); //data[11], data[12]
    
      // when
      data[10]['name'] = "jozef";
      
      filteredData.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(event.addedItems, unorderedEquals([data[10]]));
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(filteredData, unorderedEquals([data[10], data[11], data[12]]));
      }));
    });
    
    test('changing a data object in the underlying collection - gets removed from the filtered collection', () {
      // given
      var collection = new DataCollection.from(data);
      var filteredData = collection.where((d)=>d['name']=='jozef'); //data[11], data[12]

      // when
      data[11]['name'] = "Jozef";
      
      filteredData.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems, unorderedEquals([data[11]]));
        expect(filteredData, unorderedEquals([data[12]]));
      }));
    });

    test('changing a data object in the underlying collection - gets changed in the filtered collection', () {
      // given
      var collection = new DataCollection.from(data);
      var filteredData = collection.where((d)=>d['name']=='jozef'); //data[11], data[12]
      
      // when
      data[11]['email'] = "jozef@mrkvicka.com";

      filteredData.onChange.listen(expectAsync1((ChangeSet event) {
        //then
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        
        expect(event.changedItems.length, equals(1));
        expect(event.changedItems.keys, unorderedEquals([data[11]]));
        
        expect(filteredData, unorderedEquals([data[11],data[12]]));
      }));
      
    });
    
    test('clearing the underlying collection - gets changed in the filtered collection', () {
      // when
      var collection = new DataCollection.from(data);
      var filteredData = collection.where((d)=>d['name']=='jozef'); //data[11], data[12]

      // when
      collection.clear();
      
      filteredData.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.length, equals(2));
        
        expect(filteredData.isEmpty, isTrue);
      }));
    });
    
    test('complex filter function - elements with even IDs get filtered.', () {
      // given
      var collection = new DataCollection.from(data);
      
      // when
      var filteredData = collection.where((d)=>d['id']%2==0);
      
      // then      
      expect(filteredData.length, equals(7)); //0,2,4,6,8,10,12
    });
  });
}

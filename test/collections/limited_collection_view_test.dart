// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library LimitedCollectionViewTest;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(LimitedCollectionView)', () {
    
    var data;
    DataCollection col1, col2, col3;
    Data data100, data101;
    
    setUp(() {
      
      // initialize data objects
      data = [];           
      data100 = new Data.fromMap({'id':100});
      
      for(var i=0;i<=10;i++) {
        var dataMap = {'id': i, 'parity':i%2};
        data.add(new Data.fromMap(dataMap));      
      };
      
      // initialize test collections       
      col1 = new DataCollection.from(data.where((Data d) => d['id'] < 5));
      col2 = new DataCollection.from(data.where((Data d) => d['id'] > 3));
      col3 = new DataCollection.from([data[0], data[2], data[4], data[6], data[8], data[10]]);
    });
 
    test('data is properly limited. (T01)',(){
        //given
        
        //when
        DataCollectionView sortedAsc = col1.sort([['id', 1]]).limit(offset: 2);
        DataCollectionView sortedDesc = col1.sort([['id',-1]]).limit(offset: 3, limit: 1);
        
        //then
        expect(sortedAsc is SortedCollectionView, isTrue);
        expect(sortedAsc, equals([data[2], data[3], data[4]]));
        
        expect(sortedDesc is SortedCollectionView, isTrue);
        expect(sortedDesc, equals([data[1]]));
      });

    test('data is properly limited (double limit clause). (T02)',(){
      //given
      
      //when
      DataCollectionView sorted1 = col1.sort([['parity',1],['id',-1]]).limit(limit: 4).limit(offset: 1);
      DataCollectionView sorted2 = col1.sort([['parity',1],['id',-1]]).limit(offset: 1).limit(offset: 1);
      
      //then
      expect(sorted1, equals([data[2], data[0], data[3]]));
      expect(sorted2, equals([data[0], data[3], data[1]]));
    });

    test('query does not fail because of negative limit. All objects are taken. (T03)',(){
      //given
      
      //when
      DataCollectionView sorted1 = col1.sort([['parity',1]]).limit(limit: -5);
      
      //then
      try{ // prettyPrint() bug in debugger (uses our .map)
        expect(sorted1, unorderedEquals([col1]));
      } catch(e){}
    });
    
            
    test('adding in scope of limit is propagated (T04)',(){
      //given
      DataCollectionView sorted = col1.sort([['id',-1]]).limit(offset: 0, limit: 2);
      
      //when
      col1.add(data[7]);
      col1.add(data[1]);
      
      //then
      sorted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(sorted, equals([data[7], data[4]]));
        expect(event.addedItems, equals([data[7]]));
        expect(event.removedItems, equals([data[3]]));
      }));
    });
    
    test('adding out of scope of limit is not propagated (T05)',(){
      //given
      DataCollectionView sorted = col1.sort([['id',1]]).limit(offset: 0, limit: 2);
      
      //when
      col1.add(data[7]);
      
      //then
      sorted.onChange.listen((c) => expect(true, isFalse));
    });

    test('removing in scope of limit is propagated (T06)',(){
      //given
      DataCollectionView sorted = col1.sort([['id',1]]).limit(offset: 0, limit: 2);
      
      //when
      col1.remove(data[1]);
      
      //then
      sorted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(sorted, equals([data[0], data[2]]));
        expect(event.addedItems, equals([data[2]]));
        expect(event.removedItems, equals([data[1]]));
        expect(event.changedItems.isEmpty, isTrue);
      }));
    });
    
    test('removing out of scope of limit is not propagated (T07)',(){
      //given
      DataCollectionView sorted = col1.sort([['id',1]]).limit(offset: 0, limit: 10);
      
      //when
      col1.remove(data[7]);
      
      //then
      sorted.onChange.listen((c) => expect(true, isFalse));
    });
    
    test('changing an item in scope of limit is propagated (T08)',(){
      //given
      DataCollectionView sorted = col1.sort([['id',1]]).limit(offset: 0, limit: 2);
      
      //when
      data[0]['dummy'] = 'foo';
      
      //then
      sorted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(sorted, equals([data[0], data[1]]));
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.keys, equals([data[0]]));
      }));
    });
    
    test('changing an item out of scope of limit is propagated (T09)',(){
      //given
      DataCollectionView sorted = col1.sort([['id',1]]).limit(offset: 0, limit: 2);
      
      //when
      data[4]['dummy'] = 'foo';
      
      //then
      sorted.onChange.listen((c) => expect(true, isFalse));
    });
  });
}

// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library SortedCollectionViewTest;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(SortedCollectionView)', () {
    
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
 
    test('data is properly sorted (ordered by one prop). (T01)',(){
        //given
        
        //when
        DataCollectionView sortedAsc = col1.sort([['id', 1]]);
        DataCollectionView sortedDesc = col1.sort([['id',-1]]);
        
        //then
        expect(sortedAsc is SortedCollectionView, isTrue);
        expect(sortedAsc, equals([data[0],data[1], data[2], data[3], data[4]]));
        
        expect(sortedDesc is SortedCollectionView, isTrue);
        expect(sortedDesc, equals([data[4],data[3], data[2], data[1], data[0]]));
      });

    test('data is properly sorted (ordered by more props). (T02)',(){
      //given
      
      //when
      DataCollectionView sorted1 = col1.sort([['parity',1],['id',-1]]);
      DataCollectionView sorted2 = col1.sort([['parity',-1],['id',1]]);
      
      //then
      expect(sorted1, equals([data[4],data[2], data[0], data[3], data[1]]));
      expect(sorted2, equals([data[1], data[3], data[0],data[2], data[4]]));
    });

    test('data is sorted (null semantics). (T03)',(){
      //given
      data[3]['id'] = null;
      
      //when
      DataCollectionView sorted1 = col1.sort([['id',1]]);
      DataCollectionView sorted2 = col1.sort([['id',-1]]);
      
      //then
      expect(sorted1, equals([data[3], data[0], data[1], data[2], data[4]]));
      expect(sorted2, equals([data[4], data[2], data[1], data[0], data[3]]));
    });

    test('data is sorted (undefined semantics). (T04)',(){
      //given
      data[3].remove('id');
      
      //when
      DataCollectionView sorted1 = col1.sort([['id',1]]);
      DataCollectionView sorted2 = col1.sort([['id',-1]]);
      
      //then
      expect(sorted1, equals([data[3], data[0], data[1], data[2], data[4]]));
      expect(sorted2, equals([data[4], data[2], data[1], data[0], data[3]]));
    });
            
    test('adding is propagated (T05)',(){
      //given
      DataCollectionView sorted = col1.sort([['parity', 1],['id',1]]);
      
      //when
      col1.add(data[7]);
      col1.add(data[1]);
      
      //then
      sorted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(sorted, equals([data[0],data[2], data[4], data[1], data[3], data[7]]));
        expect(event.addedItems, equals([data[7]]));
      }));
    });

    test('removal is propagated (T06)',(){
      //given
      DataCollectionView sorted = col1.sort([['parity', 1],['id',1]]);
      
      //when
      col1.remove(data[7]);
      col1.remove(data[1]);
      
      //then
      sorted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(sorted, equals([data[0],data[2], data[4], data[3]]));
        expect(event.removedItems, equals([data[1]]));
      }));
    });
    

    test('change is propagated (T07)',(){
      //given
      DataCollectionView sorted = col1.sort([['parity', 1],['id',1]]);
      
      //when
      data[1]['parity'] = 0;
      
      //then
      sorted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(sorted, equals([data[0], data[1], data[2], data[4], data[3]]));
        expect(event.changedItems.keys, equals([data[1]]));
      }));
    });
    

    test('clearing the source collection is propagated (T08)',(){
      //given
      DataCollectionView sorted = col1.sort([['parity', 1],['id',1]]);
      
      //when
      col1.clear();
      
      //then
      sorted.onChange.listen(expectAsync1((ChangeSet event) {
        expect(sorted, equals([]));
        expect(event.removedItems, unorderedEquals([data[0],data[1],data[2],data[3],data[4]]));
      }));
    });
    
  });
}

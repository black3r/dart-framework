// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library IntersectedCollectionViewTest;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

void main() {

  group('(IntersectedDataCollection)', () {
    
    var data;
    DataCollection col1, col2, col3;
    Data data100, data101;
    
    setUp(() {
      
      // initialize data objects
      data = [];           
      data100 = new Data.fromMap({'id':100});
      data101 = new Data.fromMap({'id':101});
      
      for(var i=0;i<=10;i++) {
        var dataMap = {'id': i};
        data.add(new Data.fromMap(dataMap));      
      };

      // initialize test collections       
      col1 = new DataCollection.from(data.where((Data d) => d['id'] < 5));
      col2 = new DataCollection.from(data.where((Data d) => d['id'] > 3));
      col3 = new DataCollection.from([data100]);
    });
   
    test('data is properly intersected (single intersection). (T01)',(){
        //given
        
        //when        
        DataCollectionView intersected = col1.intersection(col2);
        
        //then
        expect(intersected is IntersectedCollectionView, isTrue);
        expect(intersected, equals([data[4]]));
      });
      
      test('data is properly intersected (double intersection). (T02)',(){
        //given
        
        //when        
        DataCollectionView intersected = col1.intersection(col2)
                                             .intersection(col3);
        
        //then
        expect(intersected.isEmpty, isTrue);
      });
    
      test('intersected collection reacts to source object changes with a change event. (T03)',(){
        //given
        DataCollectionView intersected = col1.intersection(col2);
        
        //when        
        data[4]['name'] = 'John Doe';
        
        //then
        intersected.onChange.listen(expectAsync1((ChangeSet event) {
          
          // a. only a change event is broadcasted
          expect(event.addedItems.isEmpty, isTrue);
          expect(event.removedItems.isEmpty, isTrue);
          expect(event.changedItems.keys, equals([data[4]]));
          
          // b. change event on the data object reports addition of 'name' property
          ChangeSet changeSet = event.changedItems[data[4]];
          expect(changeSet.addedItems, equals(['name']));
          expect(changeSet.removedItems.isEmpty, isTrue);
          expect(changeSet.changedItems.isEmpty, isTrue);
        }));
      });
      test('intersected collection reacts to adding a new object to the source collections. (T04)',(){
          
          //given
          DataCollectionView intersected = col1.intersection(col2);
          //when        
          col1.add(data[5]);
          
          //then
          intersected.onChange.listen(expectAsync1((ChangeSet event) {
            
            // a. only an add event is broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.addedItems, equals([data[5]]));
            
          }));           
        });

    
       test('intersected collection reacts to removing an object from the source collections. (T05)',(){
          // given
          DataCollectionView intersected = col1.intersection(col2);
          
          // when                  
          col1.remove(data[4]);          
          
          // then
          intersected.onChange.listen(expectAsync1((ChangeSet event) {
            
            // a. data[4] was removed from one of the collections and thus is removed from [intersected] as well.            
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems, equals([data[4]]));
          }));
          
        });
        
        test('intersected collection does not react to removing an object that is present in only one of the collections. (T06)',(){
          // given
          DataCollectionView intersected = col1.intersection(col2);
          
          // when
          col1.remove(data[6]);          

          // then
          intersected.onChange.listen((c) => 
              expect(true, isFalse));
        });
        
        test('intersected collection does not react to adding an object to only one source. (T07)',(){
          // given
          DataCollectionView intersected = col1.intersection(col2);
          
          // when
          col1.add(data101);

          // then
          intersected.onChange.listen((c) =>
              expect(true, isFalse));
        });
        
        test('intersected collection does not react to adding an already present object. (T08)',(){
          // given
          DataCollectionView intersection = col1.intersection(col2);
          
          // when
          col1.add(data[4]);

          // then
          intersection.onChange.listen((c) => expect(true, isFalse));
        });
        
        test('removing A from both source collections and adding it back in the same event loop does not broadcast a change. (T10)',(){
          // given
          DataCollectionView intersection = col1.intersection(col2);
          
          // when
          col1.remove(data[4]);
          col2.remove(data[4]);
          
          col1.add(data[4]);
          col2.add(data[4]);

          // then
          intersection.onChange.listen((c) => expect(true, isFalse));
        });

        test('Removing A from src1, adding it to src2 does not broadcast a change. (T11)',(){
          // given
          DataCollectionView intersection = col1.intersection(col2);
          
          // when
          col1.remove(data[0]);
          col2.add(data[0]);

          // then
          intersection.onChange.listen((c) 
              => expect(true, isFalse));
        });

        test('item that is removed, changed and added again is broadcasted as changed.(T12)',(){
          // given
          DataCollectionView intersection = col1.intersection(col2);
          
          // when
          col1.remove(data[4]);
          data[4]['abc'] = 'def';
          col1.add(data[4]);

          // then
          intersection.onChange.listen(expectAsync1((ChangeSet event) {
            
            // a. only a remove event on data[0] was broadcasted
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.changedItems.keys, unorderedEquals([data[4]]));
          }));  
        });

        test('clearing one of the sources results in an open [intersected] collection. (T13)',(){
          // given
          DataCollectionView intersected = col2.intersection(col1);
          
          // when
          col1.clear();

          // then
          intersected.onChange.listen(expectAsync1((ChangeSet event) {
            
            // a. only a change event on data[4] was broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems, unorderedEquals([data[4]]));
            
            // b. the contents of [intersected] are empty
            expect(intersected.isEmpty, isTrue);
          }));  
        });
  });
}

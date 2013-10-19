// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  // Transformation that capitalizes the surname property
  DataTransformFunction mapToUpper = ((DataView d){
      if (!d.containsKey('surname')) return d; 
      DataView d2 = new Data.fromMap(d.toMap());
      d2['surname'] = d['surname'].toString().toUpperCase();
      return d2;
  });
    
    // Transformation that creates a new property 'full-name' by joining name and surname
    DataTransformFunction mapAppend = ((DataView d) {
      Data mappedObj = new Data.fromMap(d.toMap());
      var name = d.containsKey('name') ? d['name'] : '';
      var surname = d.containsKey('surname') ? d['surname'] : '';
      
      mappedObj['full-name'] = "$name $surname";
      return mappedObj;
    });

    
  group('MappedDataView', () {
    
    var data;
    
    setUp(() {
      data = [];           
      var mrkvicka = {'id': 11, 'name': 'jozef', 'surname': 'Mrkvicka'};
      var redkovka = {'id': 12, 'name': 'Jozef', 'surname': 'redkovka'};
      
      data.add(new Data.fromMap(mrkvicka));
      data.add(new Data.fromMap(redkovka));
    });
    
    group('elementary functionality:', () {
      
      test('data object is mapped.', () {
        // when
        MappedDataView mDataObj = new MappedDataView(data[0], mapToUpper);
              
        //then
        expect(mDataObj['surname'], equals('MRKVICKA'));
      });
    });
    
    group('synchronization CRUD:', () {
      test('mapped object changes once the source object has changed.', () {
        // given
        MappedDataView mDataObj = new MappedDataView(data[0], mapToUpper);
        
        // when
        data[0]['surname'] = "Kapusticka";
  
        mDataObj.onChange.listen(expectAsync1((ChangeSet event) {
          // then
          expect(mDataObj['surname'], equals('KAPUSTICKA'));
        }));
      });
  
      test('double mapped object still propagates changes.', () {
        // given      
        MappedDataView mDataObj = new MappedDataView(new MappedDataView(data[0], mapToUpper), mapAppend);
        
        // when     
        data[0]['name'] = "Ingrid";
        
        mDataObj.onChange.listen(expectAsync1((ChangeSet event) {
          // then
          expect(mDataObj['full-name'], equals('Ingrid MRKVICKA'));
        })); 
      });
  
      test('a property is added to the underlying object. Mapped object is recalculated.', () {
        //given
        data[0].remove('name');
        MappedDataView mDataObj = new MappedDataView(new MappedDataView(data[0], mapToUpper), mapAppend);      
        expect(mDataObj['full-name'], equals(" MRKVICKA"));
        
        //when
        data[0]['name'] = 'Ingrid';
        
        mDataObj.onChange.listen(expectAsync1((ChangeSet event) {
          // then
          expect(mDataObj['full-name'], equals('Ingrid MRKVICKA'));
        }));
        
      });
    });
  });
  
   group('MappedDataCollection', () {
      
      var dataNames, dataNums;
      DataCollection collectionNames, collectionNumbers; 
      
      setUp(() {
        // make names collection
        dataNames = [];      
        
        var mrkvicka = {'id': 11, 'name': 'jozef', 'surname': 'mrkvicka'};
        var redkovka = {'id': 12, 'name': 'jozef', 'surname': 'redkovka'};
        
        dataNames.add(new Data.fromMap(mrkvicka));
        dataNames.add(new Data.fromMap(redkovka));
        collectionNames = new DataCollection.from(dataNames);
        
        // make numbers collection
        dataNums = [];
        new Iterable.generate(10, (i)=>{'id':i})
                    .forEach((d)=>dataNums.add(new Data.fromMap(d)));
        collectionNumbers = new DataCollection.from(dataNums);
      });
    
      group('elementary functionality:',(){
        test('data is properly mapped (single mapping).',(){
          //given
          
          //when        
          DataCollectionView mapped = collectionNames.map((d)=>mapToUpper(d));
          
          //then
          var surnames = mapped.toList().map((d)=>d['surname']);
          expect(mapped is DataCollectionView, isTrue);
          expect(surnames.length, equals(2));
          expect(surnames, unorderedEquals(['REDKOVKA', 'MRKVICKA']));
        });
  
        test('data is properly mapped (double mapping).',(){
          //given
          //when        
          DataCollectionView mapped = collectionNames.map((d)=>mapToUpper(d))
                                                     .map((d)=>mapAppend(d));
          
          //then
          expect(mapped is DataCollectionView, isTrue);
  
          var fullNames = mapped.toList().map((d)=>d['full-name']);
          expect(fullNames.length, equals(2));
          expect(fullNames, unorderedEquals(['jozef REDKOVKA', 'jozef MRKVICKA']));
        });
  
        
        test('collision does not flatten the collection',(){
          //given
          
          //when        
          DataCollectionView mapped = collectionNumbers.map((d)=>new Data.fromMap({"id":d['id']%2}));                                                     
          
          //then
          expect(mapped.length, equals(10));
        });
      });
      
      group('synchronization CRUD:',(){
        test('when a value is added to the underlying collection, it is mapped.',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapAppend(d));                                                     
          Data ernest = new Data.fromMap({'id':17, 'name':'ernest', 'surname':'hemingway'});
          
          //when
          collectionNames.add(ernest);        
          
          mapped.onChange.listen(expectAsync1((ChangeSet event) {
            // then
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['jozef mrkvicka', 'jozef redkovka', 'ernest hemingway']));
          }));
        });
  
        
        test('when a value is removed from the underlying collection, it\'s removed from the mapped collection as well.',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapAppend(d));                                                     
          
          //when
          collectionNames.remove(dataNames[0]);        
          
          mapped.onChange.listen(expectAsync1((ChangeSet event) {
            // then
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['jozef redkovka']));
          }));
        });
  
        test('when a value is changed in the underlying collection, it\'s changed in the mapped collection as well.',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapAppend(d));                                                     
          
          //when
          collectionNames.remove(dataNames[1]);
          dataNames[0]['name'] = 'karol';         
          
          mapped.onChange.listen(expectAsync1((ChangeSet event) {
            // then
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['karol mrkvicka']));
          }));
        });
        
        
        test('when a value is changed/removed in the underlying collection, it\'s changed/removed in the mapped collection as well (double-mapping version).',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapToUpper(d))
                                                      .map((d)=>mapAppend(d));                                                     
          
          //when
          collectionNames.remove(dataNames[1]);
          dataNames[0]['name'] = 'karol';
          
          mapped.onChange.listen(expectAsync1((ChangeSet event) {
            // then
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['karol MRKVICKA']));
          }));
        });
        
        test('when item in mapped collection is removed, changed and added, it is in changedItems.',(){
          // given
          var filtered = new FilteredDataCollection(collectionNames, (d) => mapToUpper(d));
          
          // when
          collectionNames.remove(dataNames[0]);
          dataNames[0]['id'] = 5;
          collectionNames.add(dataNames[0]);
          
          // then
          filtered.onChange.listen(expectAsync1((ChangeSet event) {
            expect(event.changedItems.keys, unorderedEquals([dataNames[0]]));
          }));
        });
        
        
        test('after removing an object from the mapped collection, it does not react to changes on this object anymore.', () {
          // given
          var mappedData = collectionNames.map((d)=>mapToUpper(d));
          collectionNames.remove(dataNames[1]);
          
          // when
          dataNames[1]['name'] = 'Bob';  
          
          mappedData.onChange.listen(expectAsync1((ChangeSet event) {
            // then
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems.length, equals(1));  
            expect(mappedData.length, equals(1));
          }));
        });
      });
   });
}

// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mapped_collection_view_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  // Transformation that capitalizes the surname property
  DataTransformFunction mapToUpper = ((DataView d){
      if (!d.containsKey('surname')) return d;
      Data d2 = new Data.fromMap(d.toMap());
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

  group('(MappedDataView)', () {

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

   group('(MappedDataCollection)', () {

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

          // a. the result is of the correct type
          expect(mapped is DataCollectionView, isTrue);

          // b. mapping to full-name is correct
          var fullNames = mapped.toList().map((d)=>d['full-name']);
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

          // then
          mapped.onChange.listen(expectAsync1((ChangeSet event) {

            // a. mapping to full-name is correct
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['jozef mrkvicka', 'jozef redkovka', 'ernest hemingway']));
          }));
        });


        test('when a value is removed from the underlying collection, it\'s removed from the mapped collection as well.',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapAppend(d));

          //when
          collectionNames.remove(dataNames[0]);

          // then
          mapped.onChange.listen(expectAsync1((ChangeSet event) {

            // a. mapping to full-name is correct
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['jozef redkovka']));
          }));
        });

        test('when a value is changed in the underlying collection, it\'s changed in the mapped collection as well.',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapAppend(d));

          //when
          dataNames[0]['name'] = 'karol';

          // then
          mapped.onChange.listen(expectAsync1((ChangeSet event) {

            // a. mapping to full-name is correct
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['karol mrkvicka','jozef redkovka']));
          }));
        });

        test('when a value is changed in the underlying collection twice, the changes are merged into one.',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapAppend(d));

          //when
          dataNames[0]['name'] = 'karol';
          dataNames[0]['name'] = 'tibor';

          // then
          mapped.onChange.listen(expectAsync1((ChangeSet event) {

            // a. mapping to full-name is correct
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['tibor mrkvicka','jozef redkovka']));

            // b. no addition/removal are logged, only 1 change
            expect(event.addedItems, unorderedEquals([]));
            expect(event.removedItems, unorderedEquals([]));
            expect(event.changedItems.length, equals(1));

            // c. the changed item's changeset contains only change events for name and full-name attributes.
            DataView d = event.changedItems.keys.first;
            ChangeSet objChangeSet = event.changedItems.values.first;
            expect(objChangeSet.addedItems.isEmpty, isTrue);
            expect(objChangeSet.removedItems.isEmpty, isTrue);
            expect(objChangeSet.changedItems.keys, unorderedEquals(['full-name', 'name']));

            // d. these changes go from jozef -> tibor / jozef mrkvicka -> tibor mrkvicka
            Change nChange = objChangeSet.changedItems['name'];
            expect(nChange.oldValue, equals('jozef'));
            expect(nChange.newValue, equals('tibor'));

            Change fnChange = objChangeSet.changedItems['full-name'];
            expect(fnChange.oldValue, equals('jozef mrkvicka'));
            expect(fnChange.newValue, equals('tibor mrkvicka'));
          }));
        });


        test('when a value is changed/removed in the underlying collection, it\'s changed/removed in the mapped collection as well (double-mapping version).',(){
          //given
          DataCollectionView mapped = collectionNames.map((d)=>mapToUpper(d))
                                                     .map((d)=>mapAppend(d));

          //when
          dataNames[0]['name'] = 'karol';

          // then
          mapped.onChange.listen(expectAsync1((ChangeSet event) {

            // a. name is changed to karol MRKVICKA in the mapped collection.
            var fullNames = mapped.toList().map((d)=>d['full-name']);
            expect(fullNames, unorderedEquals(['karol MRKVICKA','jozef REDKOVKA']));
          }));
        });

        test('after removing an object from the mapped collection, changing and adding it, a correct change is broadcasted.',(){
          // given
          var mapped = collectionNames.map((d) => mapToUpper(d));

          // when
          collectionNames.remove(dataNames[0]);
          dataNames[0]['id'] = 5;
          collectionNames.add(dataNames[0]);

          // then
          mapped.onChange.listen(expectAsync1((ChangeSet event) {

            // a. no addition/removal is broadcasted
            expect(event.addedItems, unorderedEquals([]));
            expect(event.removedItems, unorderedEquals([]));

            // b. the changed array contains only the one right data object
            expect(event.changedItems.keys.length, 1);
            expect(event.changedItems.keys.first['id'], equals(5));

            // c. the changed data object has changed only their id.
            ChangeSet changeSet = event.changedItems.values.first;
            expect(changeSet.changedItems.keys, unorderedEquals(['id']));
            expect(changeSet.addedItems.isEmpty, isTrue);
            expect(changeSet.removedItems.isEmpty, isTrue);

            // d. the change of the id is from 11 -> 5.
            Change change = changeSet.changedItems['id'];
            expect(change.oldValue, equals(11));
            expect(change.newValue, equals(5));
          }));
        });


        test('after removing an object from the mapped collection, it does not react to changes on this object anymore.', () {
          // given
          var mappedData = collectionNames.map((d)=>mapToUpper(d));
          collectionNames.remove(dataNames[1]);

          // when
          dataNames[1]['name'] = 'Bob';

          // then
          mappedData.onChange.listen(expectAsync1((ChangeSet event) {
            // a. nothing was changed/added
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);

            // b. only removed item is Bob
            expect(event.removedItems.length, equals(1));
            expect(event.removedItems.first['name'], equals('Bob'));

            // c. removed item indeed does not exist in the collection
            expect(mappedData.length, equals(1));
          }));

        });

        // todo: check whether this is really the correct way to do this test.
        test('if remove and change happen in one event loop, change event won\'t be broadcasted later (a.k.a subscription was cancelled).', () {
          // given
          var mappedData = collectionNames.map((d)=>mapToUpper(d));

          // when
          dataNames[1]['name'] = 'Bob';
          collectionNames.remove(dataNames[1]);
          var wasRemovedEvent = false;

          // then
          mappedData.onChange.listen(expectAsyncUntil1((ChangeSet event) {

            // a. nothing was changed/added
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isFalse);

            // this means that there must be no more callbacks in order to pass the test
            wasRemovedEvent = true;
          },() => wasRemovedEvent));
        });
      });
   });
}

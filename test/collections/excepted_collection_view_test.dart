// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ExceptedCollectionViewTest;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(ExceptedDataCollection)', () {

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
      col3 = new DataCollection.from([data[0], data[2], data[4], data[6], data[8], data[10]]);
    });

    test('data is properly intersected (non-empty single minus). (T01)',(){
        //given

        //when
        DataCollectionView excepted = col1.except(col2);
        DataCollectionView excepted2 = col2.except(col1);

        //then
        expect(excepted is ExceptedCollectionView, isTrue);
        expect(excepted, unorderedEquals([data[0],data[1], data[2], data[3]]));

        expect(excepted2 is ExceptedCollectionView, isTrue);
        expect(excepted2, unorderedEquals([data[5],data[6], data[7], data[8], data[9], data[10]]));
      });

    test('data is properly intersected (empty single minus). (T02)',(){
      //given

      //when
      DataCollectionView excepted = col1.except(col1);

      //then
      expect(excepted is ExceptedCollectionView, isTrue);
      expect(excepted.isEmpty, isTrue);
    });


    test('data is properly excepted (double minus). (T03)',(){
        //given

        //when
        DataCollectionView excepted = col1.except(col2)
                                         .except(col3);

        //then
        expect(excepted, unorderedEquals([data[1], data[3]]));
    });

    test('excepted collection reacts to source object changes with a change event. (T04)',(){
        //given
        DataCollectionView excepted = col1.except(col2);

        //when
        data[2]['name'] = 'John Doe';

        //then
        excepted.onChange.listen(expectAsync1((ChangeSet event) {

          // a. only a change event is broadcasted
          expect(event.addedItems.isEmpty, isTrue);
          expect(event.removedItems.isEmpty, isTrue);
          expect(event.changedItems.keys, equals([data[2]]));

          // b. change event on the data object reports addition of 'name' property
          ChangeSet changeSet = event.changedItems[data[2]];
          expect(changeSet.addedItems, equals(['name']));
          expect(changeSet.removedItems.isEmpty, isTrue);
          expect(changeSet.changedItems.keys, equals(['name']));
          expect(changeSet.changedItems['name'].oldValue, isNull);
          expect(changeSet.changedItems['name'].newValue, equals('John Doe'));
        }));
      });

      test('excepted collection reacts to adding a new object to the first source collection. (T05)',(){

          //given
          DataCollectionView excepted = col1.except(col2);
          //when
          col1.add(data100);

          //then
          excepted.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only an add event is broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.addedItems, equals([data100]));

          }));
        });

      test('excepted collection reacts to adding a new object to the second source collection. (T06)',(){

        //given
        DataCollectionView excepted = col1.except(col2);
        //when
        col2.add(data[3]);

        //then
        excepted.onChange.listen(expectAsync1((ChangeSet event) {

          // a. only an add event is broadcasted
          expect(event.changedItems.isEmpty, isTrue);
          expect(event.addedItems.isEmpty, isTrue);
          expect(event.removedItems, equals([data[3]]));

        }));
      });

       test('excepted collection reacts to removing an object from the first source collection. (T07)',(){
          // given
          DataCollectionView excepted = col1.except(col2);

          // when
          col1.remove(data[1]);
          col1.remove(data[4]);

          // then
          excepted.onChange.listen(expectAsync1((ChangeSet event) {

            // a. data[4] was removed from one of the collections and thus is removed from [intersected] as well.
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems, equals([data[1]]));
          }));

        });

       test('excepted collection reacts to removing an object from the second source collection. (T08)',(){
         // given
         DataCollectionView excepted = col1.except(col2);

         // when
         col2.remove(data[4]);

         // then
         excepted.onChange.listen(expectAsync1((ChangeSet event) {

           // a. data[4] was removed from one of the collections and thus is removed from [intersected] as well.
           expect(event.changedItems.isEmpty, isTrue);
           expect(event.removedItems.isEmpty, isTrue);
           expect(event.addedItems, equals([data[4]]));
           expect(excepted, unorderedEquals([data[0], data[1], data[2], data[3], data[4]]));
         }));

       });

       test('intersected collection does not react to adding an object to second collection that is not in the first collection. (T09)',(){
         // given
         DataCollectionView excepted = col1.except(col2);

         // when
         col2.add(data100);

         // then
         excepted.onChange.listen((c) => expect(true, isFalse));
       });

       test('adding and removing an object to the second collection does not raise an event. (T10)',(){
          // given
          DataCollectionView excepted = col1.except(col2);

          // when
          col2.add(data[1]);
          col2.remove(data[1]);

          // then
          excepted.onChange.listen((c) =>
              expect(true, isFalse));
        });

       test('adding and removing an object to the first collection does not raise an event. (T11)',(){
         // given
         DataCollectionView excepted = col1.except(col2);

         // when
         col1.add(data100);
         col1.remove(data100);

         // then
         excepted.onChange.listen((c) =>
             expect(true, isFalse));
       });

        test('item that is removed, changed and added again is broadcasted as changed - first collection. (T12)',(){
          // given
          DataCollectionView excepted = col1.except(col2);

          // when
          col1.remove(data[2]);
          data[2]['abc'] = 'def';
          col1.add(data[2]);

          // then
          excepted.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only a remove event on data[0] was broadcasted
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.changedItems.keys, unorderedEquals([data[2]]));
          }));
        });


        test('item that is removed, changed and added again is broadcasted as changed - second collection. (T13)',(){
          // given
          DataCollectionView excepted = col1.except(col2);

          // when
          col1.remove(data[2]);
          data[2]['abc'] = 'def';
          col1.add(data[2]);

          // then
          excepted.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only a remove event on data[0] was broadcasted
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.changedItems.keys, unorderedEquals([data[2]]));
          }));
        });

        test('changes on objects not in the collection are not broadcasted. (T14)',(){
          // given
          DataCollectionView excepted = col1.except(col2);

          // when
          data[5]['abc'] = 'def';

          // then
          excepted.onChange.listen((c) =>
              expect(true, isFalse));
        });


        test('clearing first source collection results in an empty collection. (T15)',(){
          // given
          DataCollectionView excepted = col1.except(col2);

          // when
          col1.clear();

          // then
          excepted.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only a change event on data[4] was broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems, unorderedEquals([data[0], data[1], data[2], data[3]]));

            // b. the contents of [intersected] are empty
            expect(excepted.isEmpty, isTrue);
          }));
        });

        test('clearing second source collection results in a collection equal to first collection. (T16)',(){
          // given
          DataCollectionView excepted = col1.except(col2);

          // when
          col2.clear();

          // then
          excepted.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only a change event on data[4] was broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.addedItems, equals([data[4]]));

            // b. the contents of [intersected] are empty
            expect(excepted, equals(col1));
          }));
        });
  });
}

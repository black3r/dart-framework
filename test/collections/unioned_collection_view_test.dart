// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unioned_collection_view_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

void main() {

  group('(UnionedDataCollection)', () {

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

    test('data is properly unioned (single union). (T01)',(){
        //given

        //when
        DataCollectionView unioned = col1.union(col2);

        //then
        expect(unioned is UnionedCollectionView, isTrue);
        expect(unioned, unorderedEquals(data));
      });

      test('data is properly unioned (double union). (T02)',(){
        //given
        data.add(data100);

        //when
        DataCollectionView unioned = col1.union(col2)
                                         .union(col3);

        //then
        expect(unioned is UnionedCollectionView, isTrue);
        expect(unioned, unorderedEquals(data));
      });


      test('unioned collection reacts to source object changes with a change event. (T03)',(){
        //given
        DataCollectionView unioned1 = col1.union(col2);

        //when
        data[4]['name'] = 'John Doe';

        //then
        unioned1.onChange.listen(expectAsync1((ChangeSet event) {

          // a. only a change event is broadcasted
          expect(event.addedItems.isEmpty, isTrue);
          expect(event.removedItems.isEmpty, isTrue);
          expect(event.changedItems.keys, equals([data[4]]));

          // b. change event on the data object reports addition of 'name' property
          ChangeSet changeSet = event.changedItems[data[4]];
          expect(changeSet.addedItems, equals(['name']));
          expect(changeSet.removedItems.isEmpty, isTrue);
          expect(changeSet.changedItems.keys, equals(['name']));
        }));
      });

      test('unioned collection reacts to adding a new object to the source collections. (T04)',(){

          //given
          DataCollectionView unioned2 = col1.union(col2);
          //when
          col1.add(data100);
          col2.add(data101);

          //then
          unioned2.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only an add event is broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.addedItems, unorderedEquals([data100, data101]));

          }));
        });

        test('unioned collection reacts to removing an object from the source collections (1 source). (T05)',(){
          // given
          DataCollectionView unioned3 = col1.union(col2);

          // when
          col1.remove(data[5]);

          // then

          // a. no change is broadcasted as data[4] was in both collections and did not get removed.
          unioned3.onChange.listen((e) => expect(true, isFalse));
        });

        test('unioned collection reacts to removing an object from the source collections (2 sources). (T06)',(){
          // given
          DataCollectionView unioned4 = col1.union(col2);

          // when
          col1.remove(data[4]);
          col2.remove(data[4]);

          // then
          unioned4.onChange.listen(expectAsync1((ChangeSet event) {

            // a. data[4] was removed from both collections and thus is removed from [unioned] as well.
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems, equals([data[4]]));
          }));
        });

        test('unioned collection does not react to removing an object from only one source. (T07)',(){
          // given
          DataCollectionView unioned5 = col1.union(col2);

          // when
          col1.remove(data[4]);

          // then
          unioned5.onChange.listen((c) => expect(true, isFalse));
        });

        test('unioned collection does not react to adding an already present object to the source it was not in. (T08)',(){
          // given
          DataCollectionView unioned = col1.union(col2);

          // when
          col1.add(data[8]);

          // then
          unioned.onChange.listen((c) => expect(true, isFalse));
        });

        test('unioned collection does react to adding a new object to one of the sources. (T09)',(){
          // given
          DataCollectionView unioned = col1.union(col2);

          // when
          col1.add(data100);

          // then
          unioned.onChange.listen(expectAsync1((ChangeSet event) {

            // a. data[4] was removed from both collections and thus is removed from [unioned] as well.
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems, equals([data100]));
            expect(event.removedItems.isEmpty, isTrue);
          }));
        });

        test('deleting A from src1 and adding it to src2 in the same event loop does not broadcast a change. (T10)',(){
          // given
          DataCollectionView unioned = col1.union(col2);

          // when
          col1.remove(data[0]);
          col2.add(data[0]);

          // then
          unioned.onChange.listen((c) => expect(true, isFalse));
        });

        test('Adding A to both src1 & src2 and deleting it from one of them in the same event loop does broadcast an addition. (T11)',(){
          // given
          DataCollectionView unioned = col1.union(col2);

          // when
          col1.add(data100);
          col2.add(data100);
          col1.remove(data100);

          // then
          unioned.onChange.listen(expectAsync1((ChangeSet event) {

            // a. add event for [data100] is broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.addedItems, equals([data100]));
          }));
        });

        test('removed item does not react to changes (T12)',(){
          // given
          DataCollectionView unioned = col1.union(col2);

          // when
          col1.remove(data[0]);
          data[0]['abc'] = 'def';

          // then
          unioned.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only a remove event on data[0] was broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems, equals([data[0]]));
          }));
        });

        test('change event is propagated to the unioned collection. (T13)',(){
          // given
          DataCollectionView unioned = col1.union(col2);

          // when
          data[0]['abc'] = 'def';

          // then
          unioned.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only a change event on data[0] was broadcasted
            expect(event.removedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.changedItems.keys, equals([data[0]]));

            // b. the change event on data[0] is correct
            ChangeSet changeSet = event.changedItems[data[0]];
            expect(changeSet.removedItems.isEmpty, isTrue);
            expect(changeSet.changedItems.keys, equals(['abc']));
            expect(changeSet.addedItems, equals(['abc']));

            expect(changeSet.changedItems['abc'].oldValue, isNull);
            expect(changeSet.changedItems['abc'].newValue, equals('def'));
          }));
        });

        test('clearing one of the sources propagates correctly. (T14)',(){
          // given
          DataCollectionView unioned = col2.union(col1);

          // when
          col1.clear();

          // then
          unioned.onChange.listen(expectAsync1((ChangeSet event) {

            // a. only a change event on data[0] was broadcasted
            expect(event.changedItems.isEmpty, isTrue);
            expect(event.addedItems.isEmpty, isTrue);
            expect(event.removedItems, unorderedEquals([data[0], data[1], data[2], data[3]]));

            // b. the contents of [unioned] are correct
            expect(unioned, unorderedEquals(col2));
          }));
        });
  });
}

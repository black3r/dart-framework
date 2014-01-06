// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library change_set_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('(Change)', () {

    test('initialize.', () {

      // when
      var change = new Change("old", "new");

      // then
      expect(change.oldValue, equals("old"));
      expect(change.newValue, equals("new"));
    });

    test('apply another change object.', () {
      // given
      var firstChange = new Change("old", "new");
      var secondChange = new Change("new", "newer");

      // when
      firstChange.mergeIn(secondChange);

      // then
      expect(firstChange.oldValue, equals("old"));
      expect(firstChange.newValue, equals("newer"));
    });

    test('clone change.', () {
      // given
      var change = new Change('old', 'new');

      // when
      var clone = change.clone();

      // then
      expect(clone.oldValue, equals(change.oldValue));
      expect(clone.newValue, equals(change.newValue));
    });

  });

  group('(ChangeSet)', () {

    ChangeSet changeSet;
    List children;

    setUp((){
      changeSet = new ChangeSet();
      children = ['first', 'second', 'third'];
    });

    test('initialization.', () {
      // when
      var changeSet = new ChangeSet();

      // then
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isTrue);
      expect(changeSet.isEmpty, isTrue);
    });

    test('clone.', () {
      // given
      var change = new Mock();
      change.when(callsTo('clone')).alwaysReturn(change);

      var changeSet = new ChangeSet();
      changeSet.markAdded('january', null);
      changeSet.markRemoved('february', null);
      changeSet.markChanged('march', change);

      // when
      var clone = changeSet.clone();

      // then
      expect(identical(clone, changeSet), isFalse);
      expect(clone.addedItems, equals(changeSet.addedItems));
      expect(clone.removedItems, equals(changeSet.removedItems));
      expect(clone.changedItems, equals(changeSet.changedItems));
    });

    test('add children.', () {
      // when
      for (var child in children) {
        changeSet.markAdded(child, null);
      }

      //  then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isFalse);
      expect(changeSet.addedItems, unorderedEquals(children));
    });

    test('remove children.', () {
      // when
      for (var child in children) {
        changeSet.markRemoved(child, null);
      }

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isFalse);
      expect(changeSet.removedItems, unorderedEquals(children));
    });

    test('add previously removed children.', () {
      // given
      for (var child in children) {
        changeSet.markRemoved(child, child);
      }

      // when
      for (var child in children) {
        changeSet.markAdded(child, child);
      }

      // then
      changeSet.changedItems.forEach((k, Change v){
        expect(v.isEqualityChange, isTrue);
      });
    });

    test('remove previosly added children.', () {
      // given
      for (var child in children) {
        changeSet.markAdded(child, child);
      }

      // when
      for (var child in children) {
        changeSet.markRemoved(child, child);
      }

      // then
      changeSet.changedItems.forEach((k, Change v){
        expect(v.isEqualityChange, isTrue);
      });
    });

    test('change children.', () {
      // given
      var changes =
        {'first': new Mock(), 'second': new Mock(), 'third': new Mock()};
      for (var mock in changes.values) {
        mock.when(callsTo('clone')).alwaysReturn([mock]);
      }

      // when
      for (var child in changes.keys) {
        changeSet.markChanged(child, changes[child]);
      }

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.length, equals(changes.length));
      for (var child in changeSet.changedItems.keys) {
        expect(changeSet.changedItems[child], equals(changes[child].clone()));
      }
    });

    test('change child that was changed before.', () {
      // given
      var change = new Mock();
      var anotherChange = new Mock();
      var changeClone = new Mock();
      change.when(callsTo('clone')).alwaysReturn(changeClone);

      changeSet.markChanged('child', change);

      // when
      changeSet.markChanged('child', anotherChange);

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.removedItems.isEmpty, isTrue);
      changeClone.getLogs(callsTo('mergeIn', anotherChange)).verify(happenedOnce);
      expect(changeSet.changedItems['child'], equals(changeClone));
    });

    test('change child that was added before.',() {

      for (var child in children) {
        changeSet.markAdded(child, child);
      }

      // when
      for (var child in children) {
        changeSet.markChanged(child, new Change(child, child+'_'));
      }

      // then
      expect(changeSet.addedItems, unorderedEquals(children));
      changeSet.changedItems.forEach((key, Change value){
        expect(value, equals(new Change(undefined, '${key}_')));

      });
    });


    test('apply another ChangeSet.', () {
      // given
      var change1 = new Change('v1', 'v2');
      var change2 = new Change('va', 'vb');

      changeSet.markChanged('key1', change1);

      var anotherChangeSet = new ChangeSet();
      anotherChangeSet.markChanged('key2', change2);

      // when
      changeSet.mergeIn(anotherChangeSet);

      // then
      expect(changeSet, equals(new ChangeSet({
        'key1': new Change('v1', 'v2'),
        'key2': new Change('va', 'vb')}
      )));
    });
  });
}

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
      changeSet.markAdded('january');
      changeSet.markRemoved('february');
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
        changeSet.markAdded(child);
      }

      //  then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isTrue);
      expect(changeSet.addedItems, unorderedEquals(children));
    });

    test('remove children.', () {
      // when
      for (var child in children) {
        changeSet.markRemoved(child);
      }

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isTrue);
      expect(changeSet.removedItems, unorderedEquals(children));
    });

    test('add previously removed children.', () {
      // given
      for (var child in children) {
        changeSet.markRemoved(child);
      }

      // when
      for (var child in children) {
        changeSet.markAdded(child);
      }

      // then
      expect(changeSet.isEmpty, isTrue);
    });

    test('remove previosly added children.', () {
      // given
      for (var child in children) {
        changeSet.markAdded(child);
      }

      // when
      for (var child in children) {
        changeSet.markRemoved(child);
      }

      // then
      expect(changeSet.isEmpty, isTrue);
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
      // given
      var change = new Mock();
      var changeClone = new Mock();
      change.when(callsTo('clone')).alwaysReturn(changeClone);

      for (var child in children) {
        changeSet.markAdded(child);
      }

      // when
      for (var child in children) {
        changeSet.markChanged(child, change);
      }

      // then
      expect(changeSet.addedItems, unorderedEquals(children));
      expect(changeSet.removedItems.isEmpty, isTrue);
      for (var child in children) {
        expect(changeSet.changedItems[child], equals(changeClone));
      }
    });


    test('apply another ChangeSet.', () {
      // given
      var change = new Mock();
      change.when(callsTo('clone')).alwaysReturn(change);

      changeSet.markAdded('added');
      changeSet.markRemoved('removed');
      changeSet.markChanged('changed', change);

      var anotherChangeSet = new ChangeSet();
      var anotherChange = new Mock();
      anotherChange.when(callsTo('clone')).alwaysReturn(anotherChange);
      anotherChangeSet.markAdded('anotherAdded');
      anotherChangeSet.markRemoved('anotherRemoved');
      anotherChangeSet.markChanged('anotherChanged', anotherChange);

      // when
      changeSet.mergeIn(anotherChangeSet);

      // then
      expect(changeSet.addedItems, unorderedEquals(['added', 'anotherAdded']));
      expect(changeSet.removedItems, unorderedEquals(['removed', 'anotherRemoved']));
      expect(changeSet.changedItems.length, equals(2));
      expect(changeSet.changedItems['changed'], equals(change));
      expect(changeSet.changedItems['anotherChanged'], equals(anotherChange));
    });
  });
}

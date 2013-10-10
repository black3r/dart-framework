// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('Change', () {

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
      firstChange.apply(secondChange);

      // then
      expect(firstChange.oldValue, equals("old"));
      expect(firstChange.newValue, equals("newer"));
    });

  });

  group('ChangeSet', () {

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
      expect(changeSet.addedChildren.isEmpty, isTrue);
      expect(changeSet.removedChildren.isEmpty, isTrue);
      expect(changeSet.changedChildren.isEmpty, isTrue);
      expect(changeSet.isEmpty, isTrue);
    });

    test('add children.', () {
      // when
      for (var child in children) {
        changeSet.addChild(child);
      }

      //  then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.removedChildren.isEmpty, isTrue);
      expect(changeSet.changedChildren.isEmpty, isTrue);
      expect(changeSet.addedChildren, unorderedEquals(children));
    });

    test('remove children.', () {
      // when
      for (var child in children) {
        changeSet.removeChild(child);
      }

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedChildren.isEmpty, isTrue);
      expect(changeSet.changedChildren.isEmpty, isTrue);
      expect(changeSet.removedChildren, unorderedEquals(children));
    });

    test('add previously removed children.', () {
      // given
      for (var child in children) {
        changeSet.removeChild(child);
      }

      // when
      for (var child in children) {
        changeSet.addChild(child);
      }

      // then
      expect(changeSet.isEmpty, isTrue);
    });

    test('remove previosly added children.', () {
      // given
      for (var child in children) {
        changeSet.addChild(child);
      }

      // when
      for (var child in children) {
        changeSet.removeChild(child);
      }

      // then
      expect(changeSet.isEmpty, isTrue);
    });

    test('change children.', () {
      // given
      var changes =
        {'first': new Mock(), 'second': new Mock(), 'third': new Mock()};

      // when
      for (var child in changes.keys) {
        changeSet.changeChild(child, changes[child]);
      }

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedChildren.isEmpty, isTrue);
      expect(changeSet.removedChildren.isEmpty, isTrue);
      expect(changeSet.changedChildren.length, equals(changes.length));
      for (var child in changeSet.changedChildren.keys) {
        expect(changeSet.changedChildren[child], equals(changes[child]));
      }
    });

    test('change child that was changed before.', () {
      // given
      var firstChange = new Mock();
      var secondChange = new Mock();
      var child = 'child';
      changeSet.changeChild(child, firstChange);

      // when
      changeSet.changeChild(child, secondChange);

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedChildren.isEmpty, isTrue);
      expect(changeSet.removedChildren.isEmpty, isTrue);
      firstChange.getLogs(callsTo('apply', secondChange)).verify(happenedOnce);
      expect(changeSet.changedChildren[child], equals(firstChange));
    });

    test('change child that was added before.',() {
      // given
      for (var child in children) {
        changeSet.addChild(child);
      }
      var someChange = new Mock();

      // when
      for (var child in children) {
        changeSet.changeChild(child, someChange);
      }

      // then
      expect(changeSet.addedChildren, unorderedEquals(children));
      expect(changeSet.removedChildren.isEmpty, isTrue);
      expect(changeSet.changedChildren.isEmpty, isTrue);
    });

    test('apply another ChangeSet.', () {
      // given
      var change = new Mock();
      changeSet.addChild('added');
      changeSet.removeChild('removed');
      changeSet.changeChild('changed', change);

      var anotherChangeSet = new ChangeSet();
      var anotherChange = new Mock();
      anotherChangeSet.addChild('anotherAdded');
      anotherChangeSet.removeChild('anotherRemoved');
      anotherChangeSet.changeChild('anotherChanged', anotherChange);

      // when
      changeSet.apply(anotherChangeSet);

      // then
      expect(changeSet.addedChildren, unorderedEquals(['added', 'anotherAdded']));
      expect(changeSet.removedChildren, unorderedEquals(['removed', 'anotherRemoved']));
      expect(changeSet.changedChildren.length, equals(2));
      expect(changeSet.changedChildren['changed'], equals(change));
      expect(changeSet.changedChildren['anotherChanged'], equals(anotherChange));
    });
  });
}

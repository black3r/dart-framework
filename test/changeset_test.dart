// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';

void main() {
  test_change();
  test_changeSet();
  filterTests('ChangeSet');
}

void test_change() {
  group('Change', () {
    test('Test init.', () {
      var change = new Change.fromValues(1,2);
      expect(change.oldValue,equals(1));
      expect(change.newValue,equals(2));
    });
    test('Test if the changes are properly added',(){
      var change = new Change.fromValues(1,2);
      change.apply(new Change.withNew(3));
      
      expect(change.oldValue,equals(1));
      expect(change.newValue,equals(3));
    });
    test('Test setter and getters.',(){
      var change = new Change();
      change.newValue = 4;
      change.oldValue = 7;
      
      expect(change.newValue,equals(4));
      expect(change.oldValue,equals(7));
    });
  });
}

void test_changeSet() {
  group('ChangeSet', () {
    ChangeSet changeSet;
    setUp((){
      changeSet = new ChangeSet();
    });
    test('Test addding.',(){
      changeSet.addChild(1);
      changeSet.addChild(2);
      changeSet.addChild(1);
      
      expect(changeSet.addedChildren.length,equals(2));
      expect(changeSet.addedChildren.contains(1),isTrue);
      expect(changeSet.addedChildren.contains(2),isTrue);
      expect(changeSet.addedChildren.contains(3),isFalse);
      
      expect(changeSet.removedChildren.isEmpty,isTrue);
      expect(changeSet.changedChildren.isEmpty,isTrue);
    });
    test('Test removing.',(){
      changeSet.removeChild(1);
      changeSet.removeChild(2);
      changeSet.removeChild(1);
      
      expect(changeSet.removedChildren.length,equals(2));
      expect(changeSet.removedChildren.contains(1),isTrue);
      expect(changeSet.removedChildren.contains(2),isTrue);
      expect(changeSet.removedChildren.contains(3),isFalse);
      
      expect(changeSet.addedChildren.isEmpty,isTrue);
      expect(changeSet.changedChildren.isEmpty,isTrue);
    });
    
    test('Test isEmpty',(){
      expect(changeSet.isEmpty,isTrue);
      
      changeSet.addChild(1);
      expect(changeSet.isEmpty,isFalse);
      
      changeSet = new ChangeSet();
      changeSet.removeChild(2);
      expect(changeSet.isEmpty,isFalse);
      
      changeSet = new ChangeSet();
      changeSet.changeChild(2,new Change());
      expect(changeSet.isEmpty,isFalse);
    });

    test('Test adding previosly removed.',(){
      changeSet.removeChild(2);
      changeSet.addChild(2);
      expect(changeSet.isEmpty,isTrue);
    });
    test('Test removing previosly added.',(){
      changeSet.addChild(2);
      changeSet.removeChild(2);
      expect(changeSet.isEmpty,isTrue);
    });
    test('Test changing.',(){
      var change = new Change.fromValues(47, 42);
      changeSet.changeChild(1,change);
      changeSet.changeChild(2,change);
      expect(changeSet.changedChildren[1],equals(change));
      expect(changeSet.changedChildren[2],equals(change));
    });
    test('Test changing previosly changed.',(){
      var change = new Change.fromValues(47, 42);
      changeSet.changeChild(1,change);
      changeSet.changeChild(1,new Change.withNew(19));
      expect(changeSet.changedChildren[1].newValue,equals(19));
    });
    test('Test changing previosly added.',(){
      expect(true,isFalse);
    });
    test('Test clear',(){
      changeSet.addChild(1);
      changeSet.removeChild(2);
      changeSet.changeChild(1,new Change());
      
      changeSet.clear();
      expect(changeSet.isEmpty,isTrue);
    });
    
    test('Test apply',(){
      changeSet.addChild(1);
      changeSet.addChild(2);
      changeSet.removeChild(5);
      changeSet.removeChild(6);
      changeSet.changeChild(7,new Change.fromValues(1,2));
      
      ChangeSet changeSet2 = new ChangeSet();
      changeSet2.addChild(3);
      changeSet2.addChild(5);
      changeSet2.removeChild(1);
      changeSet2.removeChild(4);
      changeSet2.changeChild(7,new Change.fromValues(1,5));
      changeSet2.changeChild(8,new Change.fromValues(1,5));
      
      changeSet.apply(changeSet2);
      
      expect(changeSet.addedChildren,equals(new Set.from([2,3])));
      expect(changeSet.removedChildren,equals(new Set.from([6,4])));
      expect(changeSet.changedChildren[7].newValue,equals(5));
      expect(changeSet.changedChildren[8].newValue,equals(5));
    });
  });
}
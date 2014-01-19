// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matchers;

import 'dart:core';
import 'package:unittest/unittest.dart';
import 'package:unittest/unittest.dart' as unittest;
import 'package:clean_data/clean_data.dart';

class ChangeEquals extends Matcher {
  Change change;
  ChangeEquals(this.change);
  
  bool matches(Change item, Map matchState) {
    return change.equals(item);
  }

  /** This builds a textual .Description of the .Matcher. */
  Description describe(Description description) {
    return description.add('equals ').addDescriptionOf(change.toString());
  }

  Description describeMismatch(item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if(item is! Change) {
      return mismatchDescription.add('is not Change.');
    }
    if(item.oldValue != change.oldValue) {
      return mismatchDescription.add('is different on oldValues.');
    }
    if(item.newValue != change.newValue) {
      return mismatchDescription.add('is different on newValues.');
    }
    return mismatchDescription.add('is unknown reason.');
  }
}
Matcher changeEquals(Change change) => new ChangeEquals(change);

class ChangeSetEquals extends Matcher {
  ChangeSet changeSet;
  ChangeSetEquals(this.changeSet);
  
  bool matches(ChangeSet item, Map matchState) {
    return changeSet.equals(item);
  }

  /** This builds a textual .Description of the .Matcher. */
  Description describe(Description description) {
    return description.addDescriptionOf(changeSet.toString());
  }

  Description describeMismatch(item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if(item is! ChangeSet) {
      return mismatchDescription.add('is not ChangeSet.');
    }
    if(item.changedItems.length != changeSet.changedItems.length) {
      return mismatchDescription.add('is not of equal length.');
    }
    bool thisEquals = true;
    changeSet.changedItems.forEach((key, value) {
      if(!thisEquals) return;
      if(!item.changedItems.containsKey(key)) {
        mismatchDescription.add('key: "$key" is missing.');
        thisEquals = false;
        return;
      }
      Matcher matcher = equals(value);
      
      if(!matcher.matches(item.changedItems[key], {})) {
        mismatchDescription.add('is not equal on key: "$key" which ');
        var subDescription = new StringDescription();
        matcher.describeMismatch(item.changedItems[key], subDescription,
            {}, verbose);    
        if (subDescription.length > 0) {
          mismatchDescription.add(subDescription);
        } else {
          mismatchDescription.add("doesn't match ");
          matcher.describe(mismatchDescription);
        }
        thisEquals = false;
      }
    });
    if(thisEquals)
     return mismatchDescription.add('is unknown reason.');
    else return mismatchDescription;
  }
}
Matcher changeSetEquals(ChangeSet change) => new ChangeSetEquals(change);

Matcher equals(expected, [limit=100]) {
    if(expected is Change) return changeEquals(expected);
    if(expected is ChangeSet) return changeSetEquals(expected);
    else return unittest.equals(expected, limit);
}
        
int main() {
  group('(changeEquals Matcher)', () {
    test('actually matches.', () {
      Change change = new Change('a', 'b');
      Change change2 = new Change('a', 'b');
      expect(change, equals(change2));
    });
    
    test('does not match.', () {
      Change change = new Change('a', 'b');
      Change change2 = new Change('a', 'c');
      expect(change, isNot(equals(change2)));
    });
    
    test('prints the reason.', () {
      Change change = new Change('a', 'b');
      Change change2 = new Change('a', 'c');
      Matcher matcher = changeEquals(change);
      expect(matcher.describeMismatch(change2, new StringDescription(), {}, null).toString(), 
          equals('is different on newValues.'));
    });
  });
  
  group('(changeSetEquals Matcher)', () {
    test('actually matches', () {
      ChangeSet changeSet = new ChangeSet({'name': new Change('Jozef', 'Peter')});
      ChangeSet changeSet2 = new ChangeSet();
      changeSet2.markChanged('name', new Change('Jozef', 'Peter'));
      
      expect(changeSet, equals(changeSet2));
    });
    
    test('does not match', () {
      ChangeSet changeSet = new ChangeSet({'name': new Change('Ondrej', 'Peter')});
      ChangeSet changeSet2 = new ChangeSet();
      changeSet2.markChanged('name', new Change('Jozef', 'Peter'));
      
      expect(changeSet, isNot(equals(changeSet2)));
    });
    
    test('prints the reason', () {
      ChangeSet changeSet = new ChangeSet({'name': new Change('Ondrej', 'Peter')});
      ChangeSet changeSet2 = new ChangeSet();
      ChangeSet changeSet3 = new ChangeSet();
      changeSet2.markChanged('name', new Change('Jozef', 'Peter'));
      
      Matcher matcher = changeSetEquals(changeSet);
      expect(matcher.describeMismatch(changeSet2, new StringDescription(), {}, null).toString(), 
          equals('is not equal on key: "name" which is different on oldValues.'));
      expect(matcher.describeMismatch(changeSet3, new StringDescription(), {}, null).toString(), 
          equals('is not of equal length.'));
    });
  });
}
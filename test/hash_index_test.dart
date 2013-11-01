// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library HashIndexTest;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';


void main() {
  
  group('(HashIndex)',() {

    setUp((){});
    
    test('add. (T01)', () {
      // given
      HashIndex index = new HashIndex();

      // when
      index.add('john', 1);
      index.add('mary', 2);
      index.add('john', 3);
      
      // then
      expect(index['john'], unorderedEquals([1,3]));
      expect(index['mary'], equals([2]));
      expect(index['foo'] is Set, isTrue);
      expect(index['foo'].isEmpty, isTrue);
    });

    test('remove. (T02)', () {
      // given
      HashIndex index = new HashIndex();
      index.add('john', 1);

      // when
      index.remove('john', 1);
      
      // then
      expect(index['john'].isEmpty, isTrue);
    });
  });
}
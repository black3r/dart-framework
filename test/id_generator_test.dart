// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';

void main() {
  test_generator();
}

test_generator(){
  group('IdGenerator',(){
    var prefix1 = 'vacuumapps';
    var prefix2 = 'cleandart';
        
    test('Generator correctly returns id when prefix is empty string.',(){
      var generator = new IdGenerator('');
      expect(generator.getId(),equals('1'));
      expect(generator.getId(),equals('2'));
      expect(generator.getId(),equals('3'));     
    });
    test('Generator correctly returns bigger ids.',(){
      var generator = new IdGenerator('');
      for(int i=1;i<1000;i++)
        generator.getId();
      expect(generator.getId(),equals('3e8'));
    });
    test('Generator correctly returns prefix.',(){
      var generator = new IdGenerator(prefix1);
      expect(generator.getId(),equals(prefix1+'1'));
    });
    test('Generator correctly appends numbers to  prefix.',(){
      var generator = new IdGenerator(prefix2);
      for(int i=1;i<211994;i++)
        generator.getId();
      expect(generator.getId(),equals(prefix2+'33c1a'));
    });
  });
}

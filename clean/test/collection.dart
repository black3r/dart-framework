// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'lib/clean_data.dart';

void main() {
  test_collection();
}

void test_collection() {
  group('Collection', () {
    test('can be created from List', () {
      Model model1 = new Model(1);
      Model model2 = new Model(2);
      Collection col = new Collection.fromList([model1, model2]);
      expect(col.length, equals(2));
      expect(col[1], equals(model1));
      expect(col[2], equals(model2));
    });
    test('can be created empty', () {
      Collection col = new Collection();
      expect(col.length, equals(0));
    });
    test('can be set read-only', () {
      Collection col = new Collection();
      Model model0 = new Model(0);
      col.add(model0);
      col.read_only = true;
      Model model1 = new Model(1);
      expect( () {
        col.add(model1);
      }, throwsException);
      expect( () {
        col.remove(model0);
      }, throwsException);
      expect(col[0], equals(model0));
    });
    test('getters work', () {
      Collection col = new Collection();
      Model model0 = new Model(0);
      Model model1 = new Model(1);
      col.add(model0);
      col.add(model1);
      expect(col[0], equals(model0));
      expect(col.get(0), equals(model0));
      expect(col[1], equals(model1));
      expect(col.get(1), equals(model1));
      expect(col.length, equals(2));
    });
    test('add/remove works', () {
      Collection col = new Collection();
      Model model = new Model(0);
      expect(col.length, equals(0));
      col.add(model);
      expect(col.length, equals(1));
      expect(col[0], equals(model));
      col.remove(model);
      expect(col.length, equals(0));
      expect(col[0], isNull);
      expect(() {
        col.remove(model);
      }, throwsArgumentError);
    });
  });
}
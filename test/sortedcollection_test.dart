// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';


void main() {
  test_sortedcollection();
}

void test_sortedcollection() {
  group('SortedCollection', () {

    Model model1, model2, model3, model4, model5, model6;
    List<Model> models;
    Collection collection, collection2;
    SortedCollection sorted1, sorted2;
    int cmp1(Model a, Model b) => a['value'] - b['value'];
    int cmp2(Model a, Model b) => b['value'] - a['value'];

    setUp(() {
      model1 = new Model(1);
      model2 = new Model(2);
      model3 = new Model(3);
      model4 = new Model(4);
      model5 = new Model(5);
      model6 = new Model(6);
      models = [model3, model2, model1, model4];

      for (var model in models) {
        model['value'] = model.id;
      }

      model5['value'] = 5;
      model6['value'] = 6;
      collection = new Collection.fromList(models);
      collection2 = new Collection.fromList(models);
      sorted1 = new SortedCollection(collection, cmp1);
      sorted2 = new SortedCollection(collection2, cmp2);
    });

    test('SortedCollection contains elements from parent in sorted order', () {
      expect(sorted1.toList(), orderedEquals([model1, model2, model3, model4]));
      expect(sorted2.toList(), orderedEquals([model4, model3, model2, model1]));
    });

    solo_test('SortedCollection gets updated when some of the models change.', () {
      sorted1.onChange.listen(expectAsync1((event) {
        expect(sorted1.toList(), orderedEquals([model2, model3, model4, model1]));
      }));
      sorted2.onChange.listen(expectAsync1((event) {
        expect(sorted2.toList(), orderedEquals([model1, model4, model3, model2]));
      }));
      model1['value'] = 10;
    });

    test('SortedCollection gets updated when the parent changes.', () {
      sorted1.onChange.listen(expectAsync1((event) {
        expect(sorted1.toList(), orderedEquals([model1, model2, model3, model4, model6]));
      }));
      sorted2.onChange.listen(expectAsync1((event) {
        expect(sorted2.toList(), orderedEquals([model4, model2, model1]));
      }));

      collection.add(model6);
      collection2.remove(3);
    });

  });
}

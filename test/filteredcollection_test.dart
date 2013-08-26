// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';


void main() {
  test_filteredcollection();
}

test_filteredcollection() {
  group('FilteredCollection', () {

    Model model1, model2, model3, model4, model5, model6;
    List<Model> models;
    Collection collection, collection2;
    bool evenTest(Model model) => model['value'] % 2 == 0;
    bool falseTest(Model model) => false;
    bool trueTest(Model model) => true;

    setUp(() {
      model1 = new Model(1);
      model2 = new Model(2);
      model3 = new Model(3);
      model4 = new Model(4);
      model5 = new Model(5);
      model6 = new Model(6);
      models = [model1, model2, model3, model4];

      for (var model in models) {
        model['value'] = model.id;
      }

      model5['value'] = 5;
      model6['value'] = 6;
      collection = new Collection.fromList(models);
      collection2 = new Collection.fromList(models);


    });

    test('FilteredCollection contains elements from parent that passes'
        ' the test.', () {
      var filtered = new FilteredCollection(collection, evenTest);
      expect(filtered.toList(), equals([model2, model4]));
      filtered = new FilteredCollection(collection, falseTest);
      expect(filtered.toList(), equals([]));
      filtered = new FilteredCollection(collection, trueTest);
      expect(filtered.toList(), equals(models));
    });

    test('FilteredCollection gets updated when some of the models change.', () {
      var filtered = new FilteredCollection(collection, evenTest);
      filtered.onChange.listen(expectAsync1((event) {
        expect(filtered.toList(), equals([model4]));
      }));
      model2['value'] = 5;
    });

    test('FilteredCollection gets updated when the parent collection changes.',
        () {
      var filtered1 = new FilteredCollection(collection, evenTest);
      filtered1.onChange.listen(expectAsync1((event) {
        expect(filtered1.toList(), equals([model4]));
      }));
      collection.remove(2);

      var filtered2 = new FilteredCollection(collection2, evenTest);
      filtered2.onChange.listen(expectAsync1((event) {
        expect(filtered2.toList(), equals([model2, model4, model6]));
      }));
      collection2.add(model6);
    });

  });
}
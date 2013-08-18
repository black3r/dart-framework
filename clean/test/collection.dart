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

    Model model1, model2, model3;
    setUp(() {
      model1 = new Model(1);
      model2 = new Model(2);
      model3 = new Model(3);
    });

    test('Collection.fromList creates an collection containing the models from'
        ' the list provided.', () {
      var collection = new Collection.fromList([model1, model2]);
      expect(collection.length, equals(2));
      expect(collection[1], equals(model1));
      expect(collection[2], equals(model2));
    });

    test('We can iterate through the collection using the for-in construct.',
        () {
      var collection = new Collection.fromList([model1, model2]);
      var models = [];
      for (var model in collection) {
        models.add(model);
      }
      expect(models, equals([model1, model2]));
    });

    test('New models are appended to the collection using the add method.', () {
      var collection = new Collection();
      collection.add(model1);
      collection.add(model2);
      expect(collection.containsId(1), equals(true));
      expect(collection[1], equals(model1));
      expect(collection[2], equals(model2));
      expect(collection.length, equals(2));
    });

    test('Information about new models appended is pushed through the'
        ' Stream onChange.', () {
      var collection = new Collection.fromList([model1, model2]);
      collection.onChange.listen(expectAsync1((event) {
        expect(event['type'], equals('add'));
        expect(event['values'], equals([model3]));
      }));
      collection.add(model3);
    });

    test('Models are removed from the collection using the remove method.', () {
      var collection = new Collection.fromList([model1, model2]);
      collection.remove(1);
      expect(collection.containsId(1), equals(false));
      expect(collection.containsId(2), equals(true));
      var models = [];
      for (var model in collection) {
        models.add(model);
      }
      expect(models, equals([model2]));
    });

    test('Information about removed models is pushed through the'
        ' Stream onChange.', () {
      var collection = new Collection.fromList([model1, model2]);
      collection.onChange.listen(expectAsync1((event) {
        expect(event['type'], equals('remove'));
        expect(event['values'], equals([model2]));
      }));
      collection.remove(2);
    });

    test('Information about changed models is pushed through the'
        ' Stream onChange', () {
      var collection = new Collection.fromList([model1, model2]);
      collection.onChange.listen(expectAsync1((event) {
        expect(event['type'], equals('change'));
        expect(event['values'], equals([model1]));
      }));
      model1['name'] = 'John Doe';
    });

    test('Information about the models not longer present in the collection'
        ' is not monitored anymore.', () {
      var collection = new Collection.fromList([model1, model2]);
      collection.remove(1, silent: true);
      collection.onChange.listen((event) => guardAsync(() => expect(true, isFalse)));
      model1['name'] = 'John Doe';
   });
  });
}
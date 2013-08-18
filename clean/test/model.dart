// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'lib/clean_data.dart';

void main() {
  test_model();
}

void test_model() {
  group('Model', () {
    test('Model id is set in the constructor.', () {
      var model = new Model(47);
      expect(model.id, equals(47));
    });

    test('Function Model.fromData creates an instance'
        ' filled with a data provided.', () {
      var model = new Model.fromData(47, {
        'first_key': 'first_value',
        'second_key': 'second_value',
        'third_key': 'third_value',
      });

      expect(model['first_key'], equals('first_value'));
      expect(model['second_key'], equals('second_value'));
      expect(model['third_key'], equals('third_value'));

    });
    test('Model works similarly to a map.', () {
      var model = new Model(47);
      model['what'] = 'that';
      model['who'] = 'him';
      expect(model['what'], equals('that'));
      expect(model['who'], equals('him'));
      model['what'] = 'somethingelse';
      expect(model['what'], equals('somethingelse'));

      expect(model.containsKey('what'), equals(true));
      expect(model.containsKey('notthere'), equals(false));
    });

    test('But the id field is read only.', () {
      var model = new Model(13);
      expect(() => model['id'] = '14', throwsArgumentError);
    });

    test('Information about model changes is available through Stream'
        ' onChange.', () {
      var model = new Model(47);
      model['key1'] = 13;
      model['key2'] = 47;
      model.onChange.listen(expectAsync1((event) {
        expect(event['source'], equals(model));
        expect(event['old_values'].length, equals(1));
        expect(event['old_values']['key2'], equals(47));
        expect(event['new_values'].length, equals(1));
        expect(event['new_values']['key2'], equals(48));

      }));

      model['key2'] = 48;

      var anotherModel = new Model(48);
      anotherModel['key0'] = 10;
      anotherModel.onChange.listen(expectAsync1((event) {
        expect(event['source'], equals(anotherModel));
        expect(event['old_values'].length, equals(0));
        expect(event['new_values'].length, equals(1));
        expect(event['new_values']['key1'], equals(15));

      }));
      anotherModel['key1'] = 15;
    });
  });
}
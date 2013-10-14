// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';


void main() {

  group('Model', () {

    test('initialize.', () {

      // when
      var model = new Model();

      // then
      expect(model.isEmpty, isTrue);
      expect(model.isNotEmpty, isFalse);
      expect(model.length, 0);
    });

    test('initialize with data.', () {
      // given
      var data = {
        'first_key': 'first_value',
        'second_key': 'second_value',
        'third_key': 'third_value',
      };

      // when
      var model = new Model.fromData(data);

      // then
      expect(model.isEmpty, isFalse);
      expect(model.isNotEmpty, isTrue);
      expect(model.length, equals(data.length));
      expect(model.keys, equals(data.keys));
      expect(model.values, equals(data.values));
      for (var key in data.keys) {
        expect(model[key], equals(data[key]));
      }
    });

    test('is accessed like a map.', () {
      // given
      var model =  new Model();

      // when
      model['key'] = 'value';

      // then
      expect(model['key'], equals('value'));
    });


    test('listen on {key, value} added.', () {
      // given
      var model = new Model();

      // when
      model['key'] = 'value';

      // then
      model.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedChildren.isEmpty, isTrue);
        expect(event.removedChildren.isEmpty, isTrue);
        expect(event.addedChildren, unorderedEquals(['key']));
      }));

    });

    test('listen on {key, value} removed.', () {
      // given
      var data = {'key': 'value'};
      var model = new Model.fromData(data);

      // when
      model.remove('key');

      // then
      model.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedChildren.isEmpty, isTrue);
        expect(event.addedChildren.isEmpty, isTrue);
        expect(event.removedChildren, unorderedEquals(['key']));
      }));

    });

    test('listen on {key, value} changed.', () {
      // given
      var data = {'key': 'oldValue'};
      var model = new Model.fromData(data);

      // when
      model['key'] = 'newValue';

      // then
      model.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedChildren.isEmpty, isTrue);
        expect(event.removedChildren.isEmpty, isTrue);
        expect(event.changedChildren.length, equals(1));
        var change = event.changedChildren['key'];
        expect(change.oldValue, equals('oldValue'));
        expect(change.newValue, equals('newValue'));
      }));
    });

    test('propagate multiple changes in single [ChangeSet].', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var model = new Model.fromData(data);

      // when
      model['key1'] = 'newValue1';
      model.remove('key2');
      model['key3'] = 'value3';

      // then
      model.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedChildren.keys, unorderedEquals(['key1']));
        expect(event.removedChildren, unorderedEquals(['key2']));
        expect(event.addedChildren, unorderedEquals(['key3']));
      }));
    });
  });
}
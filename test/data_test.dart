// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';


void main() {

  group('Data', () {

    test('initialize.', () {

      // when
      var data = new Data();

      // then
      expect(data.isEmpty, isTrue);
      expect(data.isNotEmpty, isFalse);
      expect(data.length, 0);
    });

    test('initialize with data.', () {
      // given
      var data = {
        'first_key': 'first_value',
        'second_key': 'second_value',
        'third_key': 'third_value',
      };

      // when
      var dataObj = new Data.fromMap(data);

      // then
      expect(dataObj.isEmpty, isFalse);
      expect(dataObj.isNotEmpty, isTrue);
      expect(dataObj.length, equals(data.length));
      expect(dataObj.keys, equals(data.keys));
      expect(dataObj.values, equals(data.values));
      for (var key in data.keys) {
        expect(dataObj[key], equals(data[key]));
      }
    });

    test('is accessed like a map.', () {
      // given
      var dataObj =  new Data();

      // when
      dataObj['key'] = 'value';

      // then
      expect(dataObj['key'], equals('value'));
    });


    test('listen on {key, value} added.', () {
      // given
      var dataObj = new Data();

      // when
      dataObj['key'] = 'value';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.addedItems, unorderedEquals(['key']));
      }));

    });

    test('listen on {key, value} removed.', () {
      // given
      var data = {'key': 'value'};
      var dataObj = new Data.fromMap(data);

      // when
      dataObj.remove('key');

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.isEmpty, isTrue);
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems, unorderedEquals(['key']));
      }));

    });

    test('listen on {key, value} changed.', () {
      // given
      var data = {'key': 'oldValue'};
      var dataObj = new Data.fromMap(data);

      // when
      dataObj['key'] = 'newValue';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedItems.isEmpty, isTrue);
        expect(event.removedItems.isEmpty, isTrue);
        expect(event.changedItems.length, equals(1));
        var change = event.changedItems['key'];
        expect(change.oldValue, equals('oldValue'));
        expect(change.newValue, equals('newValue'));
      }));
    });

    test('propagate multiple changes in single [ChangeSet].', () {
      // given
      var data = {'key1': 'value1', 'key2': 'value2'};
      var dataObj = new Data.fromMap(data);

      // when
      dataObj['key1'] = 'newValue1';
      dataObj.remove('key2');
      dataObj['key3'] = 'value3';

      // then
      dataObj.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedItems.keys, unorderedEquals(['key1']));
        expect(event.removedItems, unorderedEquals(['key2']));
        expect(event.addedItems, unorderedEquals(['key3']));
      }));
    });
  });
}

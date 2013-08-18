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
    test('assigns ID correctly in constructor', () {
      Model model = new Model(47);
      expect(model.id, equals(47));
    });
    test('assigns data correctly in constructor', () {
      Model model = new Model.fromData(47, {'what': 'that'});
      expect(model['what'], equals('that'));
    });
    test('sets data correctly', () {
      Model model = new Model(47);
      model['what'] = 'that';
      expect(model['what'], equals('that'));
    });
    test('ID is read-only', () {
      Model model = new Model(47);
      expect( () {
        model['id'] = 42;
      }, throwsArgumentError);
    });
    test('Event is dispatched & caught', () {
      Model model = new Model(47);
      var callback = expectAsync0((){});
      model.events.listen((Map event) {
        if (event['eventtype'] == 'modelChanged') {
          expect(event['new']['what'], equals('that'));
          callback();
        }
      });
      model['what'] = 'that';
    });
  });
}
// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library mvc.test.model;
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:web_ui/watcher.dart' as watchers;
import 'package:web_ui/observe.dart';
import 'lib/model.dart';

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
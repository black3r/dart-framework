// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library mvc.test.collection.filtered;
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:web_ui/watcher.dart' as watchers;
import 'package:web_ui/observe.dart';
import 'lib/collection.dart';
import 'lib/model.dart';
import 'lib/filteredcollection.dart';

void main() {
  test_filteredcollection();
}

bool sf_true(Model model) {
  return true;
}

bool sf_false(Model model) {
  return false;
}

bool sf_lessthan(Model model) {
  return (model.id < 47);
}

bool sf_booltest(Model model) {
  return model['test'];
}

test_filteredcollection() {
  group('FilteredCollection', () {
    test('all true', () {
      Model model = new Model(47);
      Collection col = new Collection.fromList([model]);
      FilteredCollection fcol = new FilteredCollection(col, sf_true);
      expect(fcol.length, equals(1));
    });
    
    test('all false', () {
      Model model = new Model(47);
      Collection col = new Collection.fromList([model]);
      FilteredCollection fcol = new FilteredCollection(col, sf_false);
      expect(fcol.length, equals(0));    
    });
    
    test('some pass', () {
      Model model1 = new Model(47);
      Model model2 = new Model(42);
      Collection col = new Collection.fromList([model1, model2]);
      FilteredCollection fcol = new FilteredCollection(col, sf_lessthan);
      expect(fcol.length, equals(1));
    });
    test('parent add pass', () {
      Collection col = new Collection();
      FilteredCollection fcol = new FilteredCollection(col, sf_true);
      Model model = new Model(47);
      var callback = expectAsync0((){});
      fcol.events.listen((Map event) {
        if (event['eventtype'] == 'modelAdded') {
          expect(fcol.length, equals(1));
          callback();
        }
      });
      col.add(model);    
    });
    test('parent add nopass', () {
      Collection col = new Collection();
      FilteredCollection fcol = new FilteredCollection(col, sf_false);
      Model model = new Model(47);
      var callback = protectAsync0((){});
      fcol.events.listen((Map event) {
        if (event['eventtype'] == 'modelAdded') {
          expect(fcol.length, equals(0));
          callback();
        }
      });
      col.add(model);
    });
    test('model passed before', () {
      Model model = new Model(42);
      model['test'] = true;
      Collection col = new Collection.fromList([model]);
      FilteredCollection fcol = new FilteredCollection(col, sf_booltest);
      var callback = expectAsync0((){});
      fcol.events.listen((Map event) {
        if (event['eventtype'] == 'modelRemoved') {
          expect(fcol.length, equals(0));
          callback();
        }
      });
      model['test'] = false;
    });
    test('model did not pass before', () {
      Model model = new Model(42);
      model['test'] = false;
      Collection col = new Collection.fromList([model]);
      FilteredCollection fcol = new FilteredCollection(col, sf_booltest);
      var callback = expectAsync0((){});
      fcol.events.listen((Map event) {
        if (event['eventtype'] == 'modelAdded') {
          expect(fcol.length, equals(1));
          callback();
        }
      });
      model['test'] = true;
    });
    test('model parent removed', () {
      Model model = new Model(42);
      model['test'] = true;
      Collection col = new Collection.fromList([model]);
      FilteredCollection fcol = new FilteredCollection(col, sf_booltest);
      var callback = expectAsync0((){});
      fcol.events.listen((Map event) {
        if (event['eventtype'] == 'modelRemoved') {
          expect(fcol.length, equals(0));
          callback();
        }
      });
      col.remove(model);
    });
  });
}
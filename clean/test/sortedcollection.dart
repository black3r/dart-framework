// Copyright (c) 2013, Roman Hudec. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE
// file.

library mvc.test.collection.sorted;
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:web_ui/watcher.dart' as watchers;
import 'package:web_ui/observe.dart';
import 'lib/collection.dart';
import 'lib/model.dart';
import 'lib/sortedcollection.dart';

void main() {
  test_sortedcollection();
}

void cmp_id(Model a, Model b) {
  return a.id - b.id;
}

void cmp_id2(Model a, Model b) {
  return b.id - a.id;
}

void test_sortedcollection() {
  group('SortedCollection', () {
    test('sorts', () {
      Model model1 = new Model(1);
      Model model2 = new Model(2);
      Model model3 = new Model(3);
      Collection col = new Collection.fromList([model1, model2, model3]);
      SortedCollection scol = new SortedCollection(col, cmp_id);
      expect(scol.sorted, equals([model1, model2, model3]));
      col = new Collection.fromList([model3, model2, model1]);
      scol = new SortedCollection(col, cmp_id);
      expect(scol.sorted, equals([model1, model2, model3]));
      scol = new SortedCollection(col, cmp_id2);
      expect(scol.sorted, equals([model3, model2, model1]));    
    });
    test('inserts correctly', () {
      Model m1 = new Model(1);
      Model m2 = new Model(2);
      Model m3 = new Model(3);
      Model m4 = new Model(4);
      Model m5 = new Model(5);
      Collection col = new Collection.fromList([m1, m4, m3, m5]);
      var correct = [m1, m2, m3, m4, m5];
      SortedCollection scol = new SortedCollection(col, cmp_id);    
      var callback = expectAsync0((){});
      scol.events.listen((Map event) {
        if (event['eventtype'] == 'modelAdded') {
          expect(scol.sorted, equals(correct));
          callback();
        }
      });
      col.add(m2);    
    });
    test('removes correctly', () {
      Model m1 = new Model(1);
      Model m2 = new Model(2);
      Model m3 = new Model(3);
      Model m4 = new Model(4);
      Model m5 = new Model(5);
      Collection col = new Collection.fromList([m1, m4, m3, m5, m2]);
      var correct = [m1, m3, m4, m5];
      SortedCollection scol = new SortedCollection(col, cmp_id);    
      var callback = expectAsync0((){});
      scol.events.listen((Map event) {
        if (event['eventtype'] == 'modelRemoved') {
          expect(scol.sorted, equals(correct));
          callback();
        }
      });
      col.remove(m2);
    });
  });
}
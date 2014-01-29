// Copyright (c) 2014, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sorted_set_view_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {
  group('(SortedListView)', () {
    DataMap data1, data2;
    DataSet set;
    var key = (item) => item['a'];
    var comparer = (item1, item2) => item1['a'].compareTo(item2['a']);
    var mapper = (dataObj) {
      var result = clone(dataObj);
      result['c'] = 'd';
      return result;
    };

    setUp(() {
      data1 = new DataMap.from({
        '_id': 'data1',
        'a': 'b',
        'b': 'c',
      });
      data2 = new DataMap.from({
        '_id': 'data2',
        'a': 'e',
        'b': 'f',
      });
      set = new DataSet.from([data2, data1]);
      set.addIndex(['_id']);
    });

    test('Constructor fromKey. (T01)', () {
      SortedDataListView sorted = new SortedDataListView.fromKey(set, (item) => item['a']);
      var first = sorted[0];
      var second = sorted[1];
      expect(first, equals(data1));
      expect(second, equals(data2));
    });

    test('Default constructor. (T02)', () {
      SortedDataListView sorted = new SortedDataListView(set, comparer);
      var first = sorted[0];
      var second = sorted[1];
      expect(first, equals(data1));
      expect(second, equals(data2));
    });

    test('Add. (T02)', () {
      SortedDataListView sorted = new SortedDataListView(set, comparer);
      var data3 = new DataMap.from({
        '_id': 'data3',
        'a': 'g',
        'b': 'h',
      });

      set.add(data3);

      sorted.onChange.listen(expectAsync1((ChangeSet dataObj) {
        expect(dataObj.addedItems.length, equals(1));
        var added = dataObj.addedItems.first;
        expect(sorted[added], equals(data3));
      }));
    });

    test('Remove. (T03)', () {
      SortedDataListView sorted = new SortedDataListView(set, comparer);

      set.remove(data2);

      sorted.onChange.listen(expectAsync1((ChangeSet dataObj) {
        expect(dataObj.removedItems.length, equals(1));
        expect(sorted[0], equals(data1));
        expect(sorted.length, equals(1));
      }));
    });

    test('Change. (T04)', () {
      SortedDataListView sorted = new SortedDataListView(set, comparer);

      data2['a'] = 'a';

      sorted.onChange.listen(expectAsync1((ChangeSet dataObj) {
        expect(dataObj.changedItems.length, equals(2));
        expect(sorted[0], equals(data2));
        expect(sorted[1], equals(data1));
      }));
    });
  });
}
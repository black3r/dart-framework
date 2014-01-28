// Copyright (c) 2014, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mapped_set_view_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {
  group('(MappedsetView)', () {
    DataMap data1, data2;
    DataSet set;
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
      set = new DataSet.from([data1, data2]);
      set.addIndex(['_id']);
    });

    test('Constructed properly. (T01)', () {
      MappedDataSetView mapped = new MappedDataSetView(set, mapper);
      mapped.addIndex(['_id']);
      var mdata1 = mapped.findBy('_id', 'data1').first;
      var mdata2 = mapped.findBy('_id', 'data2').first;
      expect(mdata1['a'], equals(data1['a']));
      expect(mdata1['b'], equals(data1['b']));
      expect(mdata1['c'], equals('d'));
      expect(mdata2['a'], equals(data2['a']));
      expect(mdata2['b'], equals(data2['b']));
      expect(mdata2['c'], equals('d'));
    });

    test('Add. (T02)', () {
      MappedDataSetView mapped = new MappedDataSetView(set, mapper);
      var data3 = new DataMap.from({
        '_id': 'data3',
        'a': 'g',
        'b': 'h',
      });

      set.add(data3);

      mapped.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet.addedItems.length, equals(1));
        var mdata3 = changeSet.addedItems.first;
        expect(mdata3['a'], equals(data3['a']));
        expect(mdata3['b'], equals(data3['b']));
        expect(mdata3['c'], equals('d'));
      }));
    });

    test('Remove. (T03)', () {
      MappedDataSetView mapped = new MappedDataSetView(set, mapper);

      set.remove(data2);

      mapped.onChange.listen(expectAsync1((ChangeSet changeSet) {
        expect(changeSet.removedItems.length, equals(1));
        var mdata2 = changeSet.removedItems.first;
        expect(mdata2, equals(mapper(data2)));
      }));
    });
  });
}
// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library change_set_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'matchers.dart' as matchers;

var equals = matchers.equals;

void main() {

  group('(Change)', () {

    test('initialize.', () {

      // when
      var change = new Change("old", "new");

      // then
      expect(change.oldValue, equals("old"));
      expect(change.newValue, equals("new"));
    });

    test('apply another change object.', () {
      // given
      var firstChange = new Change("old", "new");
      var secondChange = new Change("new", "newer");

      // when
      firstChange.mergeIn(secondChange);

      // then
      expect(firstChange.oldValue, equals("old"));
      expect(firstChange.newValue, equals("newer"));
    });

    test('clone change.', () {
      // given
      var change = new Change('old', 'new');

      // when
      var clone = change.clone();

      // then
      expect(clone.oldValue, equals(change.oldValue));
      expect(clone.newValue, equals(change.newValue));
    });

  });

  group('(ChangeSet)', () {

    ChangeSet changeSet;
    List children;

    setUp((){
      changeSet = new ChangeSet();
      children = ['first', 'second', 'third'];
    });

    test('initialization.', () {
      // when
      var changeSet = new ChangeSet();

      // then
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isTrue);
      expect(changeSet.isEmpty, isTrue);
    });

    test('clone.', () {
      // given
      var change = new Change(1,2);

      var changeSet = new ChangeSet();
      changeSet.markAdded('january', null);
      changeSet.markRemoved('february', null);
      changeSet.markChanged('march', change);

      // when
      var clone = changeSet.clone();

      // then
      expect(identical(clone, changeSet), isFalse);
      expect(clone.equals(changeSet), isTrue);
    });

    test('add children.', () {
      // when
      for (var child in children) {
        changeSet.markAdded(child, null);
      }

      //  then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isFalse);
      expect(changeSet.addedItems, unorderedEquals(children));
    });

    test('remove children.', () {
      // when
      for (var child in children) {
        changeSet.markRemoved(child, null);
      }

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.isEmpty, isFalse);
      expect(changeSet.removedItems, unorderedEquals(children));
    });

    test('add previously removed children.', () {
      // given
      for (var child in children) {
        changeSet.markRemoved(child, child);
      }

      // when
      for (var child in children) {
        changeSet.markAdded(child, child);
      }

      // then

      expect(changeSet, equals(new ChangeSet({
        'first': new Change('first', 'first'),
        'second': new Change('second', 'second'),
        'third': new Change('third', 'third')
      })));
    });

    test('remove previosly added children.', () {
      // given
      for (var child in children) {
        changeSet.markAdded(child, child);
      }

      // when
      for (var child in children) {
        changeSet.markRemoved(child, child);
      }

      // then

      expect(changeSet, equals(new ChangeSet({
        'first': new Change(undefined, undefined),
        'second': new Change(undefined, undefined),
        'third': new Change(undefined, undefined)
      })));
    });

    test('change children.', () {
      // given
      var changes =
        {'first': new Mock(), 'second': new Mock(), 'third': new Mock()};
      for (var mock in changes.values) {
        mock.when(callsTo('clone')).alwaysReturn([mock]);
      }

      // when
      for (var child in changes.keys) {
        changeSet.markChanged(child, changes[child]);
      }

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.removedItems.isEmpty, isTrue);
      expect(changeSet.changedItems.length, equals(changes.length));
      for (var child in changeSet.changedItems.keys) {
        expect(changeSet.changedItems[child], equals(changes[child].clone()));
      }
    });

    test('change child that was changed before.', () {
      // given
      var change = new Mock();
      var anotherChange = new Mock();
      var changeClone = new Mock();
      change.when(callsTo('clone')).alwaysReturn(changeClone);

      changeSet.markChanged('child', change);

      // when
      changeSet.markChanged('child', anotherChange);

      // then
      expect(changeSet.isEmpty, isFalse);
      expect(changeSet.addedItems.isEmpty, isTrue);
      expect(changeSet.removedItems.isEmpty, isTrue);
      changeClone.getLogs(callsTo('mergeIn', anotherChange)).verify(happenedOnce);
      expect(changeSet.changedItems['child'], equals(changeClone));
    });

    test('change child that was added before.',() {

      for (var child in children) {
        changeSet.markAdded(child, child);
      }

      // when
      for (var child in children) {
        changeSet.markChanged(child, new Change(child, child+'_'));
      }

      // then
      expect(changeSet.addedItems, unorderedEquals(children));
      changeSet.changedItems.forEach((key, Change value){
        expect(value, equals(new Change(undefined, '${key}_')));
      });
    });


    test('apply another ChangeSet.', () {
      // given
      var change1 = new Change('v1', 'v2');
      var change2 = new Change('va', 'vb');

      changeSet.markChanged('key1', change1);

      var anotherChangeSet = new ChangeSet();
      anotherChangeSet.markChanged('key2', change2);

      // when
      changeSet.mergeIn(anotherChangeSet);

      // then
      expect(changeSet, equals(new ChangeSet({
        'key1': new Change('v1', 'v2'),
        'key2': new Change('va', 'vb')}
      )));
    });

    test('changeSet correctly splits to added, removed and modified items', (){
      Map data = {'a': 1};
      var change = new ChangeSet({
                         'a': new Change(1,2),
                         'b': new ChangeSet({'a': new Change(1,2)}),
                         'c': new Change(undefined, 1),
                         'd': new Change(1, undefined),
                         'e': new Change(data, data)
                    });
      expect(change.addedItems.length +
             change.removedItems.length +
             change.strictlyChanged.length,
             equals(change.changedItems.length));
    });

    group('(json', () {
      group('export)', () {
        test('changes', () {
          changeSet = new ChangeSet({
            'add': new Change(undefined, 'value'),
            'change' : new Change('oldValue', 'newValue'),
            'remove' : new Change('value', undefined),
          });

          Map exportedJson = changeSet.toJson();

          expect(exportedJson, equals({
            'add': [CLEAN_UNDEFINED, 'value'],
            'change' : ['oldValue', 'newValue'],
            'remove' : ['value', CLEAN_UNDEFINED]
          }));
        });

        test('key may be number', () {
          changeSet = new ChangeSet({
            'string': new Change(undefined, 'string'),
            47 : new Change(47, 'forty seven'),
          });

          Map exportedJson = changeSet.toJson();

          expect(exportedJson, equals({
            'string': [CLEAN_UNDEFINED, 'string'],
            47 : [47, 'forty seven'],
          }));
        });

        test('nested changeset', () {
          changeSet = new ChangeSet({
            'set': new ChangeSet({
              'change' : new Change('oldValue', 'newValue'),
            }),
            'remove' : new Change('value', undefined),
          });

          Map exportedJson = changeSet.toJson();

          expect(exportedJson, equals({
            'set': {
              'change': ['oldValue', 'newValue']
              },
            'remove' : ['value', CLEAN_UNDEFINED]
          }));
        });

        test('_id is extracted from key if possible on top-level', () {
          changeSet = new ChangeSet({
            {'change': 'newValue', '_id': 'id'}:
              new ChangeSet({'change': new Change('oldValue', 'newValue')}),
          });

          Map exportedJson = changeSet.toJson();

          expect(exportedJson, equals({
            'id': { 'change': ['oldValue', 'newValue'] }
          }));
        });

        test('key if map must contain _id', () {
          changeSet = new ChangeSet({
            {'change': 'newValue'}: new Change('oldValue', 'newValue'),
          });

          expect(changeSet.toJson, throwsException);
        });

        test('_id if present must be primitive', () {
          changeSet = new ChangeSet({
            {'_id': {}}: new Change('oldValue', 'newValue'),
          });

          expect(changeSet.toJson, throwsException);
        });

        test('only primitive types can be on not top-level changeset', () {
          changeSet = new ChangeSet({
            'key':  new ChangeSet({{'key': 'value'}: new Change('oldValue', 'newValue')}),
          });
          expect(changeSet.toJson, throwsException);

          changeSet = new ChangeSet({
            'key':  new ChangeSet({{'_id': 'value'}: new Change('oldValue', 'newValue')}),
          });
          expect(changeSet.toJson, throwsException);

          changeSet = new ChangeSet({
            'key':  new ChangeSet({47: new Change('oldValue', 'newValue')}),
          });
          expect(changeSet.toJson, isNot(throwsException));

          changeSet = new ChangeSet({
            'key':  new ChangeSet({'string': new Change('oldValue', 'newValue')}),
          });
          expect(changeSet.toJson, isNot(throwsException));
        });
      });

      group('apply)', () {
        test('change, add, remove in datamap', () {
          Map json = { 'add': [CLEAN_UNDEFINED, 'value'],
            'change' : ['oldValue', 'newValue'],
            'remove' : ['value', CLEAN_UNDEFINED]
          };

          DataMap map = new DataMap.from({
            'change': 'oldValue',
            'remove': 'value'
          });
          applyJSON(json, map);

          expect(map, equals({
            'add': 'value',
            'change': 'newValue'
          }));
        });

        test('change and add in datalist', () {
          Map json = { 1: [CLEAN_UNDEFINED, 'add'],
            0 : ['oldValue', 'newValue'],
          };
          DataList list = new DataList.from(['oldValue']);

          applyJSON(json, list);

          expect(list, equals(['newValue', 'add']));
        });

        test('change and remove in datalist', () {
          Map json = { 1: ['remove', CLEAN_UNDEFINED],
            0 : ['oldValue', 'newValue'],
          };
          DataList list = new DataList.from(['oldValue', 'remove']);

          applyJSON(json, list);

          expect(list, equals(['newValue']));
        });

        test('changes, adds, remove in dataset', () {
          Map json = { 1: ['remove', CLEAN_UNDEFINED],
            2 : [{'_id': 2, 'change': 'oldValue'}, {'_id': 2, 'changeNew': 'newValue'}],
            3 : [CLEAN_UNDEFINED, {'_id': 3, 'new': null}]
          };

          DataSet set = new DataSet.from([{'_id': 1, 'remove': null},
             {'_id': 2, 'change': 'oldValue'}]);
          set.addIndex(['_id']);

          applyJSON(json, set);

          expect(set.toList(), unorderedEquals([{'_id': 3, 'new': null},
               {'_id': 2, 'changeNew': 'newValue'}]));
        });

        test('nested data on map', () {
          Map json = { 'a': {'b': ['old', 'new']}};

          DataMap map = new DataMap.from({'a': {'b': 'old', 'c': 'c'}});

          applyJSON(json, map);

          expect(map, equals({'a': {'b': 'new', 'c': 'c'}}));
        });

        test('nested data on list', () {
          Map json = { 0: {'b': ['old', 'new']}};

          DataList list = new DataList.from([{'b': 'old', 'c': 'c'}, 'second']);

          applyJSON(json, list);

          expect(list, equals([{'b': 'new', 'c': 'c'}, 'second']));
        });

        test('nested data on set', () {
          Map json = { 1: {'b': ['old', 'new']}};

          DataSet set = new DataSet.from([{'_id': 1, 'b': 'old', 'c': 'c'},
            {'_id': 2, 'b': 'other'}]);
          set.addIndex(['_id']);

          applyJSON(json, set);

          expect(set.toList(), equals([{'_id': 1, 'b': 'new', 'c': 'c'},
                                       {'_id': 2, 'b': 'other'}]));
        });


        test('propagates only changes that have truly happened. (map)', () {
          Map json = { 'a': {'b': ['old', 'new'], 'd': [CLEAN_UNDEFINED, 'd']}};

          DataMap map = new DataMap.from({'a': {'b': 'old', 'c': 'c'}});

          applyJSON(json, map);

          map.onChange.listen(expectAsync((ChangeSet changeSet) {
            expect(changeSet.toJson(), equals(json));
          }));
        });

        test('propagates only changes that have truly happened. (list)', () {
          Map json = { 0: {'b': ['old', 'new'], 'd': [CLEAN_UNDEFINED, 'd']}};

          DataList list = new DataList.from([{'b': 'old', 'c': 'c'}, 'second']);

          applyJSON(json, list);

          list.onChange.listen(expectAsync((ChangeSet changeSet) {
            expect(changeSet.toJson(), equals(json));
          }));
        });

        test('propagates only changes that have truly happened. (set)', () {
          Map json = { 1: {'b': ['old', 'new'], 'd': [CLEAN_UNDEFINED, 'd']}};

          DataSet set = new DataSet.from([{'_id': 1, 'b': 'old', 'c': 'c'},
            {'_id': 2, 'b': 'other'}]);
          set.addIndex(['_id']);

          applyJSON(json, set);

          set.onChange.listen(expectAsync((ChangeSet changeSet) {
            expect(changeSet.toJson(), equals(json));
          }));
        });


      });
    });
  });
}

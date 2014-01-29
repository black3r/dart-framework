library cleanify_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:collection';

main(){
  group('(Cleanify)', () {
    test('from Object creates DataReference. (T01)', () {
      var result = cleanify('String');
      expect(result, new isInstanceOf<DataReference>());
      expect(result.value, equals('String'));
    });

    test('from List creates DataList. (T02)', () {
      var result = cleanify(['L', 'I', 'S', 'T']);
      expect(result, new isInstanceOf<DataList>());
      expect(result, equals(['L', 'I', 'S', 'T']));
    });

    test('from Map creates DataMap. (T03)', () {
      var result = cleanify({'name': 'Princess', 'age': 15});
      expect(result, new isInstanceOf<DataMap>());
      expect(result.length, equals(2));
      expect(result['name'], equals('Princess'));
      expect(result['age'], equals(15));
    });

    test('from Set creates DataSet. (T04)', () {
      var result = cleanify(new Set.from([4, 4, 7,9]));
      expect(result, new isInstanceOf<DataSet>());
      expect(result, unorderedEquals([4, 7, 9]));
    });

    test('from Iterable creates DataSet. (T04)', () {
      DataSet result = cleanify(new Queue.from([5, 1]));
      expect(result, new isInstanceOf<DataSet>());
      expect(result.contains(5), isTrue);
      expect(result.contains(1), isTrue);
    });

    test('creates CleanData recursively for List. (T05)', () {
      var result = cleanify([{'name': 'Filip'}, {'name': 'Beethoven'}, new Set.from([4,5,7])]);
      expect(result, new isInstanceOf<DataList>());
      expect(result[0], new isInstanceOf<DataMap>());
      expect(result[1], new isInstanceOf<DataMap>());
      expect(result[2], new isInstanceOf<DataSet>());

      expect(result[1]['name'], equals('Beethoven'));
      expect(result[2].contains(5), isTrue);
    });

    test('creates CleanData recursively for Map. (T06)', () {
      var result = cleanify({'list': [4, 7], 'name': new Set.from(['random'])});

      expect(result, new isInstanceOf<DataMap>());
      expect(result['list'], new isInstanceOf<DataList>());
      expect(result['name'], new isInstanceOf<DataSet>());

      expect(result['list'], unorderedEquals([7, 4]));
      expect(result['name'].contains('random'), isTrue);
    });

    test('creates CleanData recursively for Set. (T07)', () {
      DataSet result = cleanify(new Set.from([{'list': [4, 7]}]));

      expect(result, new isInstanceOf<DataSet>());
      expect(result.single, new isInstanceOf<DataMap>());

      expect(result.single['list'], unorderedEquals([7, 4]));
    });
  });

  group('(Decleanify)', () {
    test('from DataReference yields value. (T01)', () {
      var data = 'String';
      var result = cleanify(data);
      expect(decleanify(result), equals(data));
    });

    test('DataList makes list. (T02)', () {
      var result = cleanify(['L', 'I', 'S', 'T']);
      expect(result, new isInstanceOf<DataList>());
      expect(result, equals(['L', 'I', 'S', 'T']));
    });

    test('from DataMap creates Map. (T03)', () {
      var data = {'name': 'Princess', 'age': 15};
      var result = cleanify(data);
      expect(decleanify(result), equals(data));
    });

    test('from DataSet creates Set. (T04)', () {
      var data = new Set.from([4, 4, 7,9]);
      var result = cleanify(data);
      expect(decleanify(result), equals(data));
    });

    test('decleanifies DataList recursively. (T05)', () {
      var data = [{'name': 'Filip'}, {'name': 'Beethoven'}, new Set.from([4,5,7])];
      var result = cleanify(data);
      expect(decleanify(result), equals(data));
    });

    test('decleanifies DataMap recursively. (T06)', () {
      var data = {'list': [4, 7], 'name': new Set.from(['random'])};
      var result = cleanify(data);
      expect(decleanify(result), equals(data));
    });

    test('decleanifies DataSet recursively. (T07)', () {
      var data = new Set.from([{'list': [4, 7]}]);
      var result = cleanify(data);
      expect(decleanify(result), equals(data));
    });
  });

  group('(Clone)', () {
    test('creates new instance of DataMap. (T01)', () {
      DataMap x = new DataMap.from({'a': 'b'});
      DataMap result = clone(x);
      expect(result, new isInstanceOf<DataMap>());
      expect(result, equals(x));
      expect(result == x, isFalse);
    });

    test('creates new instance of DataSet. (T02)', () {
      DataSet x = new DataSet.from(['a', 'b']);
      DataSet result = clone(x);
      expect(result, equals(x));
      expect(result == x, isFalse);
    });

    test('creates new instance of DataList. (T03)', () {
      DataList x = new DataList.from(['a', 'a', 'b']);
      DataList result = clone(x);
      expect(result, equals(x));
      expect(result == x, isFalse);
    });

    test('creates deep clones. (T04)', () {
      DataMap x = new DataMap.from({'a': {'b': 'c'}});
      DataMap result = clone(x);
      expect(result, equals(x));
      expect(result == x, isFalse);
      expect(result['a'], equals(x['a']));
      expect(result['a'] == x['a'], isFalse);
      expect(result['a']['b'], equals(x['a']['b']));
      expect(result['a']['b'] == x['a']['b'], isTrue);
    });
  });
}
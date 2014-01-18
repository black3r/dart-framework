library cleanify_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:collection';

main(){
  group('Cleanify', () {
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
    
    test('creates CleanData recursively for Set. (T06)', () {
      DataSet result = cleanify(new Set.from([{'list': [4, 7]}]));
      
      expect(result, new isInstanceOf<DataSet>());
      expect(result.single, new isInstanceOf<DataMap>());
      
      expect(result.single['list'], unorderedEquals([7, 4]));
    });
  });
}
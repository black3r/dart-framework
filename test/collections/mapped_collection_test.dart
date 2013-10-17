// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('MappedDataView', () {
    
    var data;
    
    // capitalizes the surname property
    var mappingUpper = ((DataView d) {
      Data d2 = new Data.fromMap(d.toMap());
      if (d2.containsKey('surname')) {
        d2['surname'] = d2['surname'].toString().toUpperCase();
      }
      return d2;
     });
    
    // creates a new property 'full-name' by joining name and surname
    var mappingAppender = ((DataView d) {
      Data d2 = new Data.fromMap(d.toMap());
      var name = (d2.containsKey('name')?d2['name']:'');
      var surname = (d2.containsKey('surname')?d2['surname']:'');
      
      d2['full-name'] = "$name $surname";
      return d2;
    });
    
    setUp(() {
      data = [];      
      var map01 = {'id': 11, 'name': 'jozef', 'surname': 'Mrkvicka'};
      var map02 = {'id': 12, 'name': 'Jozef', 'surname': 'redkovka'};
      data.add(new Data.fromMap(map01));
      data.add(new Data.fromMap(map02));
    });
/*
    test('data object is mapped.', () {
      // when
      MappedDataView mDataObj = new MappedDataView(data[0], mappingUpper);
            
      //then
      expect(mDataObj['surname'], equals('MRKVICKA'));
    });

    test('mapped object changes once the source object has changed.', () {
      // given
      MappedDataView mDataObj = new MappedDataView(data[0], mappingUpper);
      
      // when
      data[0]['surname'] = "Kapusticka";

      mDataObj.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(mDataObj['surname'], equals('KAPUSTICKA'));
      }));
    });

    test('double mapped object still propagates changes.', () {
      // given      
      MappedDataView mDataObj = new MappedDataView(new MappedDataView(data[0], mappingUpper), mappingAppender);
      
      // when     
      data[0]['name'] = "Ingrid";
      
      mDataObj.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(mDataObj['full-name'], equals('Ingrid MRKVICKA'));
      })); 
    });
 */
    test('a property is added to the underlying object. Mapped object is recalculated.', () {
      //given
      data[0].remove('name');
      MappedDataView mDataObj = new MappedDataView(new MappedDataView(data[0], mappingUpper), mappingAppender);      
      expect(mDataObj['full-name'], equals(" MRKVICKA"));
      
      //when
      data[0]['name'] = 'Ingrid';
      
      mDataObj.onChange.listen(expectAsync1((ChangeSet event) {
        // then
        expect(mDataObj['full-name'], equals('Ingrid MRKVICKA'));
      }));
      
    });
  });
}

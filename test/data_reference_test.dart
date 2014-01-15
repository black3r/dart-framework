// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library data_reference_test;

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';
import 'package:unittest/mock.dart';
import 'dart:async';


void main() {

  group('(DataReference)', () {

    test('Getter (T01)', () {
      DataReference ref = new DataReference('value');
      expect(ref.value, 'value');
    });

    test('Setter (T02)', () {
      DataReference ref = new DataReference('value');
      ref.value = 'newValue';
      expect(ref.value, 'newValue');
    });


    test('Listen on change (T03)', () {
      DataReference ref = new DataReference('oldValue');

      ref.value = 'newValue';
      ref.onChange.listen(expectAsync1((Change change) {
        expect(change.equals(new Change('oldValue', 'newValue')), isTrue);
      }));
    });

    test('Correctly merge changes. (T04)', () {
      Data d = new Data.from({'name': 'Bond. James Bond.'});
      var oldRef = d.ref('name');
      d['name'] = 'Guybrush';
      d.remove('name');
      d['name'] = 'Guybrush Threepwood';

      d.onChange.listen((change){
        expect(change.equals(new ChangeSet({'name': new Change('Bond. James Bond.', 'Guybrush Threepwood')})),
            isTrue);
      });
    });

    test('Listen on changeSync (T05)', () {
      DataReference ref = new DataReference('oldValue');

      var check = expectAsync1((event) {
        expect(event['change'].equals(new Change('oldValue', 'newValue')), isTrue);
      });

      ref.onChangeSync.listen(check);
      ref.value = 'newValue';
    });

    test('Listen on changes of value. (T06)', () {
      var data = new Data.from({'key': 'oldValue'});
      var dataRef = new DataReference(data);

      // when
      dataRef.value['key'] = 'semiNewValue';
      dataRef.value['key'] = 'newValue';

      // then
      dataRef.onChange.listen(expectAsync1((ChangeSet event) {
        var ref = data.ref('key');
        expect(event.equals(new ChangeSet(
              {'key': new Change('oldValue', 'newValue')}
        )), isTrue);
      }));

    });


    test('Listen synchronyosly on changes of value. (T07)', () {
      //given
      var data = new Data.from({'key': 'oldValue'});
      var dataRef = new DataReference(data);
      var change;
      dataRef.onChangeSync.listen((event){
        change = event['change'];
      });

      // when
      dataRef.value['key'] = 'newValue';

      // then
      expect(change.equals(new ChangeSet({'key': new Change('oldValue', 'newValue')}))
          , isTrue);

    });
  });
}
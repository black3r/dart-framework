// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'package:clean_data/clean_data.dart';

void main() {

  group('Collection', () {

    var model0, model1, model2, model3;
    var models;
    setUp(() {
      models = [];
      for (var i = 0; i <= 10; i++) {
        models.add(new Model.fromData({'id': i}));
      }
    });

    test('initialize.', () {
      // when
      var collection = new Collection();

      // then
      expect(collection.length, equals(0));
      expect(collection, equals([]));
    });

    test('initialize with data.', () {
      // when
      var collection = new Collection.from(models);

      // then
      expect(collection.length, equals(models.length));
      expect(collection, unorderedEquals(models));
    });

    test('multiple listeners listen to onChange.', () {
      // given
      var collection = new Collection();

      // when
      collection.onChange.listen((event) => null);
      collection.onChange.listen((event) => null);

      // Then no exception is thrown.
    });

    test('add model.', () {
      // given
      var collection = new Collection();

      // when
      for (var model in models) {
        collection.add(model);
      }

      // then
      expect(collection.contains(models[0]), isTrue);
      expect(collection, unorderedEquals(models));
    });

    test('remove model.', () {
      // given
      var models = [new Model(), new Model()];
      var collection = new Collection.from(models);

      // when
      collection.remove(models[0]);

      // then
      expect(collection.contains(models[0]), isFalse);
      expect(collection, unorderedEquals([models[1]]));
    });

    test('clear.', () {
      // given
      var collection = new Collection.from(models);

      // when
      collection.clear();

      // then
      expect(collection.isEmpty, isTrue);
    });

    test('listen on model added.', () {
      // given
      var collection = new Collection();

      // when
      collection.add(models[0]);

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.removedChildren.isEmpty, isTrue);
        expect(event.changedChildren.isEmpty, isTrue);
        expect(event.addedChildren, unorderedEquals([models[0]]));
      }));
    });

    test('listen on model removed.', () {
      // given
      var collection = new Collection.from(models);

      // when
      collection.remove(models[0]);

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedChildren.isEmpty, isTrue);
        expect(event.changedChildren.isEmpty, isTrue);
        expect(event.removedChildren, unorderedEquals([models[0]]));
      }));
    });

    test('listen on model changes.', () {
      // given
      var collection = new Collection.from(models);

      // when
      models[0]['name'] = 'John Doe';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedChildren.isEmpty, isTrue);
        expect(event.removedChildren.isEmpty, isTrue);
        expect(event.changedChildren.length, equals(1));
        expect(event.changedChildren[models[0]].addedChildren,
            unorderedEquals(['name']));
      }));
    });

    test('do not listen on removed model changes.', () {
      // given
      var collection = new Collection.from(models);

      // when
      collection.remove(models[0]);
      models[0]['name'] = 'John Doe';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedChildren.isEmpty, isTrue);
      }));
    });

    test('do not listen on cleared model changes.', () {
      // given
      var collection = new Collection.from(models);

      // when
      collection.clear();
      models[0]['name'] = 'John Doe';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedChildren.isEmpty, isTrue);
      }));
    });

    test('propagate multiple add/remove changes in single [ChangeSet].', () {
      // given
      var collection = new Collection.from(models);
      var newModel = new Model();

      // when
      collection.remove(models[0]);
      collection.add(newModel);

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.addedChildren, unorderedEquals([newModel]));
        expect(event.removedChildren, unorderedEquals([models[0]]));
      }));
    });

    test('propagate multiple models changes in single [ChangeSet].', () {
      // given
      var collection = new Collection.from(models);

      // when
      models[0]['name'] = 'John Doe';
      models[1]['name'] = 'James Bond';

      // then
      collection.onChange.listen(expectAsync1((ChangeSet event) {
        expect(event.changedChildren.keys,
            unorderedEquals([models[0], models[1]]));
      }));
    });

  });
}
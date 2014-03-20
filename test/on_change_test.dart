// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library on_change_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

class OnChangeMock {
  bool canceled = false;
  change(value) => _onChangeController.add(value);

  StreamController _onChangeController;
  Stream get onChange => _onChangeController.stream;

  OnChangeMock() {
    _onChangeController = new StreamController(
        onCancel: () => canceled = true);
  }

}

void main() {
  group("Group multiple onChange events to single stream", () {
    var ref1, ref2, handler;
    var subscription;

    verifySingleCall() => new Future.delayed(new Duration(milliseconds: 10), () => null).then((_) {
      handler.getLogs(callsTo('call')).verify(happenedOnce);
    });

    // given
    setUp(() {
      ref1 = new OnChangeMock();
      ref2 = new OnChangeMock();
      handler = new Mock();
      subscription = onChange([ref1, ref2]).listen((_) => handler());
    });

    test("both changes", () {
      // when
      ref1.change("sth");
      ref1.change("again");
      ref2.change("also");

      // then
      return verifySingleCall();
    });

    test("single change", () {
      // when
      ref2.change("sth");

      // then
      return verifySingleCall();
    });

    test("stop listening", () {
      // when
      subscription.cancel();

      // then
      expect(ref1.canceled, isTrue);
      expect(ref2.canceled, isTrue);
    });
  });

  group("React to changes by updating DataReference", () {
    test("reactively.", () {
      // given
      var ref1 = new OnChangeMock();
      var ref2 = new OnChangeMock();
      var oldValue = 0, newValue = 10;
      var value = oldValue;

      var reactive = reactiveRef([ref1, ref2], () => value);

      // then
      reactive.onChange.listen(expectAsync1((_) {
        expect(reactive.value, equals(newValue));
      }));

      // when
      value = 10;
      ref1.change("sth");
      ref2.change('another');
    });
  });
}

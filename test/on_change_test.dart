// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library on_change_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

class OnChangeMock {
  bool canceled = true;
  change(value) => _onChangeController.add(value);

  StreamController _onChangeController;
  Stream get onChange => _onChangeController.stream;

  OnChangeMock() {
    _onChangeController = new StreamController.broadcast(
        onListen: () => canceled = false,
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

    test("restart listening", () {
      // when
      subscription.cancel();
      var subscription2 = onChange([ref1, ref2]).listen((_) => handler());

      // then
      expect(ref1.canceled, isFalse);
      expect(ref2.canceled, isFalse);
    });

  });

  group("React to changes by updating DataReference", () {
    var ref1, ref2, handler, value, oldValue, newValue, reactive;

    setUp(() {
      // given
      ref1 = new OnChangeMock();
      ref2 = new OnChangeMock();
      oldValue = 0;
      newValue = 10;
      value = oldValue;
      handler = new Mock();
      reactive = reactiveRef([ref1, ref2], () => value);
    });

    test("reactively.", () {
      // then
      reactive.onChange.listen(expectAsync1((_) {
        expect(reactive.value, equals(newValue));
      }));

      // when
      value = 10;
      ref1.change("sth");
      ref2.change('another');
    });

    test("update ref only if new value is different from old one", () {
      // given
      reactive.onChange.listen((_) => handler());

      // when
      ref1.change('sth');
      ref2.change('another');

      // then
      return new Future.delayed(new Duration(milliseconds: 10), () {
        handler.getLogs(callsTo('call')).verify(neverHappened);
      });
    });
  });
}

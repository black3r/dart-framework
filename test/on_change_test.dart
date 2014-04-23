// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library on_change_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

class MockFunction extends Mock implements Function {}
class MockTimer extends Mock implements Timer {}

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

class ReactorMock extends Reactor {
  ReactorMock(DataReference ref, List listenTo, Function computeValue, {bool forceOverride: false, this.customSchedule})
      : super(ref, listenTo, computeValue, forceOverride: forceOverride){

  }
  var customSchedule = (duration, callback) => new Timer(duration, callback);
  schedule(duration, callback) => customSchedule(duration, callback);
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

  group("Reactor test", () {
    var handler, oldValue, newValue, reactive;
    DataReference ref, ref1, ref2;
    var recalculatedValue;
    var calculation;

    setUp(() {
      // given
      ref1 = new DataReference(null);
      ref2 = new DataReference(null);
      ref = new DataReference(null);
      var customHandler = new Mock();
      handler = customHandler;
      ref.onChangeSync.listen((_) => customHandler(ref.value));
      recalculatedValue = 1;
      calculation = new MockFunction()
         ..when(callsTo('call')).alwaysCall(()=> recalculatedValue);
    });

    test(" set initial value to calculation", () {
      //given
      var reactor = new ReactorMock(ref, [ref1, ref2], calculation);
      //then
      expect(ref.value, equals(recalculatedValue));
    });

    test(" react to changes of listen to", () {
      //given
      var reactor = new ReactorMock(ref, [ref1, ref2], calculation);

      //when
      recalculatedValue = 2;
      ref1.value = 2;

      //then
      return new Future.delayed(new Duration(milliseconds: 10), () {
        handler.getLogs(callsTo('call', recalculatedValue)).verify(happenedOnce);
      });
    });

    test(" handles expiration value", (){
      //given
      var runScheduledCallback;
      var customSchedule = new MockTimer();
      customSchedule..when(callsTo('call')).alwaysCall((duration,callback) {
        runScheduledCallback = callback;
        return customSchedule;
       });
      var expirationTime = new DateTime(2014, 1, 1, 13);
      recalculatedValue = new ReactiveValue(2, expirationTime);
      var reactor = new ReactorMock(ref, [ref1, ref2], calculation,
          customSchedule: customSchedule);

      //then
      customSchedule.getLogs(callsTo('call', expirationTime, anything)).verify(happenedOnce);

      //when
      recalculatedValue = "afterExpiration";
      runScheduledCallback();

      //then
      return new Future.delayed(new Duration(milliseconds: 10), () {
        handler.getLogs(callsTo('call', recalculatedValue)).verify(happenedOnce);
      });
    });

    test(" cancel previous timer if recalculate happens", (){
      //given
      var runScheduledCallback;
      var customSchedule = new MockTimer();
      customSchedule..when(callsTo('call')).alwaysCall((duration,callback) {
        runScheduledCallback = callback;
        return customSchedule;
       });
      var expirationTime = new DateTime(2014, 1, 1, 13);
      recalculatedValue = new ReactiveValue(2, expirationTime);

      var reactor = new ReactorMock(ref, [ref1, ref2], calculation,
          customSchedule: customSchedule);

      //then
      customSchedule.getLogs(callsTo('call', expirationTime, anything)).verify(happenedOnce);

      //when
      recalculatedValue = 5;
      reactor.recalculate();
      //then
      customSchedule.getLogs(callsTo('cancel')).verify(happenedOnce);

    });


    test(" if value is not changed do nothing", (){
      // given
      var reactor = new ReactorMock(ref, [ref1, ref2], calculation);

      // when
      reactor.recalculate();
      reactor.recalculate();
      reactor.recalculate();

      // then
      return new Future.delayed(new Duration(milliseconds: 100), () {
        handler.getLogs(callsTo('call')).verify(happenedOnce);
      });
    });

    test(" if value is not changed and forceUpdate fire events", (){
      // given
      var reactor = new ReactorMock(ref, [ref1, ref2], calculation, forceOverride: true);

      // when
      reactor.recalculate();
      reactor.recalculate();
      reactor.recalculate();
      // then
      return new Future.delayed(new Duration(milliseconds: 100), () {
        handler.getLogs(callsTo('call')).verify(happenedExactly(4));
      });
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
      reactive.onChange.listen(expectAsync((_) {
        expect(reactive.value, equals(value));
        // when
        value = 10;
      }, count: 2));

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
        handler.getLogs(callsTo('call')).verify(happenedOnce);
      });
    });
  });
}

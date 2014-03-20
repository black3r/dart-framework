// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library on_change_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';
import 'package:clean_data/clean_data.dart';
import 'dart:async';

class OnChangeMock {
  change(value) => _onChangeController.add(value);
  StreamController _onChangeController = new StreamController();
  Stream get onChange => _onChangeController.stream;
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
  });
}

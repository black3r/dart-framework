// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Listen simply to [onChange] events from multiple [sources]. Returned stream
 * propagates single [null] value as notification that some [onChange] occured.
 * Propagation happens asynchronously in the new event loop.
 */
onChange(Iterable sources) {
  var start, stop, notify;

  var controller = new StreamController(onListen: () => start(), onCancel: () => stop());

  var subscriptions = [];
  var willNotify = false;
  var listening = false;
  start = () {
    listening = true;
    for (var o in sources) {
      subscriptions = o.onChange.listen((_) => notify());
    }
  };

  stop = () {
    listening = false;
    for (var s in subscriptions) s.cancel();
  };

  notify = () {
    if (willNotify) return;
    if (!listening) return;
    willNotify = true;

    Timer.run(() {
      willNotify = false;
      controller.add(null);
    });
  };

  return controller.stream;
}
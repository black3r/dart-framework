// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of clean_data;

/**
 * Listen simply to [onChange] events from multiple [sources].
 *
 * Returned stream propagates single [null] value as notification that some
 * [onChange] occured. Propagation happens asynchronously in the new event loop.
 */
Stream onChange(Iterable sources) {
  var start, stop, notify;

  var controller = new StreamController.broadcast(
      onListen: () => start(),
      onCancel: () => stop());

  var subscriptions = [];
  var willNotify = false;
  var listening = false;
  start = () {
    listening = true;
    for (var o in sources) {
      subscriptions.add(o.onChange.listen((_) => notify()));
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

/**
 * Listens to onChange on every element in [listenTo] and updates [ref] with value returned
 * by [computeValue].
 *
 * Optional [computeExpires] function can be specified to force [ref] recalculation after some
 * expiration time. The [expire] takes newly computed value as an argument and shall return
 * DateTime of expiration in the future.
 *
 * By default update to [ref] is only made if the newly computed value differs from the value
 * stored in [ref]. You can override this behavior by setting [forceOverride] to true.
 */
class Reactor {
  final DataReference ref;
  final Function computeValue;
  final bool forceOverride;

  Reactor(DataReference this.ref, List listenTo, Function this.computeValue,
      {bool this.forceOverride: false}) {
    recalculate();
    listener = onChange(listenTo).listen((_) => recalculate());
  }

  StreamSubscription listener;
  Timer expireTimer;
  /**
   * Force recalculation of the [ref].
   *
   * If [forceOverride] is not set, use the value specified in constructor.
   */
  recalculate(){
    var computedValue =  computeValue();
    var newValue = computedValue;
    var newExpirationTime = null;
    // try to parse expiration value
    if (computedValue is ReactiveValue) {
      newExpirationTime = computedValue.expiration;
      newValue = computedValue.value;
    }
    // set new value to ref if new is different or forceOverride is setted
    if (ref.value != newValue || forceOverride == true) {
      ref.value = newValue;
    }
    //cancel previous scheduled expiration
    if (expireTimer != null) {
      expireTimer.cancel();
      expireTimer = null;
    }
    // schedule recalculation if needed
    if (newExpirationTime != null) {
      expireTimer = schedule(newExpirationTime, recalculate);
    }
  }

  schedule(expirationTime, callback) => createTimer(expirationTime, callback);

  /**
   * Dispose all listeners and timers.
   */
  dispose(){
    expireTimer.cancel();
    listener.cancel();
  }
}

final MAX_SAFE_DURATION = new Duration(days: 10);
Timer createTimer(expirationTime, callback) {
  var duration = expirationTime.difference(new DateTime.now());
  if (duration > MAX_SAFE_DURATION) duration = MAX_SAFE_DURATION;
  if (duration < new Duration(microseconds: 0)) {
    throw new ArgumentError("Expiration time can't be in past: $expirationTime");
  }
  return new Timer(duration, callback);
}

class ReactiveValue {
  final DateTime expiration;
  final dynamic value;
  ReactiveValue(this.value, this.expiration);
}

/**
 * Reactively compute value of reference.
 * Value is computed using [computeValue] whenever happens [onChange] on any item
 * in [listenTo]. If [computeValue] returns [ReactiveValue] then recalculation
 * of value will also hapen at expiration time.
 */
DataReference reactiveRef(Iterable listenTo, computeValue,
     {bool forceOverride: false}) {
  DataReference ref = new DataReference(null);
  var reactor = new Reactor(ref, listenTo, computeValue, forceOverride: forceOverride);
  ref.setOnDispose(reactor.dispose);
  return ref;
}
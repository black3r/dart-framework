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

class Reactor {
  final DataReference ref;
  final Function computeValue;
  final bool forceOverride;

  final _scheduleExpiration;

  /**
   * Listens to onChange on every element in [listenTo] and updates [ref] with
   * value returned by [computeValue].
   *
   * Optionaly [computeValue] can return [ReactiveValue] instance which can
   * specify expiration time after which the value must be recalculated.
   *
   * By default update to [ref] is only made if the newly computed value differs
   * from the value stored in [ref]. You can override this behavior by setting
   * [forceOverride] to true.
   */
  Reactor(DataReference ref, List listenTo, Function computeValue,
      {bool forceOverride: false})
      : this.config(ref, listenTo, computeValue, scheduleExpiration,
                    forceOverride: forceOverride);

  Reactor.config(DataReference this.ref, List listenTo,
      Function this.computeValue, this._scheduleExpiration,
      {bool this.forceOverride: false}) {

    recalculate();
    listener = onChange(listenTo).listen((_) => recalculate());
  }

  StreamSubscription listener;
  Timer expirationTimer;

  /**
   * Force recalculation of the [ref].
   *
   * If [forceOverride] is not set, use the value specified in constructor.
   */
  recalculate(){
    var newValue = computeValue();

    if (newValue is! ReactiveValue) {
      newValue = new ReactiveValue(newValue);
    }

    // set new value to ref if new is different or forceOverride is setted
    if (ref.value != newValue.value || forceOverride == true) {
      ref.value = newValue.value;
    }

    //cancel previous scheduled expiration
    if (expirationTimer != null) {
      expirationTimer.cancel();
      expirationTimer = null;
    }

    // schedule recalculation if needed
    if (newValue.expiration != null) {
      expirationTimer = _scheduleExpiration(newValue.expiration, recalculate);
    }
  }


  /**
   * Dispose all listeners and timers.
   */
  dispose() {
    if (expirationTimer != null) expirationTimer.cancel();
    listener.cancel();
  }
}

/**
 * Describes reactively computed value with expiration time.
 */
class ReactiveValue {
  final DateTime expiration;
  final dynamic value;
  ReactiveValue(this.value, {DateTime this.expiration});
}


// When compiled to javascript timer can not be set to period longer than
// 23 days. For this reason [scheduleExpiration] do not schedule [Duration]s
// longer than MAX_SAFE_DURATION.
const MAX_SAFE_DURATION = const Duration(days: 10);

/**
 * Schedule [callback] invocation for some particular [DateTime] in future.
 *
 * Returns [Timer] instance responsible for calling the [callback].
 */
Timer scheduleExpiration(DateTime expirationTime, callback) {
  var duration = expirationTime.difference(new DateTime.now());

  // When compiled to javascript timer can not be set to period longer than
  // 23 days. For this reason [scheduleExpiration] do not schedule [Duration]s
  // longer than MAX_SAFE_DURATION.
  if (duration > MAX_SAFE_DURATION) duration = MAX_SAFE_DURATION;

  if (duration < new Duration(microseconds: 0)) {
    throw new ArgumentError("Expiration time from past: $expirationTime");
  }
  return new Timer(duration, callback);
}




/**
 * Reactively compute value of reference.
 *
 * Value is computed using [computeValue] whenever happens [onChange] on any
 * item in [listenTo]. If [computeValue] returns [ReactiveValue] then
 * recalculation of value will also hapen at expiration time.
 */
DataReference reactiveRef(Iterable listenTo, computeValue,
                          {bool forceOverride: false}) {
  var reactor;
  DataReference ref = new DataReference(null, () => reactor.dispose());
  reactor = new Reactor(ref, listenTo, computeValue,
                        forceOverride: forceOverride);

  return ref;
}
// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for automatical data synchronization among collections.
 *
 * ## Concepts
 *
 * * __Changes__: You can easily attach listeners to all objects to detect
 *   changes of their data. Changes are represented as [ChangeSet] or [Change]
 *   instances. Changes are available through asynchronous [onChange] [Stream],
 *   that does the work of grouping multiple changes that occured during
 *   execution to single [ChangeSet] fired in the next event loop.
 *
 * * __Data__: Data are stored using a [Map] compatible instances of class
 *   [Data].
 *
 * * __Collection__: Multiple data objects can be stored and manipulated using
 *   the instance of [DataCollection] class. [DataCollection] behave similarly
 *   to [Set], each object can be contained at most once and no order is
 *   guaranteed.
 *
 * * __Views__: You can easily create various read-only views of your data
 *   using handy methods [filter], [map], [union], [except], [intersect]. Views
 *   gets automatically updated when the underlying data change to always
 *   reflect actual state.
 *
 * ## Examples
 *
 * Create simple data object and listen to its changes:
 *
 *     import 'package:clean_data/clean_data.dart';
 *     void main() {
 *       var person = new Data.from({"name": "John"});
 *       person.onChange.listen((changeSet) => print("Person has changed!"));
 *
 *       person['surname'] = 'Doe';
 *       person['age'] = 37;
 *     }
 *
 * The above code outputs:
 *
 *     Person has changed!
 *
 * Notice that despite of two changes happened, we only one notification was
 * fired.
 *
 * Create simple collection and listen to its changes:
 *
 *     import 'package:clean_data/clean_data.dar';
 *     void main() {
 *       var colleagues = new DataCollection();
 *       colleagues.onChange.listen((changeSet) => print("Team has changed!"));
 *
 *       colleagues.add(new Data.from({"name": "John"}));
 *       colleagues.add(new Data.from({"name": "Peter"}));
 *
 *     }
 *
 * The above code outputs:
 *
 *     Team has changed!
 *
 * Similarly to previous example, only one notification was fired.
 *
 * Our collection also listens to changes in its underlying data objects:
 *
 *     import 'package:clean_data/clean_data.dar';
 *     void main() {
 *       var john = new Data.from({"name": "John"});
 *       var peter = new Data.from({"name": "Peter"});
 *
 *       var colleagues = new DataCollection.from([john, peter]);
 *       colleagues.onChange.listen((changeSet) => print("Team has changed!"));
 *
 *       john['surname'] = 'Doe';
 *       peter['surname'] = 'Pan';
 *
 *     }
 *
 * The above code outputs:
 *
 *     Team has changed!
 *
 * Again, only one notification was fired.
 */
library clean_data;

import "dart:core";
import "dart:async";
import "dart:collection";

part 'src/data.dart';
part 'src/data_collection.dart';
part 'src/change_set.dart';

part 'src/collections/transformed_collection_view.dart';
part 'src/collections/filtered_collection_view.dart';

part 'src/hash_index.dart';
part 'src/data_change_listeners_mixin.dart';
part 'src/change_notifications_mixin.dart';
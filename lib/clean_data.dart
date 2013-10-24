// Copyright (c) 2013, the Clean project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for data representing and manipulation in single page applications.
 */
library clean_data;

import "dart:core";
import "dart:async";
import "dart:collection";

part 'src/data.dart';
part 'src/data_collection.dart';
part 'src/id_generator.dart';
part 'src/change_set.dart';

part 'src/collections/transformed_data_collection.dart';
part 'src/collections/filtered_data_collection.dart';
part 'src/collections/mapped_data_collection.dart';

part 'src/collections/unioned_data_collection.dart';
part 'src/collections/intersected_data_collection.dart';
part 'src/collections/excepted_collection_view.dart';

part 'src/collections/sorted_data_collection.dart';